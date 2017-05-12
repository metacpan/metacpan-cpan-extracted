#!/usr/bin/perl
use strict;
use warnings;

use Carp;
use Cwd;
use File::Temp qw(tempfile);
use IO::Select;
use IO::Socket::INET;
use POSIX qw(sysconf _SC_OPEN_MAX);
use Test::More;
use Test::Exception;
use Test::MockRandom {
    rand => [qw(AI::Evolve::Befunge::Population Algorithm::Evolutionary::Wheel)],
    srand => { main => 'seed' },
    oneish => [qw(main)]
};
use Time::HiRes qw(sleep);

my $incoming; # lines of migration data sent by Population.pm
my $serverpid;
my $port = spawn_test_server();
my($temp, $tempfn) = tempfile();
$temp->print(<<"EOF");
migrationd_host: 127.0.0.1
migrationd_port: $port
popsize: 3
EOF

$ENV{AIEVOLVEBEFUNGE} = $tempfn;

require AI::Evolve::Befunge::Population;

AI::Evolve::Befunge::Util::push_quiet(1);

my $num_tests;
BEGIN { $num_tests = 0; };
plan tests => $num_tests;


# constructor
throws_ok(sub { AI::Evolve::Befunge::Migrator->new() }, qr/'Local' parameter/, 'dies without Local');
BEGIN { $num_tests += 1 };


my $quit1    = "q";
my $scorer1 = "[   @]02M^]20M^]11M^" . (' 'x605);
my $scorer2 = "[   @]22M^]21M^]20M^" . (' 'x605);
my $scorer3 = "[@  <]02M^]20M^]11M^" . (' 'x605);

# migrate (input overrun)
my $population = AI::Evolve::Befunge::Population->load('t/savefile');
is(scalar @{$population->blueprints}, 3, "3 critters to start with");
$population->host('whee');
$population->popsize(5);
sleep(0.25);
seed(0.85);
alarm(3);
$population->migrate();
is($incoming->getline, '[I-4 D4 F3 Hnot_test1]'.$scorer3."\n", 'migration exported a critter');
alarm(0);
my $ref = $population->blueprints;
is(scalar @$ref, 8, 'there are now 8 blueprints in list');
BEGIN { $num_tests += 3 };
my @expected_results = (
    {id => -4,  code => $scorer3,  fitness =>  3, host => 'not_test1'},
    {id => -2,  code => $scorer2,  fitness =>  2, host => 'not_test'},
    {id => -10, code => $quit1,    fitness =>  1, host => 'test'},
    {id => 12345, code => 'abcdefgh', fitness => 31,  host => 'test2'},
    {id => 12346, code => 'abcdefgi', fitness => 30,  host => 'test2'},
    {id => 12347, code => 'abcdefgj', fitness => 29,  host => 'test2'},
    {id => 12348, code => 'abcdefgk', fitness => 28,  host => 'test2'},
    {id => 12349, code => 'abcdefgl', fitness => 27,  host => 'test2'},
);
for my $id (0..@expected_results-1) {
    is($$ref[$id]{id},      $expected_results[$id]{id},      "loaded $id id right");
    is($$ref[$id]{host},    $expected_results[$id]{host},    "loaded $id host right");
    is($$ref[$id]{code},    $expected_results[$id]{code},    "loaded $id code right");
    is($$ref[$id]{fitness}, $expected_results[$id]{fitness}, "loaded $id fitness right");
}
BEGIN { $num_tests += 8*4 };


