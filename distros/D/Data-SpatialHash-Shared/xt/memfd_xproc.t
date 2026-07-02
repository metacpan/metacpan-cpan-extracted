use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';
use POSIX qw(_exit);
use Data::SpatialHash::Shared;

# An unrelated process accesses a memfd-backed index it did NOT inherit, via
# /proc/<creator-pid>/fd/<n> -- the cross-process sharing memfd exists for.
# (SCM_RIGHTS over a unix socket is the alternative when the creator may exit.)

pipe(my $R, my $W) or die "pipe: $!";
my $pid = fork // die "fork: $!";
if (!$pid) {                       # creator builds the index AFTER fork
    close $R;
    my $s = Data::SpatialHash::Shared->new_memfd('xproc', 1000, 0, 1.0);
    $s->insert($_ + 0.5, 0.5, $_ * 100) for 1 .. 20;
    syswrite $W, $$ . ' ' . $s->memfd . "\n";
    close $W;
    select undef, undef, undef, 5;          # stay alive so /proc/$$/fd/N persists
    _exit(0);
}
close $W;
my ($cpid, $cfd) = split ' ', scalar(<$R>);
open my $fh, '+<', "/proc/$cpid/fd/$cfd" or die "open /proc/$cpid/fd/$cfd: $!";
my $s2 = Data::SpatialHash::Shared->new_from_fd(fileno $fh);

is $s2->count, 20, "unrelated process sees the creator's 20 entries";
is_deeply [sort { $a <=> $b } $s2->query_aabb(-1, -1, 100, 100)],
          [map { $_ * 100 } 1 .. 20], 'all entries visible via the passed memfd';
my $h = $s2->insert(50.5, 50.5, -7);          # write into the shared memory
ok scalar(grep { $_ == -7 } $s2->query_radius(50.5, 50.5, 1)), 'writes via the passed fd land in the shared map';

kill 'TERM', $cpid; waitpid $cpid, 0;
done_testing;
