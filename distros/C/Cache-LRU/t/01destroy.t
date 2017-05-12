use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Cache::LRU');
};

my $cache = Cache::LRU->new(
    size => 3,
);

$cache->set(a => Foo->new());
is $Foo::cnt, 1;
$cache->set(a => 2);
is $Foo::cnt, 0;

$cache->set(b => Foo->new());
is $Foo::cnt, 1;
$cache->remove('b');
is $Foo::cnt, 0;

done_testing;

package Foo;

our $cnt = 0;

sub new {
    my $klass = shift;
    $cnt++;
    bless {}, $klass;
}

sub DESTROY {
    --$cnt;
}
