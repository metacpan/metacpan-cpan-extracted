#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Deferred;
use Context::Vars qw($snap);

# A callback reads the values of the moment it was queued. Pinned: this is
# the rule, not an accident (proposed decision V3).

my $q = Deferred->new(wired => 1);
my @read;
sub task {
    $snap = 1;
    $q->later(sub { push @read, $snap });
    $snap = 2;
    $q->later(sub { push @read, $snap });
    push @read, "task ends reading $snap";
}
task();
$q->run_all;
is_deeply(\@read, ['task ends reading 2', 1, 2],
          'a callback queued before a later assignment reads the earlier value');

done_testing;
