use Modern::Perl;
use Log::LogMethods::Log4perlLogToString;
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
my $self=$class->new(logger=>$logger,token=>$token,retryCount=>2);
isa_ok($self,$class);
{
  my $result=$self->build_post_json('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;

  cmp_ok($post->uri,'eq',$self->api_url.'test','Should have generated the correct url');
  cmp_ok($post->content,'eq',to_json({qw(test data)}),'make sure our json serialization works');
  cmp_ok($post->method,'eq','POST','Should have a valid post object') or die;
}
{
  my $result=$self->build_put_json('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;

  cmp_ok($post->uri,'eq',$self->api_url.'test','Should have generated the correct url');
  cmp_ok($post->content,'eq',to_json({qw(test data)}),'make sure our json serialization works');
  cmp_ok($post->method,'eq','PUT','Should have a valid post object') or die;
}
{
  my $result=$self->build_post_form('test',{qw(test data)});
  ok($result,'Should have buid the request without any issues');
  my $post=$result->get_data;
  cmp_ok($post->method,'eq','POST','Should have a valid post object') or die;

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
    ($self,$id,$result,$request,$response)=@_;
  };

  $self->handle_delete($cb,1,$self->new_false("Should be false"),HTTP::Request->new(DELETE=>'http://blah'),HTTP::Response->new(204,'looks good'));
  ok($result,'delete pass, result object should be true') or die "Should pass this test";
  $self->handle_delete($cb,1,$self->new_false("Should be false"),HTTP::Request->new(DELETE=>'http://blah'),HTTP::Response->new(200,'Should fail'));
  ok(!$result,'delete fail, result object should be false') or die diag Dumper($result);
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS,TEST_EMAIL] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_EMAIL};
  my $result=$self->listPeople({email=>$ENV{TEST_EMAIL}});
  ok($result,'Should get an email address') or diag(Dumper $result);
  #diag(Dumper($result->get_data));
  sleep 1;
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS,TEST_USER] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_USER};
  my $result=$self->listPeople({displayName=>$ENV{TEST_USER}});
  ok($result,'displayName lookup') or diag(Dumper $result);
  sleep 1;
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS,TEST_USER_WC] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_USER_WC};
  my $result=$self->listPeople({displayName=>$ENV{TEST_USER_WC},maxResults=>5});
  ok($result,'displayName begins with test') or diag(Dumper $result);
  #diag(Dumper $result->get_data);
  sleep 1;
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS,TEST_PERSON_ID] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_PERSON_ID};
  my $result=$self->getPerson($ENV{TEST_PERSON_ID});
  ok($result,'Fetch person by id') or diag(Dumper $result);
  #diag(Dumper $result->get_data);
  sleep 1;
}


my $orgId;
SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS] Not set',1 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS};
  my $result=$self->getMe;
  ok($result,'Should find myself');
  $orgId=$result->get_data->{orgId};
  #diag(Dumper $result->get_data);
  sleep 1;
}

SKIP: {
  skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS, TEST_TEAM] Not set',3 unless $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $ENV{TEST_TEAM};

  my $result=$self->createTeam({name=>$ENV{TEST_TEAM}});
  ok($result,'Should create the team without an error') or diag("Failed to create team, error was: $result");
  sleep 1;
  SKIP: {
    skip "Failed to create team",1 unless $result;
    my $teamId=$result->get_data->{id};
    my $result=$self->listTeams;
    ok($result,'Should find a team') or die $result;
    sleep 3;
    my $teams=$result->get_data->{items};
    foreach my $team (@{$teams}) {
      next unless $team->{name} eq $ENV{TEST_TEAM};
      ok(1,"We have found our team");
    }

    SKIP: {
      skip 'ENV Vars [SPARK_TOKEN, RUN_HTTP_TESTS, TEST_TEAM $teamId] Not set',1 unless $ENV{TEST_TEAM} and $ENV{SPARK_TOKEN} and $ENV{RUN_HTTP_TESTS} and $teamId;
      my $room_args={teamId=>$teamId,title=>$ENV{TEST_TEAM}};
      my $result=$self->createRoom($room_args);
      sleep 1;
      ok($result,'Should have created the room') or die "$result";
      {
        my $result=$self->updateTeam($teamId,{name=>$ENV{TEST_TEAM}."Renamed"});
	ok($result,"Should have updated the test team wthout an error") or diag($result);
        sleep 1;
      }
      {
        my $result=$self->deleteTeam($teamId);
        ok($result,"Cleaning up team $ENV{TEST_TEAM}, ID: $teamId") or diag($result);
	diag(Dumper($result->get_data));
      }
    }
  }
}


done_testing;