# migrate (no overrun)
undef $population;
$population = AI::Evolve::Befunge::Population->load('t/savefile');
is(scalar @{$population->blueprints}, 3, "3 critters to start with");
$population->host('whee');
$population->popsize(8);
sleep(0.25);
seed(0.85);
alarm(3);
$population->migrate();
is($incoming->getline, '[I-2 D4 F2 Hnot_test]'.$scorer2."\n", 'migration exported a critter');
$population->migrate();
alarm(0);
$ref = $population->blueprints;
is(scalar @$ref, 9, 'there are now 9 blueprints in list');
BEGIN { $num_tests += 3 };
@expected_results = (
    {id => -4,  code => $scorer3,  fitness =>  3, host => 'not_test1'},
    {id => -2,  code => $scorer2,  fitness =>  2, host => 'not_test'},
    {id => -10, code => $quit1,    fitness =>  1, host => 'test'},
    {id => 12345, code => 'abcdefgh', fitness => 31,  host => 'test2'},
    {id => 12346, code => 'abcdefgi', fitness => 30,  host => 'test2'},
    {id => 12347, code => 'abcdefgj', fitness => 29,  host => 'test2'},
    {id => 12348, code => 'abcdefgk', fitness => 28,  host => 'test2'},
    {id => 12349, code => 'abcdefgl', fitness => 27,  host => 'test2'},
    {id => 12350, code => 'abcdefgm', fitness => 26,  host => 'test2'},
);
for my $id (0..@expected_results-1) {
    is($$ref[$id]{id},      $expected_results[$id]{id},      "loaded $id id right");
    is($$ref[$id]{host},    $expected_results[$id]{host},    "loaded $id host right");
    is($$ref[$id]{code},    $expected_results[$id]{code},    "loaded $id code right");
    is($$ref[$id]{fitness}, $expected_results[$id]{fitness}, "loaded $id fitness right");
}
BEGIN { $num_tests += 9*4 };


# migrate (disconnected from test server)
close($incoming);
lives_ok(sub { $population->migrate() }, 'migrate runs without server connection');
waitpid($serverpid, 0);
lives_ok(sub { $population->migrate() }, 'migrate runs without server connection');
BEGIN { $num_tests += 2 };


# by assigning one side of the socketpair to an external variable, the socket
# will stay open.  When the test script exits, the socket will be closed,
# signalling the child process to exit.
sub spawn_test_server {
    my $listener = IO::Socket::INET->new(
        Listen    => 1,
        LocalAddr => '127.0.0.1',
        Proto     => 'tcp',
        ReuseAddr => 1,
    );
    croak("can't create TCP listener socket") unless defined $listener;
    my $sock2;
    ($incoming, $sock2) = IO::Socket->socketpair(AF_UNIX, SOCK_STREAM, PF_UNSPEC);
    $serverpid = fork();
    if($serverpid) {
        close($sock2);
        my $mysockaddr = $listener->sockname();
        my ($port, $myaddr) = sockaddr_in($mysockaddr);
        return $port;
    }

    for my $fd (0..sysconf(_SC_OPEN_MAX)-1) {
        next if $fd == $listener->fileno();
        next if $fd == $sock2->fileno();
        next if $fd == STDERR->fileno();
        POSIX::close($fd);
    }
    $sock2->blocking(1);
    my $select = IO::Select->new($listener, $sock2);
    while(1) {
#        print(STDERR "sitting in select()\n");
        my @sockets = $select->can_read(10);
#        print(STDERR "select() returned " . scalar(@sockets) . "\n");
        foreach my $socket (@sockets) {
#            print(STDERR "read event from socket " . $socket->fileno() . "\n");
            exit(0) if $socket == $sock2;
            if($socket == $listener) {
#                print(STDERR "new connection\n");
                my $new = $socket->accept();
                $new->blocking(1);
                $new->print(<<EOF);
parse error
[I12345 D3 F31 Htest2\]abcdefgh
[I12346 D3 F30 Htest2\]abcdefgi
[I12347 D3 F29 Htest2\]abcdefgj
[I12348 D3 F28 Htest2\]abcdefgk
[I12349 D3 F27 Htest2\]abcdefgl
[I12350 D3 F26 Htest2\]abcdefgm
EOF
                $select->add($new);
            } else {
                my $data;
                my $rv = $socket->sysread($data, 4096);
                if($rv < 1) {
                    $select->remove($socket);
                } else {
#                    print(STDERR "got data [$data]\n");
                    $sock2->print($data);
                }
            }
        }
    }
}
