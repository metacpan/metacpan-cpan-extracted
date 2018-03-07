use Modern::Perl;
use Charter::ForTestingOnly::Log4perlToString;
use Carp qw(confess);
use Data::Dumper;
use JSON qw(to_json from_json);
#BEGIN { $SIG{__DIE__} = sub { confess @_ }; }
use Test::More qw(no_plan);

my $class='AnyEvent::HTTP::Spark';
require_ok($class);
use_ok($class);

my $string;
my $logger=LoggerToString($class,$string);
my $token=exists $ENV{SPARK_TOKEN} ? $ENV{SPARK_TOKEN} : 'this is not a valid token';
my $self=$class->new(logger=>$logger,token=>$token);
isa_ok($self,$class);
{
  my $result=$self->build_post_json('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;

  cmp_ok($post->uri,'eq',$self->api_url.'test','Should have generated the correct url');
  cmp_ok($post->content,'eq',to_json({qw(test data)}),'make sure our json serialization works');
  cmp_ok($post->method,'eq','POST','Should have a valid post object');
}
{
  my $result=$self->build_put_json('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;

  cmp_ok($post->uri,'eq',$self->api_url.'test','Should have generated the correct url');
  cmp_ok($post->content,'eq',to_json({qw(test data)}),'make sure our json serialization works');
  cmp_ok($post->method,'eq','POST','Should have a valid post object');
}
{
  my $result=$self->build_post_form('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;
  cmp_ok($post->method,'eq','POST','Should have a valid post object');

  cmp_ok($post->uri,'eq',$self->api_url.'test','Should have generated the correct url');
  diag $post->as_string;
}
{
  my $result=$self->build_get('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;
  cmp_ok($post->method,'eq','GET','Should have a valid GET object');

  cmp_ok($post->uri,'eq',$self->api_url.'test?test=data','Should have generated the correct url');
  diag $post->as_string;
}

{
  my $result=$self->build_head('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;
  cmp_ok($post->method,'eq','HEAD','Should have a valid GET object');

  cmp_ok($post->uri,'eq',$self->api_url.'test?test=data','Should have generated the correct url');
  diag $post->as_string;
}
{
  my $result=$self->build_delete('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;
  cmp_ok($post->method,'eq','DELETE','Should have a valid DELETE object');

  cmp_ok($post->uri,'eq',$self->api_url.'test?test=data','Should have generated the correct url');
  diag $post->as_string;
}
{
  my ($id,$result,$request,$response);
  my $cb=sub {
    ($id,$result,$request,$response)=@_;
  };

  $self->handle_delete($cb,1,$self->new_false("Should be false"),HTTP::Request->new(DELETE=>'http://blah'),HTTP::Response->new(204,'looks good'));
  ok($result,'delete pass, result object should be true');
  $self->handle_delete($cb,1,$self->new_false("Should be false"),HTTP::Request->new(DELETE=>'http://blah'),HTTP::Response->new(200,'Should fail'));
  ok(!$result,'delete fail, result object should be false');
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS,TEST_EMAIL] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_EMAIL};
  my $result=$self->listPeople({email=>$ENV{TEST_EMAIL}});
  ok($result,'Should get an email address') or diag(Dumper $result);
  diag(Dumper($result->get_data));
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS,TEST_USER] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_USER};
  my $result=$self->listPeople({displayName=>$ENV{TEST_USER}});
  ok($result,'Should get a person') or diag(Dumper $result);
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS,TEST_USER_WC] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_USER_WC};
  my $result=$self->listPeople({displayName=>$ENV{TEST_USER_WC},maxResults=>1});
  ok($result,'Should get a person') or diag(Dumper $result);
  diag(Dumper $result->get_data);
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS,TEST_PERSON_ID] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_PERSON_ID};
  my $result=$self->getPerson($ENV{TEST_PERSON_ID});
  ok($result,'Should get a person') or diag(Dumper $result);
  diag(Dumper $result->get_data);
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS};
  my $result=$self->getMe;
  ok($result,'Should find myself') or diag(Dumper $result);
  diag(Dumper $result->get_data);
}


done_testing;
