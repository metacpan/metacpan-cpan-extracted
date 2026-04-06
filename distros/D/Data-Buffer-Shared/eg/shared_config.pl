#!/usr/bin/env perl
# Live-reloadable shared configuration via Str + F64 buffers
#
# Writer process updates config values; reader processes see changes
# immediately without restart. Fixed-slot layout acts as a named config map.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use File::Temp qw(tmpnam);

use Data::Buffer::Shared::Str;
use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::I64;

my $path_keys = tmpnam();
my $path_vals = tmpnam();
END { unlink $path_keys, $path_vals if defined $path_keys }

# config layout: fixed slots, keys are names, values are doubles
# slot 0: "max_connections"
# slot 1: "timeout_sec"
# slot 2: "rate_limit"
# slot 3: "debug_level"
my $nslots = 4;
my $keys = Data::Buffer::Shared::Str->new($path_keys, $nslots, 32);
my $vals = Data::Buffer::Shared::F64->new($path_vals, $nslots);

# initialize config
$keys->set(0, "max_connections"); $vals->set(0, 100);
$keys->set(1, "timeout_sec");     $vals->set(1, 30.0);
$keys->set(2, "rate_limit");      $vals->set(2, 1000.0);
$keys->set(3, "debug_level");     $vals->set(3, 0);

printf "initial config:\n";
for my $i (0..$nslots-1) {
    printf "  %s = %g\n", $keys->get($i), $vals->get($i);
}

# reader process
my $pid = fork();
if ($pid == 0) {
    # reopen by path (simulating a separate process)
    my $rkeys = Data::Buffer::Shared::Str->new($path_keys, $nslots, 32);
    my $rvals = Data::Buffer::Shared::F64->new($path_vals, $nslots);

    sleep 0.05;  # wait for writer to update
    printf "\nreader sees after update:\n";
    for my $i (0..$nslots-1) {
        printf "  %s = %g\n", $rkeys->get($i), $rvals->get($i);
    }
    _exit(0);
}

# writer updates config
$vals->set(0, 200);    # max_connections: 100 → 200
$vals->set(1, 60.0);   # timeout: 30 → 60
$vals->set(3, 1);      # debug: off → on
printf "\nwriter updated: max_connections=200, timeout=60, debug=1\n";

waitpid($pid, 0);
