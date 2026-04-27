use strict;
use warnings;
use Test::More;

use Data::Pool::Shared;

# Skip if RLIMIT_NOFILE is effectively unbounded (containerized CI).
my $nofile = `bash -c 'ulimit -n' 2>/dev/null`;
chomp $nofile;
$nofile = 1024 unless $nofile =~ /^\d+$/;
plan skip_all => "RLIMIT_NOFILE=$nofile too high to exhaust safely"
    if $nofile > 20000;

# Exhaust fds; open until we can't.
my @fds;
while (open(my $fh, '<', '/dev/null')) {
    push @fds, $fh;
}
my $held = scalar @fds;
diag "opened $held fds before exhaustion (!)";

# new_memfd must now fail
my $err;
my $p = eval { Data::Pool::Shared->new_memfd("rl", 1, 8) };
$err = $@ unless $p;

ok !$p, "new_memfd fails at fd exhaustion";
like $err || '', qr/memfd_create|Too many|EMFILE|files open/i,
    "meaningful error: " . ($err // '(no error)');

# Release fds; new_memfd succeeds again
@fds = splice @fds, 0, int($held / 2);
my $p2 = Data::Pool::Shared->new_memfd("rl", 1, 8);
ok $p2, "new_memfd succeeds after releasing fds";

done_testing;
