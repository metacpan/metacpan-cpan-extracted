use strict;
use warnings;

use FindBin;
use IO::Socket;
use Test::More;

eval <<_DEPS_;
   use Test::WWW::Mechanize;
   use Catalyst::Runtime;
   use Catalyst::Devel;
   use Cache::FastMmap;
   use Catalyst::Authentication::User::Hash;
   use Catalyst::Plugin::Session::State::Cookie;
   use Catalyst::Plugin::Session::Store::FastMmap;
   use Class::Accessor::Fast;
   use Crypt::DH;
   use ExtUtils::MakeMaker;
   use HTML::Parser 3;
   use LWP::UserAgent;
   use Net::OpenID::Consumer;
   use Net::OpenID::Server;
   use Test::WWW::Mechanize;
   use Net::DNS;
   use IO::Socket::INET;
_DEPS_

if ( $@ )
{
    plan skip_all => 'Test application dependencies not satisfied ' . $@;
}
elsif ( not $ENV{TEST_HTTP} )
{
    plan skip_all => 'Set TEST_HTTP to enable this test';
}
else
{
    plan tests => 21;
}

# One port for consumer app, one for provider.
my $consumer_port = 10000 + int rand(1 + 10000);
my $provider_port = $consumer_port;
$provider_port = 10000 + int rand(1 + 10000) until $consumer_port != $provider_port;

my $provider_pipe = "perl -I$FindBin::Bin/../lib -I$FindBin::Bin/Provider/lib $FindBin::Bin/Provider/script/testapp_server.pl -p $consumer_port |";

my $consumer_pipe = "perl -I$FindBin::Bin/../lib -I$FindBin::Bin/Consumer/lib $FindBin::Bin/Consumer/script/testapp_server.pl -p $provider_port |";

my $provider_pid = open my $provider, $provider_pipe
    or die "Unable to spawn standalone HTTP server for Provider: $!";

diag("Started Provider with pid $provider_pid");

my $consumer_pid = open my $consumer, $consumer_pipe
    or die "Unable to spawn standalone HTTP server for Consumer: $!";

diag("Started Consumer with pid $consumer_pid");

# How long to wait for test server to start and timeout for UA.
my $seconds = 15;

diag("Waiting (up to $seconds seconds) for application servers to start...");

eval {
    local $SIG{ALRM} = sub { die "Servers took too long to start\n" }; # NB: \n required
    alarm($seconds);
    sleep 1 while check_port( 'localhost', $provider_port ) != 1;
    sleep 1 while check_port( 'localhost', $consumer_port ) != 1;
    alarm(0)
};

if ( $@ )
{
    shut_down();
    die "Could not run test: $@";
}

my $openid_consumer = $ENV{CATALYST_SERVER} = "http://localhost:$consumer_port";
my $openid_server = "http://localhost:$provider_port";

# Tests start --------------------------------------------
diag("Started...") if $ENV{TEST_VERBOSE};

my $mech = Test::WWW::Mechanize->new(timeout => $seconds);

$mech->get_ok($openid_consumer, "GET $openid_consumer");

$mech->content_contains("You are not signed in.", "Content looks right");

$mech->get_ok("$openid_consumer/signin_openid", "GET $openid_consumer/signin_openid");

{
    my $claimed_uri = "$openid_server/provider/paco";

    $mech->submit_form_ok({ form_name => "openid",
                            fields => { openid_identifier => $claimed_uri,
                            },
                          },
                          "Trying OpenID login, 'openid' realm");

    $mech->content_contains("You're not signed in so you can't be verified",
                            "Can't use OpenID, not signed in at provider");
}

# Bad claimed URI.
{
    my $claimed_uri = "gopher://localhost:443/what?";
    $mech->back();
    $mech->submit_form( form_name => "openid",
                         fields => { openid_identifier => $claimed_uri,
                                   },
                       );

    diag("Trying OpenID with ridiculous URI")
        if $ENV{TEST_VERBOSE};

    # no_identity_server: The provided URL doesn't declare its OpenID identity server.

    is( $mech->status, 500,
        "Can't use OpenID: bogus_url" );
}

# Bad claimed URI.
{
    my $claimed_uri = "localhost/some/path";
    $mech->back();
    $mech->submit_form( form_name => "openid",
                         fields => { openid_identifier => $claimed_uri,
                                   },
                       );

    diag("Trying OpenID with phony URI")
        if $ENV{TEST_VERBOSE};

    # no_identity_server: The provided URL doesn't declare its OpenID identity server.
    is( $mech->status, 500,
        "Can't use OpenID: no_identity_server");
}



#
$mech->get_ok("$openid_server/login", "GET $openid_consumer/login");

# diag($mech->content);

$mech->submit_form_ok({ form_name => "login",
                        fields => { username => "paco",
                                    password => "l4s4v3n7ur45",
                                },
                       },
                      "Trying cleartext login, 'memebers' realm");

$mech->content_contains("signed in", "Signed in successfully");

$mech->get_ok("$openid_consumer/signin_openid", "GET $openid_consumer/signin_openid");

$mech->content_contains("Sign in with OpenID", "Content looks right");

my $claimed_uri = "$openid_server/provider/paco";

$mech->submit_form_ok({ form_name => "openid",
                        fields => { openid_identifier => $claimed_uri,
                                },
                    },
                      "Trying OpenID login, 'openid' realm");

$mech->content_contains("You did it with OpenID!",
                        "Successfully signed in with OpenID");

$mech->get_ok($openid_consumer, "GET $openid_consumer");

$mech->content_contains("provider/paco", "OpenID info is in the user");

# can't be verified

$mech->get_ok("$openid_consumer/logout", "GET $openid_consumer/logout");

$mech->get_ok("$openid_consumer/signin_openid", "GET $openid_consumer/signin_openid");

$mech->content_contains("Sign in with OpenID", "Content looks right");

$mech->submit_form_ok({ form_name => "openid",
                        fields => { openid_identifier => $claimed_uri,
                                },
                    },
                      "Trying OpenID login, 'openid' realm");

$mech->content_contains("can't be verified",
                        "Proper failure for unauthenticated memember.");

shut_down();

exit 0;

# Tests end ----------------------------------------------

sub shut_down {
    kill INT => $provider_pid, $consumer_pid;
    close $provider;
    close $consumer;
}

sub check_port {
    my ( $host, $port ) = @_;

    my $remote = IO::Socket::INET->new(
        Proto    => "tcp",
        PeerAddr => $host,
        PeerPort => $port
    );
    if ($remote) {
        close $remote;
        return 1;
    }
    else {
        return 0;
    }
}

__END__

