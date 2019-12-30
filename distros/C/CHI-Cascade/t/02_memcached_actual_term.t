use strict;

use lib 't/lib';
use test_01_actual_term;

use Test::More;

use CHI;
use CHI::Cascade;

plan skip_all => 'Not installed CHI::Driver::Memcached::Fast'
  unless eval "use CHI::Driver::Memcached::Fast; 1";

plan skip_all => 'Memcached tests are skipped (to define FORCE_MEMCACHED_TESTS environment variable if you want)'
  unless defined $ENV{FORCE_MEMCACHED_TESTS};

my ($pid_file, $socket_file, $cwd, $user_opt);

chomp($cwd = `pwd`);

if ($< == 0) {
    # if root - other options
    $pid_file           = "/tmp/memcached.$$.pid";
    $socket_file        = "/tmp/memcached.$$.socket";
    $user_opt           = '-u nobody';

}
else {
    $pid_file           = "$cwd/t/memcached.$$.pid";
    $socket_file        = "$cwd/t/memcached.$$.socket";
    $user_opt           = '';
}

my $out = `memcached $user_opt -d -s $socket_file -a 644 -m 64 -P $pid_file -t 2 2>&1`;

$SIG{__DIE__} = sub {
    `{ kill \`cat $pid_file\`; } >/dev/null 2>&1`;
    unlink $pid_file    unless -l $pid_file;
    unlink $socket_file unless -l $socket_file;
    $SIG{__DIE__} = 'IGNORE';
};

$SIG{TERM} = $SIG{INT} = $SIG{HUP} = sub { die "Terminated by signal " . shift };

sleep 1;

if ( $? || ! (-f $pid_file )) {
    ( defined($out) && chomp($out) ) || ( $out = '' );
    plan skip_all => "Cannot start the memcached for this test ($out)";
}
else {
    plan tests => 32;
}

my $cascade = CHI::Cascade->new(
    chi => CHI->new(
        driver          => 'Memcached::Fast',
        servers         => [$socket_file],
        namespace       => 'CHI::Cascade::tests'
    )
);

test_cascade($cascade);

$SIG{__DIE__} eq 'IGNORE' || $SIG{__DIE__}->();
