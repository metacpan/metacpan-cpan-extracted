use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::Buffer::Shared::I64;

my $path = tmpnam();
END { unlink $path if $path && -f $path }

my $buf = Data::Buffer::Shared::I64->new($path, 100);
isa_ok($buf, 'Data::Buffer::Shared::I64');

# capacity / elem_size
is($buf->capacity, 100, 'capacity');
is($buf->elem_size, 8, 'elem_size');

# set / get
ok($buf->set(0, 42), 'set');
is($buf->get(0), 42, 'get');

# keyword API
buf_i64_set $buf, 1, 99;
my $kv = buf_i64_get $buf, 1;
is($kv, 99, 'keyword get/set');

# out of bounds
is($buf->get(100), undef, 'get out of bounds');
ok(!$buf->set(100, 1), 'set out of bounds');

# zero initialized
is($buf->get(50), 0, 'zero initialized');

# negative values
$buf->set(2, -123);
is($buf->get(2), -123, 'negative value');

# fill
$buf->fill(7);
is($buf->get(0), 7, 'fill elem 0');
is($buf->get(99), 7, 'fill elem 99');

# slice
$buf->set(0, 10);
$buf->set(1, 20);
$buf->set(2, 30);
my @vals = $buf->slice(0, 3);
is_deeply(\@vals, [10, 20, 30], 'slice');

# keyword slice
my @kvals = buf_i64_slice $buf, 0, 3;
is_deeply(\@kvals, [10, 20, 30], 'keyword slice');

# set_slice
ok($buf->set_slice(5, 100, 200, 300), 'set_slice');
is($buf->get(5), 100, 'set_slice elem 0');
is($buf->get(6), 200, 'set_slice elem 1');
is($buf->get(7), 300, 'set_slice elem 2');

# incr / decr
$buf->set(10, 0);
is($buf->incr(10), 1, 'incr');
is($buf->incr(10), 2, 'incr again');
is($buf->decr(10), 1, 'decr');

# add
is($buf->add(10, 10), 11, 'add');
is($buf->add(10, -5), 6, 'add negative');

# cas
ok($buf->cas(10, 6, 100), 'cas success');
is($buf->get(10), 100, 'cas value updated');
ok(!$buf->cas(10, 6, 200), 'cas failure (wrong expected)');
is($buf->get(10), 100, 'cas value unchanged');

# keyword counters
buf_i64_set $buf, 20, 0;
my $ki = buf_i64_incr $buf, 20;
is($ki, 1, 'kw incr');
my $ka = buf_i64_add $buf, 20, 5;
is($ka, 6, 'kw add');
my $kc = buf_i64_cas $buf, 20, 6, 42;
ok($kc, 'kw cas');

# multiprocess
$buf->set(30, 0);
my $pid = fork();
if ($pid == 0) {
    my $child = Data::Buffer::Shared::I64->new($path, 100);
    for (1..1000) { $child->incr(30) }
    exit 0;
}
for (1..1000) { $buf->incr(30) }
waitpid($pid, 0);
is($buf->get(30), 2000, 'multiprocess atomic incr');

# path
is($buf->path, $path, 'path');

# mmap_size
ok($buf->mmap_size > 0, 'mmap_size > 0');

# ptr / ptr_at
my $base = $buf->ptr;
ok($base > 0, 'ptr returns non-zero address');
my $p0 = $buf->ptr_at(0);
is($p0, $base, 'ptr_at(0) == ptr');
my $p1 = $buf->ptr_at(1);
is($p1, $base + 8, 'ptr_at(1) == ptr + elem_size');

# keyword ptr
my $kp = buf_i64_ptr $buf;
is($kp, $base, 'keyword ptr');
my $kpa = buf_i64_ptr_at $buf, 5;
is($kpa, $base + 40, 'keyword ptr_at');

# ptr_at out of bounds
eval { $buf->ptr_at(100) };
like($@, qr/out of bounds/, 'ptr_at out of bounds croaks');

done_testing;
