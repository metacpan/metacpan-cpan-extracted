use strict;
use warnings;

use Test::More;

use CPAN::Mini::Inject;
use lib 't/lib';
use Local::localserver;

# if either of these happen, we don't want the tests to fail.
$SIG{'INT'} = $SIG{'TERM'} = sub { print "\nCleaning up before exiting\n"; done_testing(); exit 0 };

my $port =  empty_port();
like $port, qr/\A\d+\z/a, 'port looks like a number';

my( $pid ) = start_server($port);

diag( "$$: PORT: $port" ) if $ENV{TEST_VERBOSE};
diag( "$$: PID: $pid" ) if $ENV{TEST_VERBOSE};

my $url = "http://localhost:$port/";

my $available = 0;
foreach ( 1 .. 4 ) {
  my $sleep = $_ ** 2;
  sleep $sleep;
  diag("Sleeping $sleep seconds waiting for server") if $ENV{TEST_VERBOSE};
  if( can_fetch($url) ) {
  	$available = 1;
  	last;
  	}
  elsif( ! kill 0, $pid ) {
    diag("Server pid is gone") if $ENV{TEST_VERBOSE};
  	last;
  	}
}

# Sometime the server does not come up, but we don't want that to
# stand in the way of people who want to use this.
unless( $available ) {
	diag( "Server never came up. Not attempting to test it." );
	done_testing();
	exit 0;
	}

ok can_fetch($url), "URL $url is available";

my $mcpi = CPAN::Mini::Inject->new;
$mcpi->loadcfg( 't/.mcpani/config' )->parsecfg;
$mcpi->{config}{remote} =~ s/:\d{5}\b/:$port/;

$mcpi->testremote;
is( $mcpi->{site}, $url, "Site URL is $url" );
ok can_fetch($url), "URL $url is available";

$mcpi->loadcfg( 't/.mcpani/config_badremote' )->parsecfg;
$mcpi->{config}{remote} =~ s/:\d{5}\b/:$port/;

SKIP: {
  skip 'Test fails with funky DNS providers', 1
   if can_fetch( 'http://blahblah' );
  # This fails with OpenDNS &c
  $mcpi->testremote;
  is( $mcpi->{site}, $url, 'Selects correct remote URL' );
}

kill( 9, $pid );
unlink( 't/testconfig' );

done_testing();
