# XXX - These tests seem to be somewhat flaky and timing-dependent. I
# have seen them all run to completion, and I've seen them fail
# partway through. If someone can come up with a better way to test
# this stuff that'd be great.

use strict;
use warnings;

use Test::More;
BEGIN {
    plan skip_all => 'set TEST_HTTP to enable this test' unless $ENV{TEST_HTTP};
}

use File::Copy qw( copy );
use File::Path;
use FindBin;
use LWP::Simple;
use IO::Socket;
use IPC::Open3;
use Time::HiRes qw/sleep/;
use Catalyst::Helper;
eval "use Catalyst::Devel 1.04;";

plan skip_all => 'Catalyst::Devel >= 1.04 required' if $@;
eval "use File::Copy::Recursive";
plan skip_all => 'File::Copy::Recursive required' if $@;

plan tests => 35;

my $tmpdir = "$FindBin::Bin/../t/tmp";

# clean up
rmtree $tmpdir if -d $tmpdir;

# create a TestApp and copy the test libs into it
mkdir $tmpdir;
chdir $tmpdir;

my $helper = Catalyst::Helper->new(
    {
        '.newfiles' => 1,
    }
);

$helper->mk_app('TestApp');

chdir "$FindBin::Bin/..";

copy_test_app();

# remove TestApp's tests
rmtree 't/tmp/TestApp/t';

# spawn the standalone HTTP server
my $port = 30000 + int rand( 1 + 10000 );

my ( $pid, $server ) = start_server($port);

# change various files
my @files = (
    "$FindBin::Bin/../t/tmp/TestApp/lib/TestApp.pm",
    "$FindBin::Bin/../t/tmp/TestApp/lib/TestApp/Controller/Foo.pm",
    "$FindBin::Bin/../t/tmp/TestApp/lib/TestApp/Controller/Root.pm",
);

# change some files and make sure the server restarts itself
NON_ERROR_RESTART:
for ( 1 .. 5 ) {
    my $index = rand @files;
    open my $pm, '>>', $files[$index]
      or die "Unable to open $files[$index] for writing: $!";
    print $pm "\n";
    close $pm;

    if ( ! look_for_restart() ) {
    SKIP:
        {
            skip "Server did not restart, no sense in checking further", 1;
        }
        next NON_ERROR_RESTART;
    }

    my $response = get("http://localhost:$port/");
    like( $response, qr/Welcome to the  world of Catalyst/,
          'Non-error restart, request OK' );
}

# add errors to the file and make sure server does die
DIES_ON_ERROR:
for ( 1 .. 5 ) {
    my $index = rand @files;
    open my $pm, '>>', $files[$index]
      or die "Unable to open $files[$index] for writing: $!";
    print $pm "bleh";
    close $pm;

    if ( ! look_for_death() ) {
    SKIP:
        {
            skip "Server restarted, no sense in checking further", 2;
        }
        next DIES_ON_ERROR;
    }
    copy_test_app();

    if ( ! look_for_restart() ) {
    SKIP:
        {
            skip "Server did not restart, no sense in checking further", 1;
        }
        next DIES_ON_ERROR;
    }

    my $response = get("http://localhost:$port/");
    like( $response, qr/Welcome to the  world of Catalyst/,
          'Non-error restart after death, request OK' );
}

# multiple restart directories

# we need different options so we have to rebuild most
# of the testing environment

kill 9, $pid or die "Cannot send kill signal to $pid: $!";
close $server or die "Cannot close handle to server process: $!";
wait;

# pick next port because the last one might still be blocked from
# previous server. This might fail if this port is unavailable
# but picking the first one has the same problem so this is acceptable

$port += 1;

copy_test_app();

@files = (
  "$FindBin::Bin/../t/tmp/TestApp/lib/TestApp/Controller/Subdir1/Foo.pm",
  "$FindBin::Bin/../t/tmp/TestApp/lib/TestApp/Controller/Subdir2/Foo.pm",
);

my $app_root = "$FindBin::Bin/../t/tmp/TestApp";
my $restartdirs = join ' ', map{
    "-restartdirectory $app_root/lib/TestApp/Controller/Subdir$_"
} 1, 2;

( $pid, $server ) = start_server($port);

MULTI_DIR_RESTART:
for ( 1 .. 5 ) {
    my $index = rand @files;
    open my $pm, '>>', $files[$index]
      or die "Unable to open $files[$index] for writing: $!";
    print $pm "\n";
    close $pm;

    if ( ! look_for_restart() ) {
    SKIP:
        {
            skip "Server did not restart, no sense in checking further", 1;
        }
        next MULTI_DIR_RESTART;
    }

    my $response = get("http://localhost:$port/");
    like( $response, qr/Welcome to the  world of Catalyst/,
          'Non-error restart with multiple watched dirs' );
}

kill 9, $pid;
close $server;
wait;

rmtree "$FindBin::Bin/../t/tmp" if -d "$FindBin::Bin/../t/tmp";

sub copy_test_app {
    { no warnings 'once'; $File::Copy::Recursive::RMTrgFil = 1; }
    copy( 't/lib/TestApp.pm', 't/tmp/TestApp/lib/TestApp.pm' );
    File::Copy::Recursive::dircopy( 't/lib/TestApp', 't/tmp/TestApp/lib/TestApp' );
}

sub start_server {
    my $port = shift;

    my $server;
    my $pid = open3(
        undef, $server, undef,
        $^X,   "-I$FindBin::Bin/../lib",
        "$FindBin::Bin/../t/tmp/TestApp/script/testapp_server.pl", '--port',
        $port,                                                     '--restart'
    ) or die "Unable to spawn standalone HTTP server: $!";

    # switch to non-blocking reads so we can fail gracefully instead
    # of just hanging forever
    $server->blocking(0);

    my $waited = 0;

    diag('Waiting for server to start...');
    while ( check_port( 'localhost', $port ) != 1 ) {
        sleep 1;
        $waited++;

        if ( $waited >= 10 ) {
            BAIL_OUT('Waited 10 seconds for server to start, to no avail');
        }
    }

    return ($pid, $server);
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

sub look_for_restart {
    # give the server time to notice the change and restart
    my $count = 0;
    my $line;

    while ( ( $line || '' ) !~ /can connect/ ) {
        $line = $server->getline;
        sleep 0.1;
        if ( $count++ > 300 ) {
            fail "Server restarted";
            return 0;
        }
    };

    pass "Server restarted";

    return 1;
}

sub look_for_death {
    # give the server time to notice the change and restart
    my $count = 0;
    my $line;

    while ( ( $line || '' ) !~ /failed/ ) {
        $line = $server->getline;
        sleep 0.1;
        if ( $count++ > 300 ) {
            fail "Server died";
            return 0;
        }
    };

    pass "Server died";

    return 1;
}
