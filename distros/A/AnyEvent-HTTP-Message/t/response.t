use strict;
use warnings;
use Test::More 0.88;
use lib 't/lib';
use AEHTTP_Tests;

my $mod = 'AnyEvent::HTTP::Response';
eval "require $mod" or die $@;

# parse_args error
foreach my $args ( [1], [1,2,3] ){
  is eval { $mod->parse_args(@$args) }, undef, 'wrong number of args';
  like $@, qr/expects two arguments/, 'error message';
}

# not much to test here, just order of args
{
  my $body = "black\nparade";
  my %pseudo = (
    Pseudo => 'Header',
    Status => 200,
    Reason => 'Who Cares',
    HTTPVersion => 1.1,
  );
  my %headers = (
    %pseudo,
    'x-interjection' => '3 cheers!'
  );

  my $res = new_ok($mod, [$body, { %headers }]);

  is $res->body, $body, 'body in/out';
  is $res->content, $body, 'content alias';
  is_deeply $res->headers, { 'x-interjection' => '3 cheers!' }, 'headers in/out';
  is_deeply $res->pseudo_headers, { %pseudo }, 'pseudo headers';

  my @interjections = qw( X_Interjection X-INTERJECTION );
  is $res->header( $_ ), '3 cheers!', 'single header'
    for @interjections;

  is_deeply [ $res->args ], [ $body, { %headers } ], 'arg list';

  test_http_message $res, sub {
    my $msg = shift;
    ok $msg->is_success, '200 OK';
    is $msg->message, 'Who Cares', 'nobody cares';
    is $msg->header( $_ ), '3 cheers!', 'header via HTTP::Headers'
      for @interjections;
    is $msg->protocol, 'HTTP/1.1', 'HTTPVersion => protocol';
    is $msg->content, "black\nparade", 'reponse body content';
  };
}

# args via hashref
{
  my $body = 'the end';
  my %headers = (
    res_is => 'less useful than req'
  );
  my %pseudo = (
    Silly => 'wabbit',
    Status => 413,
    HTTPVersion => '1.0',
    Reason => 'Your Request is Stupid',
  );

  my $res = new_ok($mod, [{
    headers => { %headers },
    body => $body,
    pseudo_headers => { %pseudo },
  }]);

  my %norm = ('res-is' => $headers{res_is});

  is $res->body, $body, 'body in/out';
  is $res->content, $body, 'content alias';
  is_deeply $res->headers, { %norm }, 'headers in/out';
  is_deeply $res->pseudo_headers, { %pseudo }, 'pseudo headers';

  my @single = qw( res_is res-is RES_IS RES-IS );
  is $res->header( $_ ), 'less useful than req', 'single header'
    for @single;

  is_deeply [ $res->args ], [ $body, { %norm, %pseudo } ], 'arg list';

  test_http_message $res, sub {
    my $msg = shift;
    ok !$msg->is_success, '413 is a bad request';
    is $msg->header( $_ ), 'less useful than req', 'header via HTTP::Headers'
      for @single;

    is $msg->protocol, 'HTTP/1.0', 'HTTPVersion => protocol';
  };
}

# args via HTTP::Message
test_http_message sub {
  my $msg = new_ok('HTTP::Response', [200, 'Fine', [
    X_Dog => 'Fluffy',
    X_Dog => 'Fido',
  ], "bark!"]);

  # don't throw warnings if protocol was undefined
  {
    my @w;
    local $SIG{__WARN__} = sub { push @w, [@_] };
    is new_ok($mod, [$msg])->pseudo_headers->{HTTPVersion}, undef,
      'cannot set HTTPVersion without a protocol';
    is_deeply \@w, [], 'no warnings';
  }

  $msg->protocol('HTTP/0.1');

  my $res = new_ok($mod, [$msg]);
  is_deeply
    $res->pseudo_headers,
    {
      Status      =>        200,
      Reason      =>     'Fine',
      HTTPVersion =>       '.1',
    },
    'psuedo headers transferred';
  is $res->content, 'bark!', 'hush!';
  like $res->header('x-dog'), qr/^Fluffy, ?Fido$/, 'combined header';
};

done_testing;
