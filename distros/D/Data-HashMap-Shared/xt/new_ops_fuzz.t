use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# Fuzz the new ops (update_ttl, cas_take, remove_multi, get_with_ttl)
# under multi-process contention. Asserts invariants that hold regardless
# of interleaving: no crashes, size stays sane, get_with_ttl returns
# consistent (value, ttl) pairs.

use File::Temp qw(tmpnam);

sub run_fuzz {
    my ($pkg, $key_fn, $val_fn) = @_;
    my $path = tmpnam() . ".$$";
    my $N_PROC = 4;
    my $OPS = 1500;

    my $m = $pkg->new($path, 8192, 0, 60);
    my @pids;
    for my $k (0 .. $N_PROC - 1) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $c = $pkg->new($path, 8192, 0, 60);
            srand($k * 1000 + $$);
            for my $i (1..$OPS) {
                my $key = $key_fn->(int rand 200);
                my $val = $val_fn->(int rand 1_000);
                my $op = int rand 9;
                if    ($op == 0) { $c->put($key, $val) }
                elsif ($op == 1) { $c->add($key, $val) }
                elsif ($op == 2) { $c->update_ttl($key, $val, 1 + int rand 30) }
                elsif ($op == 3) { $c->add_ttl($key, $val, 1 + int rand 30) }
                elsif ($op == 4) { $c->get($key) }
                elsif ($op == 5) { my ($v, $t) = $c->get_with_ttl($key) }
                elsif ($op == 6) { $c->remove_multi(map { $key_fn->(int rand 200) } 1..5) }
                elsif ($op == 7) { $c->cas_take($key, $val) }
                else             { $c->cas($key, $val, $val_fn->(int rand 1_000)) }
            }
            _exit(0);
        }
        push @pids, $pid;
    }
    my @statuses;
    for my $pid (@pids) { waitpid($pid, 0); push @statuses, $? >> 8 }
    ok($m->size <= 200, "$pkg fuzz: size within keyspace (" . $m->size . ")");
    ok(!grep { $_ != 0 } @statuses, "$pkg fuzz: all children exited cleanly");
    unlink $path;
}

run_fuzz("Data::HashMap::Shared::II", sub { $_[0] }, sub { $_[0] });
run_fuzz("Data::HashMap::Shared::SS", sub { "k" . $_[0] }, sub { "v" . $_[0] });

done_testing;
