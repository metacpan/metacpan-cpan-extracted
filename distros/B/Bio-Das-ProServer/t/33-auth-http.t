use strict;
use warnings;
use Test::More;

eval {
  require LWP::UserAgent;
  require Cache::FileCache;
};
if ($@) {
  plan skip_all => 'HTTP authentication requires LWP::UserAgent and Cache::FileCache';
} else {
  plan tests => 20;
}

# Initial basic tests
use_ok('Bio::Das::ProServer::Authenticator::http');
my $auth = Bio::Das::ProServer::Authenticator::http->new();
isa_ok($auth, 'Bio::Das::ProServer::Authenticator::http');
can_ok($auth, qw(parse_token authenticate));

# Set up a server and check it is listening.
my $port;
my $child_pid;
my $agent = LWP::UserAgent->new(timeout=>1);

if($ENV{http_proxy}) {
  $ENV{http_proxy} = q[];
}

for my $test_port (10000 .. 10100) {
  $child_pid = &setup_server($test_port);
  my $resp = $agent->get("http://127.0.0.1:$test_port/token=allow");

  if ($resp->code() == 200) {
    $resp = $agent->get("http://127.0.0.1:$test_port/token=deny");

    if ($resp->code() == 403) {
      $port = $test_port;
      last;
    }
  }
  kill 3, $child_pid; wait;
}

my $server_err = 0;
$SIG{INT} = sub { $server_err = 1; };

if ($port) {
  pass("run test authentication server");

  # Parent process does the testing
  use HTTP::Request;

  for my $type (qw(cookie param header default)) {

    $auth = Bio::Das::ProServer::Authenticator::http->new({
							   config => {
								      authurl   => "http://127.0.0.1:$port?token=%token",
								      "auth$type" => 'key',
								     },
							  });

    for my $token (qw(allow deny)) {
      for my $attempt (qw(first cached)) {
        my $req = HTTP::Request->new('get',
                                     "http://my.example.com?key=$token",
                                     ['Cookie', "key=$token",
                                     'key', $token,
                                     'Authorization', $token]);
        my ($uri) = $req->uri() =~ m/\?(.*)/smx;
        my $resp = $auth->authenticate( {'request' => $req, 'cgi' => CGI->new($uri)} );
        ok( $token eq 'allow' ? !$resp : defined $resp && $resp->isa('HTTP::Response'), "$attempt $token $type authentication") || diag($resp);
      }
    }
  }
} else {
  fail("run test authentication server");
}

$child_pid && kill 3, $child_pid;

sub setup_server {

  if (my $child_pid = fork) {
    return $child_pid;
  }

  my $listen_port = shift;

  #########
  # Child process runs a server
  # (similar to http://poe.perl.org/?POE_Cookbook/Web_Server)
  #
  use POE qw(Component::Server::TCP Filter::HTTPD);
  use HTTP::Response;

  POE::Component::Server::TCP->new(
    Port         => $listen_port,
    ClientFilter => 'POE::Filter::HTTPD',
    ClientInput  => sub {
      my ($kernel, $heap, $request) = @_[KERNEL, HEAP, ARG0];

      #########
      # Errors appear as HTTP::Response objects (via filter)
      #
      if ($request->isa("HTTP::Response")) {
        $heap->{client}->put($request);

      } else {
        my ($client_token) = $request->uri() =~ m/token=(.*)$/smx;
        if ($client_token eq 'allow') {
          $heap->{client}->put(HTTP::Response->new(200)); # OK

        } else {
          $heap->{client}->put(HTTP::Response->new(403)); # Forbidden
        }
      }

      $kernel->yield("shutdown");
    }
  );
  $poe_kernel->run();
}
