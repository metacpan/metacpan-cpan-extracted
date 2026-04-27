use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::Buffer::Shared::Str;

my $path = tmpnam();
END { unlink $path if $path && -f $path }

my $buf = Data::Buffer::Shared::Str->new($path, 20, 16);
isa_ok($buf, 'Data::Buffer::Shared::Str');

is($buf->capacity, 20, 'capacity');
is($buf->elem_size, 16, 'elem_size');

# set / get
ok($buf->set(0, "hello"), 'set');
is($buf->get(0), "hello", 'get');

# empty string
ok($buf->set(1, ""), 'set empty');
is($buf->get(1), "", 'get empty');

# max length string
my $max = "x" x 16;
ok($buf->set(2, $max), 'set max length');
is($buf->get(2), $max, 'get max length');

# truncation (longer than elem_size)
ok($buf->set(3, "x" x 20), 'set truncated');
is($buf->get(3), "x" x 16, 'get truncated');

# fill
$buf->fill("abc");
is($buf->get(0), "abc", 'fill[0]');
is($buf->get(19), "abc", 'fill[19]');

# slice
$buf->set(0, "aaa");
$buf->set(1, "bbb");
$buf->set(2, "ccc");
my @vals = $buf->slice(0, 3);
is_deeply(\@vals, ["aaa", "bbb", "ccc"], 'slice');

# set_slice
ok($buf->set_slice(5, "xx", "yy", "zz"), 'set_slice');
is($buf->get(5), "xx", 'set_slice[0]');
is($buf->get(6), "yy", 'set_slice[1]');
is($buf->get(7), "zz", 'set_slice[2]');

# new_memfd + new_from_fd round-trip (Str variant requires max_len arg)
{
    my $a = Data::Buffer::Shared::Str->new_memfd("strfd", 10, 16);
    $a->set(0, "hello");
    my $fd = $a->memfd;
    ok defined $fd && $fd >= 0, 'memfd returned';
    my $b = Data::Buffer::Shared::Str->new_from_fd($fd, 16);
    is $b->get(0), "hello", 'new_from_fd shares state';
    $b->set(1, "world");
    is $a->get(1), "world", 'reverse view';
}

done_testing;
