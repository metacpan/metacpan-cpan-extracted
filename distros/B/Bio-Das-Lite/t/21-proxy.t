use strict;
use warnings;

use Bio::Das::Lite;
use Test::More;
use English qw(-no_match_vars);

BEGIN {
  eval {
    require POE;
    require WWW::Curl::Simple;
    POE->import(qw(Component::Server::TCP Filter::HTTPD));
    require HTTP::Response;
  };

  if ($EVAL_ERROR) {
    plan skip_all => 'Proxy testing requires POE and WWW::Curl::Simple';
  } else {
    plan tests => 11;
  }
}

# We will only communicate with the local host on the loopback interface, we don't want interference from a proxy!
delete $ENV{http_proxy};

my ($child_pid, $port) = &setup_server;
if ($child_pid && $port) {
  pass("run test proxy server");

  my $dsn = 'http://www.ensembl.org/das/Homo_sapiens.GRCh37.reference';

  $ENV{http_proxy} = undef if $ENV{http_proxy};

  my $dl = Bio::Das::Lite->new($dsn);
  $dl->features('1:1,2');
  my $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
  unlike($status, qr/PROXY/smx, 'direct connection');

  SKIP: {

    if (! defined $Bio::Das::Lite::{CURLOPT_NOPROXY} ) {
      skip 'proxy support DISABLED as unsupported by your version of libcurl', 9;
    }

    $dl = Bio::Das::Lite->new({dsn => $dsn, http_proxy => "http://127.0.0.1:$port"});
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    is($status, '200 (OK) PROXY', 'basic proxy (constructor)');

    $dl = Bio::Das::Lite->new($dsn);
    $dl->http_proxy("http://127.0.0.1:$port");
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    is($status, '200 (OK) PROXY', 'basic proxy (method)');

    if (! defined $Bio::Das::Lite::{CURLOPT_PROXYUSERNAME} || !defined $Bio::Das::Lite::{CURLOPT_PROXYPASSWORD} ) {
      skip 'authenticating proxy support DISABLED as unsupported by your version of libcurl', 1;
    }

    $dl = Bio::Das::Lite->new($dsn);
    $dl->http_proxy("http://user:pass\@127.0.0.1:$port");
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    is($status, '200 (OK) PROXY user:pass', 'authenticated proxy (method)');

    $ENV{http_proxy} = "http://127.0.0.1:$port";
    $dl = Bio::Das::Lite->new($dsn);
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    is($status, '200 (OK) PROXY', 'basic proxy (environment)');

    if (! defined $Bio::Das::Lite::{CURLOPT_NOPROXY} ) {
      skip 'no_proxy support DISABLED as unsupported by your version of libcurl', 5;
    }

    $dl = Bio::Das::Lite->new({dsn=>$dsn,no_proxy=>'ensembl.org'});
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    unlike($status, qr/PROXY/smx, 'no-proxy (constructor) positive match');
  
    $dl = Bio::Das::Lite->new($dsn);
    $dl->no_proxy('ensembl.org', 'another.com');
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    unlike($status, qr/PROXY/smx, 'no-proxy (method list) positive match');
  
    $dl = Bio::Das::Lite->new($dsn);
    $dl->no_proxy('wibble.com', 'another.com');
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    is($status, '200 (OK) PROXY', 'no-proxy (method list) negative match');
  
    $dl = Bio::Das::Lite->new($dsn);
    $dl->no_proxy(['ensembl.org', 'another.com']);
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    unlike($status, qr/PROXY/smx, 'no-proxy (method listref) positive match');
  
    $ENV{no_proxy} = 'ensembl.org, another.com';
    $dl = Bio::Das::Lite->new($dsn);
    $dl->features('1:1,2');
    $status = $dl->statuscodes("$dsn/features?segment=1:1,2");
    unlike($status, qr/PROXY/smx, 'no-proxy (environment) positive match');
  };

} else {
  fail("run test proxy server");
}

kill_child();

sub kill_child {
  $child_pid && kill 9, $child_pid;
}

$SIG{INT} = \&kill_child;

sub setup_server {
  # Set up a server and check it is listening.
  my $port;
  my $child_pid;
  my $agent = WWW::Curl::Simple->new(timeout=>1);

  for my $test_port (10000 .. 10010) {
    $child_pid = fork_server($test_port);
    my $resp;
    eval {
      $resp = $agent->get("http://127.0.0.1:$test_port");
    };

    if ($@) {
      warn "Error from test server on port $test_port - ".$@;
    } elsif (!$resp) {
      warn "No response from test server on port $test_port";
    } elsif ($resp->status_line() =~ m/^200 \(OK\) PROXY/) {
      $port = $test_port;
      last;
    } else {
      warn "Unexpected status from test server on port $test_port - ".$resp->status_line;
    }
    kill 9, $child_pid; wait;
    undef $child_pid;
  }

  return ($child_pid, $port);
}

sub fork_server {

  if (my $child_pid = fork) {
    return $child_pid;
  }

  my $listen_port = shift;

  eval {
    # Child process runs a server
    # (similar to http://poe.perl.org/?POE_Cookbook/Web_Server)
    POE::Component::Server::TCP->new(
      Port         => $listen_port,
      ClientFilter => 'POE::Filter::HTTPD',
      ClientInput  => sub {
        my ($kernel, $heap, $req_or_resp) = @_[KERNEL, HEAP, ARG0];
        # Errors appear as HTTP::Response objects (via filter)
        if ($req_or_resp->isa(q[HTTP::Request])) {
          my $auth = $req_or_resp->proxy_authorization_basic;
          $req_or_resp = HTTP::Response->new(200, $auth ? 'PROXY ' . $auth : 'PROXY'); # OK
          $req_or_resp->content('FAKE CONTENT');
        }
        $heap->{client}->put($req_or_resp);
        $kernel->yield(q[shutdown]);
      }
    );

    $poe_kernel->run();
  };
}
