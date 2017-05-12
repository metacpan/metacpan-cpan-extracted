#!perl

use strict;
use warnings;

use File::Copy;
use File::Path;
use FindBin;
use IO::Socket;
use Test::More;
eval "use File::Copy::Recursive";

plan skip_all => 'set TEST_POE to enable this test' unless $ENV{TEST_POE};
plan skip_all => 'File::Copy::Recursive required' if $@;
plan tests => 1;

# clean up
rmtree "$FindBin::Bin/../t/tmp" if -d "$FindBin::Bin/../t/tmp";

# create a TestApp and copy the test libs into it
mkdir "$FindBin::Bin/../t/tmp";
chdir "$FindBin::Bin/../t/tmp";
system "catalyst.pl TestApp";
copy "$FindBin::Bin/../t/testapp_poe.pl", "$FindBin::Bin/../t/tmp/TestApp/script/testapp_poe.pl";
chdir "$FindBin::Bin/..";
File::Copy::Recursive::dircopy( 't/lib', 't/tmp/TestApp/lib' );

# remove TestApp's tests
rmtree 't/tmp/TestApp/t';

# remove the Root controller
unlink 't/tmp/TestApp/lib/TestApp/Controller/Root.pm';

# spawn the standalone POE server
my $port = 30000 + int rand(1 + 10000);
my $pid = open my $server, 
    "perl -I$FindBin::Bin/../lib $FindBin::Bin/../t/tmp/TestApp/script/testapp_poe.pl -port $port 2>&1 |"
    or die "Unable to spawn standalone POE server: $!";

# wait for it to start
print "Waiting for server to start...\n";
while ( check_port( 'localhost', $port ) != 1 ) {
    sleep 1;
}

# run the testsuite against the POE server
$ENV{CATALYST_SERVER} = "http://localhost:$port";
system( 'prove -r -Ilib/ t/live_*' );

# shut it down
kill 'INT', $pid;
close $server;

# clean up
rmtree "$FindBin::Bin/../t/tmp" if -d "$FindBin::Bin/../t/tmp";

ok( 'done' );

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
