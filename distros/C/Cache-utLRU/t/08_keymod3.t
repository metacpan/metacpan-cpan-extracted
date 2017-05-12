use strict;
use warnings;
use Test::More;

use Devel::Peek;
use Cache::utLRU;

my $cache = Cache::utLRU->new();

# This is combination of 06_keymod.t and 07_keymod2.t using implicit SV mutation via a loop.

my $k;
while ($k = <DATA>) {
    chomp $k;
    # Dump($k);
    $cache->add($k, 1);
}

my $val = $cache->find("foo");
is $val, 1, "value found";

done_testing;
__DATA__
foo
bar
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
