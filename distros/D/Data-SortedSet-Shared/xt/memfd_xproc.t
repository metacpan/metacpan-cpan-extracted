use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux /proc required' unless -d '/proc/self/fd';
use POSIX qw(_exit);
use Data::SortedSet::Shared;

# An unrelated process accesses a memfd-backed set it did NOT inherit, via
# /proc/<creator-pid>/fd/<n> -- the cross-process sharing memfd exists for.
pipe(my $R, my $W) or die "pipe: $!";
my $pid = fork // die "fork: $!";
if (!$pid) {                       # creator builds the set AFTER fork
    close $R;
    my $z = Data::SortedSet::Shared->new_memfd('xproc', 1000);
    $z->add($_, $_ + 0.5) for 1 .. 20;            # member k, score k+0.5 -> order is 1..20
    syswrite $W, $$ . ' ' . $z->memfd . "\n";
    close $W;
    select undef, undef, undef, 5;                # stay alive so /proc/$$/fd/N persists
    _exit(0);
}
close $W;
my ($cpid, $cfd) = split ' ', scalar(<$R>);
open my $fh, '+<', "/proc/$cpid/fd/$cfd" or die "open /proc/$cpid/fd/$cfd: $!";
my $z2 = Data::SortedSet::Shared->new_from_fd(fileno $fh);

is $z2->count, 20, "unrelated process sees the creator's 20 members";
my @m;
$z2->each(sub { push @m, $_[0] });
is_deeply \@m, [1 .. 20], 'all members visible via the passed memfd, in score order';
is $z2->add(99, 0.25), 1, 'write a member through the passed fd';
ok $z2->exists(99), 'writes via the passed fd land in the shared map';
is $z2->at_rank(0), 99, 'new member (lowest score) ranks first across the shared mapping';

kill 'TERM', $cpid;
waitpid $cpid, 0;
done_testing;
