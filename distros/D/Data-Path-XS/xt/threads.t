use strict;
use warnings;
use Config;
use Test::More;

BEGIN {
    if (!$Config{useithreads}) {
        plan skip_all => 'this Perl was built without ithreads';
    }
    require threads;
    threads->import;
}

use Data::Path::XS qw(path_get path_set path_compile pathc_get pathc_set);

# The POD's THREAD SAFETY section says:
#   - the module uses no global state;
#   - per-thread data is fine;
#   - compiled-path objects must not be shared.
#
# Pin those guarantees: spawn N threads, each with its own data and its
# own compiled paths, and confirm that they all complete with consistent
# results and no crashes.

my $N = 8;
my $ITERS = 2000;
my $parent_path = path_compile('/value');

my @threads = map {
    threads->create(sub {
        my $tid = $_;
        eval { pathc_get({ value => 42 }, $parent_path) };
        return [$tid, 0, 'inherited compiled path accepted']
            unless $@ =~ /Not a compiled path/;
        my $data = {};
        my $cp_set = path_compile('/users/0/name');
        my $cp_get = path_compile('/users/0/name');
        for my $i (1 .. $ITERS) {
            path_set($data, "/k$i", $i + $tid);
            pathc_set($data, $cp_set, "alice-$tid-$i");
            my $v = pathc_get($data, $cp_get);
            return [$tid, $i, "got=$v"] if $v ne "alice-$tid-$i";
        }
        return [$tid, $ITERS, 'ok'];
    });
} 0 .. $N - 1;

for my $t (@threads) {
    my $r = $t->join;
    is($r->[2], 'ok', "thread $r->[0] completed $ITERS iterations");
    is(pathc_get({ value => 42 }, $parent_path), 42,
       'parent compiled path survives thread destruction');
}

done_testing;
