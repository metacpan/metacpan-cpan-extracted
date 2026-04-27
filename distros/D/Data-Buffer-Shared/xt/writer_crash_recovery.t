use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Buffer::Shared::I64;

# Regression: crashed parked writer must not indefinitely starve readers.

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $b = Data::Buffer::Shared::I64->new($path, 1024);
$b->set(0, 100);

my $writer = fork // die;
if ($writer == 0) {
    my $c = Data::Buffer::Shared::I64->new($path, 1024);
    for (1..10_000_000) { $c->set($_ % 1024, $_) }
    _exit(0);
}
select undef, undef, undef, 0.1;
kill 9, $writer;
waitpid $writer, 0;

my $t0 = time;
my $v = $b->get(0);
my $dt = time - $t0;
ok defined($v), 'reader got value after writer crash';
ok $dt < 5, sprintf('reader advanced in %.2fs', $dt);

unlink $path;
done_testing;
