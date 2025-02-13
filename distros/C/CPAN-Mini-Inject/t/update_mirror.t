use strict;
use warnings;

use Test::More;

use CPAN::Mini::Inject;
use File::Path;
use File::Spec::Functions;
use File::Temp ();

use lib 't/lib';
use Local::localserver;
use Local::utils;

# if either of these happen, we don't want the tests to fail.
$SIG{'INT'} = $SIG{'TERM'} = sub { print "\nCleaning up before exiting\n"; done_testing(); exit };
my $tmp_dir = File::Temp::tempdir( CLEANUP => 1 );
my $tmp_config_file;

# some CPAN testers had problems with this
unless( -w $tmp_dir ) {
	diag("/tmp was not writeable, so not continuing");
	pass();
	exit;
	}

my $url;
my $port;
my $pid;
subtest 'start local server' => sub {
	$port = empty_port();
	( $pid ) = start_server($port);

	diag( "$$: PORT: $port" ) if $ENV{TEST_VERBOSE};
	diag( "$$: PID: $pid" ) if $ENV{TEST_VERBOSE};

	$url = "http://localhost:$port/";

	foreach ( 1 .. 4 ) {
		my $sleep = $_ * 2;
		sleep $sleep;
		diag("Sleeping $sleep seconds waiting for server") if $ENV{TEST_VERBOSE};
		last if can_fetch($url);
		}

	ok can_fetch($url), "URL $url is available";
	};

subtest 'make config' => sub {
	$tmp_config_file = write_config(
		local      => catfile( qw(t local CPAN) ),
		remote     => $url,
		repository => $tmp_dir,
		);
	diag("Temp file is <$tmp_config_file>") if $ENV{TEST_VERBOSE};

	ok -e $tmp_config_file, "<tmp_config_file> exists";
	};

my $mcpi;
subtest 'setup' => sub {
	my $class = 'CPAN::Mini::Inject';
	use_ok $class;
	$mcpi = $class->new;
	isa_ok $mcpi, $class;
	};

subtest 'testremote' => sub {
	$mcpi->loadcfg( $tmp_config_file )->parsecfg;
	$mcpi->{config}{remote} =~ s/:\d{5}\b/:$port/;

	ok can_fetch($url), "URL $url is available";

	eval { $mcpi->testremote } or print STDERR "testremote died: $@";

	ok can_fetch($url), "URL $url is still available";

	is( $mcpi->{site}, $url, "Site URL is $url" );
	};

subtest 'update mirror' => sub {
	ok( -e $tmp_dir, 'mirror directory exists' );

	# a couple of CPAN Testers have this problem.
	unless( -w $tmp_dir ) {
		diag( "temp dir is not writable? Skipping these tests" );
		return;
	}

	ok can_fetch($url), "URL $url is available";

	eval {
		$mcpi->update_mirror(
			remote    => $url,
			local     => $tmp_dir,
			trace     => 1,
			log_level => 'error',
			verbose   => 0,
			);
		} or diag( "update_mirror died: $@" );
	};

subtest 'mirror state' => sub {
	unless( -w $tmp_dir ) {
		diag( "temp dir is not writable? Skipping these tests" );
		return;
	}

	ok( -e catfile( $tmp_dir, qw(authors) ), 'authors/ exists' );
	ok( -e catfile( $tmp_dir, qw(modules) ), 'modules/ exists' );
	ok( -e catfile( $tmp_dir, qw(authors 01mailrc.txt.gz) ), '01mailrc.txt.gz exists' );
	ok( -e catfile( $tmp_dir, qw(modules 02packages.details.txt.gz) ), '02packages.details.txt.gz exists' );
	ok( -e catfile( $tmp_dir, qw(modules 03modlist.data.gz) ), '03modlist.data.gz exists' );
	ok( -e catfile( $tmp_dir, qw(authors id R RJ RJBS CHECKSUMS) ), 'RJBS/CHECKSUMS exists' );
	ok( -e catfile( $tmp_dir, qw(authors id R RJ RJBS CPAN-Mini-2.1828.tar.gz) ), 'CPAN-Mini-2.1828.tar.gz exists' );
	ok( -e catfile( $tmp_dir, qw(authors id S SS SSORICHE CHECKSUMS) ), 'SSORICHE/CHECKSUMS exists' );
	ok( -e catfile( $tmp_dir, qw(authors id S SS SSORICHE CPAN-Mini-Inject-1.01.tar.gz) ), 'CPAN::Mini::Inject exixts' );
	};

sleep 1; # allow locks to expire
kill( 9, $pid );

done_testing();
