use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'Linux memfd required' unless $^O eq 'linux';

use Data::SpatialHash::Shared;

# new_memfd seals the memfd against resize (F_SEAL_SHRINK | F_SEAL_GROW) so the
# backing store cannot be truncated out from under a live mapping.

my $s  = Data::SpatialHash::Shared->new_memfd('seal-test', 100, 0, 1.0);
my $fd = $s->memfd;
cmp_ok $fd, '>=', 0, 'memfd fd';

open my $fh, '+<&=', $fd or die "fdopen: $!";
my $seals = fcntl($fh, 1034, 0);   # F_GET_SEALS
ok defined $seals, 'F_GET_SEALS works';
ok $seals & 2, 'F_SEAL_SHRINK set';   # F_SEAL_SHRINK = 2
ok $seals & 4, 'F_SEAL_GROW set';     # F_SEAL_GROW   = 4
ok !truncate($fh, 64), 'ftruncate on a sealed memfd is refused (EPERM)';

done_testing;
