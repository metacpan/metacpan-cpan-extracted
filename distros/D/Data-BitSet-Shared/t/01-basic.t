use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::BitSet::Shared;

my $bs = Data::BitSet::Shared->new(undef, 256);
ok $bs, 'created';
is $bs->capacity, 256;
is $bs->count, 0;
ok $bs->none, 'none initially';

# set/test
is $bs->set(0), 0, 'set(0) returns old=0';
is $bs->test(0), 1, 'test(0)=1';
is $bs->set(0), 1, 'set(0) again returns old=1';
is $bs->count, 1;
ok $bs->any;

# set more
$bs->set(10);
$bs->set(100);
$bs->set(255);
is $bs->count, 4;

# clear
is $bs->clear(10), 1, 'clear returns old=1';
is $bs->clear(10), 0, 'clear again returns old=0';
is $bs->test(10), 0;
is $bs->count, 3;

# toggle
is $bs->toggle(50), 1, 'toggle 0->1 returns new=1';
is $bs->test(50), 1;
is $bs->toggle(50), 0, 'toggle 1->0 returns new=0';
is $bs->test(50), 0;

# first_set / first_clear
$bs->zero;
$bs->set(42);
is $bs->first_set, 42, 'first_set';
is $bs->first_clear, 0, 'first_clear';

$bs->fill;
is $bs->count, 256, 'fill sets all';
ok !defined $bs->first_clear, 'first_clear on full = undef';
is $bs->first_set, 0, 'first_set on full = 0';

$bs->zero;
is $bs->count, 0, 'zero clears all';
ok !defined $bs->first_set, 'first_set on empty = undef';

# set_bits
$bs->set(3);
$bs->set(7);
$bs->set(15);
my @bits = $bs->set_bits;
is_deeply \@bits, [3, 7, 15], 'set_bits';

# to_string
$bs->zero;
$bs->set(0);
$bs->set(2);
$bs->set(4);
my $str = $bs->to_string;
like $str, qr/^10101/, 'to_string';
is length($str), 256;

# stringification overload
like "$bs", qr/^10101/, 'overloaded ""';

# out of range
eval { $bs->set(999) };
like $@, qr/out of range/, 'set out of range';
eval { $bs->test(256) };
like $@, qr/out of range/, 'test out of range';

# boundary: capacity=64 (exactly one word)
my $b64 = Data::BitSet::Shared->new(undef, 64);
$b64->set(0);
$b64->set(63);
is $b64->count, 2;
$b64->fill;
is $b64->count, 64;

# boundary: capacity=65 (one word + 1 bit)
my $b65 = Data::BitSet::Shared->new(undef, 65);
$b65->fill;
is $b65->count, 65, 'cap=65 fill';
ok !defined $b65->first_clear;

# cross-process
$bs->zero;
$bs->set(42);
my $pid = fork // die;
if ($pid == 0) {
    _exit($bs->test(42) == 1 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'cross-process read';

# concurrent set from child
$pid = fork // die;
if ($pid == 0) {
    $bs->set(99);
    _exit(0);
}
waitpid($pid, 0);
is $bs->test(99), 1, 'cross-process set';

# file persistence
my $path = tmpnam() . '.shm';
{
    my $fb = Data::BitSet::Shared->new($path, 128);
    $fb->set(10);
    $fb->set(20);
    is $fb->path, $path;
}
{
    my $fb = Data::BitSet::Shared->new($path, 128);
    is $fb->count, 2, 'persistence';
    is $fb->test(10), 1;
}
unlink $path;

# memfd
my $mb = Data::BitSet::Shared->new_memfd("test", 128);
$mb->set(5);
my $mb2 = Data::BitSet::Shared->new_from_fd($mb->memfd);
is $mb2->test(5), 1, 'memfd fd passing';

# stats
my $s = $bs->stats;
ok ref $s eq 'HASH';
ok $s->{sets} > 0;
ok exists $s->{count};

done_testing;
