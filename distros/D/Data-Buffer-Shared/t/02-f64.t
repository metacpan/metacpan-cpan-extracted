use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::Buffer::Shared::F64;

my $path = tmpnam();
END { unlink $path if $path && -f $path }

my $buf = Data::Buffer::Shared::F64->new($path, 50);
isa_ok($buf, 'Data::Buffer::Shared::F64');

is($buf->capacity, 50, 'capacity');
is($buf->elem_size, 8, 'elem_size');

# set / get
ok($buf->set(0, 3.14), 'set');
ok(abs($buf->get(0) - 3.14) < 1e-10, 'get');

# keyword API
buf_f64_set $buf, 1, 2.718;
my $kv = buf_f64_get $buf, 1;
ok(abs($kv - 2.718) < 1e-10, 'keyword get/set');

# fill
$buf->fill(1.5);
ok(abs($buf->get(49) - 1.5) < 1e-10, 'fill');

# slice
$buf->set(0, 1.0);
$buf->set(1, 2.0);
$buf->set(2, 3.0);
my @vals = $buf->slice(0, 3);
ok(abs($vals[0] - 1.0) < 1e-10, 'slice[0]');
ok(abs($vals[1] - 2.0) < 1e-10, 'slice[1]');
ok(abs($vals[2] - 3.0) < 1e-10, 'slice[2]');

# set_slice
ok($buf->set_slice(5, 10.5, 20.5, 30.5), 'set_slice');
ok(abs($buf->get(5) - 10.5) < 1e-10, 'set_slice elem 0');
ok(abs($buf->get(7) - 30.5) < 1e-10, 'set_slice elem 2');

done_testing;
