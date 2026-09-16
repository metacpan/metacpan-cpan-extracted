use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# A max_size that needs every slot the map holds can never evict, so the
# constructor warns.  Under `use warnings FATAL => ...`, or any __WARN__ handler
# that dies, that warning croaks -- and it used to croak before the handle
# belonged to any SV, so nothing ever freed the mmap, or the descriptor a memfd
# map owns.  The object is built first now, with a pending free across the
# warning that only a survivor cancels.
#
# The two ways a warning croaks take different paths through perl: a dying
# handler runs from the warn hook, FATAL croaks straight out of the warner and
# never reaches a hook.  The pragma has to be in the scope of the constructor
# call itself, since the warning bits come from the caller's statement.

plan skip_all => 'needs /proc for fd and mapping counts' unless -r "/proc/$$/maps";

my $dir = tempdir(CLEANUP => 1);
sub fds  { opendir my $d, "/proc/$$/fd" or die $!; scalar grep { !/^\./ } readdir $d }
sub vmas { open my $f, '<', "/proc/$$/maps" or die $!; my $n = 0; $n++ while <$f>; $n }

my $N = 60;

# The croak has to happen, or the rest of the file proves nothing.
my $warned = 0;
{
    local $SIG{__WARN__} = sub { $warned++ };
    my $m = Data::HashMap::Shared::SS->new("$dir/warn.shm", 64, 4096);
}
is $warned, 1, 'an unreachable max_size warns from the constructor';

# A memfd map to reopen by descriptor; its own warning is not under test.
my $src = do { local $SIG{__WARN__} = sub {}; Data::HashMap::Shared::SS->new_memfd('src', 64, 4096) };
my $fd  = $src->memfd;

my %ctor = (
    'file-backed' => [
        sub { Data::HashMap::Shared::SS->new("$dir/f$_[0].shm", 64, 4096) },
        sub { use warnings FATAL => 'misc'; Data::HashMap::Shared::SS->new("$dir/F$_[0].shm", 64, 4096) },
    ],
    'memfd' => [
        sub { Data::HashMap::Shared::SS->new_memfd("m$_[0]", 64, 4096) },
        sub { use warnings FATAL => 'misc'; Data::HashMap::Shared::SS->new_memfd("M$_[0]", 64, 4096) },
    ],
    'from_fd' => [
        sub { Data::HashMap::Shared::SS->new_from_fd($fd) },
        sub { use warnings FATAL => 'misc'; Data::HashMap::Shared::SS->new_from_fd($fd) },
    ],
    'sharded x4' => [
        sub { Data::HashMap::Shared::SS->new_sharded("$dir/s$_[0]", 4, 64, 4096) },
        sub { use warnings FATAL => 'misc'; Data::HashMap::Shared::SS->new_sharded("$dir/S$_[0]", 4, 64, 4096) },
    ],
);

for my $what (sort keys %ctor) {
    my ($plain, $fatal) = @{ $ctor{$what} };
    for my $how (
        ['a dying __WARN__ handler', sub { local $SIG{__WARN__} = sub { die "fatal warning: $_[0]" }; $plain->(shift) }],
        ['use warnings FATAL',       $fatal],
    ) {
        my ($via, $make) = @$how;
        my ($f0, $v0) = (fds(), vmas());
        my $croaks = 0;
        for my $i (1 .. $N) {
            eval { my $m = $make->($i); 1 } or $croaks++;
        }
        is $croaks, $N, "$what under $via: every attempt croaked";
        cmp_ok fds()  - $f0, '<=', 2, "  ... leaking no descriptors";
        cmp_ok vmas() - $v0, '<=', 2, "  ... and no mappings"
            or diag sprintf '%s under %s: %+d mappings over %d attempts', $what, $via, vmas() - $v0, $N;
    }
}

# The object still works when the warning is not fatal, and when there is none.
{
    my $m = do { local $SIG{__WARN__} = sub {}; Data::HashMap::Shared::SS->new("$dir/ok.shm", 64, 4096) };
    ok $m->put(a => 'b'), 'a map whose warning was not fatal is usable';
    is $m->get('a'), 'b', '  ... and stores correctly';
}
{
    my $m = Data::HashMap::Shared::SS->new("$dir/q.shm", 4096, 64);
    ok $m->put(a => 'b'), 'and so is one that never warned';
}

done_testing;
