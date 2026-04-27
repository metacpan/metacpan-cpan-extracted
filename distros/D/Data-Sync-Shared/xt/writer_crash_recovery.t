use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Sync::Shared;

# RWLock regression: crashed writer must not starve readers.

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $rw = Data::Sync::Shared::RWLock->new($path);

my $writer = fork // die;
if ($writer == 0) {
    my $c = Data::Sync::Shared::RWLock->new($path);
    for (1..1_000_000) { $c->wrlock; $c->wrunlock }
    _exit(0);
}
select undef, undef, undef, 0.1;
kill 9, $writer;
waitpid $writer, 0;

my $t0 = time;
$rw->rdlock;
my $dt = time - $t0;
$rw->rdunlock;
ok $dt < 5, sprintf('rdlock advanced in %.2fs after writer crash', $dt);

unlink $path;
done_testing;
