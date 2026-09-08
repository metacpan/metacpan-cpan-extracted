use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;
use Data::HashMap::Shared::SI;
use Data::HashMap::Shared::SI16;
use Data::HashMap::Shared::SI32;
use Data::HashMap::Shared::IS;
use Data::HashMap::Shared::I16S;
use Data::HashMap::Shared::I32S;

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, "$_[0].shm") }

# $1 is a magical scalar: its buffer holds whatever was LAST fetched from it,
# and only get-magic refreshes it from the current match.  Fetch "stale" from
# it, then match "hello" without fetching, so a key read with SvPV_nomg sees
# "stale" while SvPV sees "hello".
sub prime { my $x; "stale" =~ /(\w+)/ and $x = "$1"; die unless $x eq 'stale'; return }
sub prime_num { my $n; "7" =~ /(\d+)/ and $n = 0 + $1; die unless $n == 7; return }

for my $class (qw(SS SI SI16 SI32)) {
    my $map = "Data::HashMap::Shared::$class"->new(path("k_$class"), 100);
    my $v = $class eq 'SS' ? 'val' : 7;

    prime(); "hello" =~ /(\w+)/ or die;
    ok $map->put($1, $v), "$class: put(\$1)";
    is $map->get('hello'), $v, "$class: stored under the current capture";
    ok !$map->exists('stale'), "$class: nothing stored under the stale buffer";

    prime(); "hello" =~ /(\w+)/ or die;
    is $map->get($1), $v, "$class: get(\$1) reads the current capture";
    prime(); "hello" =~ /(\w+)/ or die;
    ok $map->exists($1), "$class: exists(\$1)";
    prime(); "hello" =~ /(\w+)/ or die;
    my ($mv) = $map->get_multi($1);
    is $mv, $v, "$class: get_multi(\$1)";
    prime(); "hello" =~ /(\w+)/ or die;
    ok $map->remove($1), "$class: remove(\$1) removes the current capture";
    ok !$map->exists('hello'), "$class: ... and it is gone";

    prime(); "hello" =~ /(\w+)/ or die;
    is $map->set_multi($1, $v), 1, "$class: set_multi(\$1)";
    is $map->get('hello'), $v, "$class: set_multi stored under the current capture";
    prime(); "hello" =~ /(\w+)/ or die;
    is $map->remove_multi($1), 1, "$class: remove_multi(\$1)";
    is $map->size, 0, "$class: map empty again";
}

for my $class (qw(SS IS I16S I32S)) {
    my $map = "Data::HashMap::Shared::$class"->new(path("v_$class"), 100);
    my $k = $class eq 'SS' ? 'k' : 1;
    prime(); "hello" =~ /(\w+)/ or die;
    ok $map->put($k, $1), "$class: put(k, \$1)";
    is $map->get($k), 'hello', "$class: value is the current capture";
    my $k2 = $class eq 'SS' ? 'k2' : 2;   # a key put() above did not touch
    prime(); "hello" =~ /(\w+)/ or die;
    is $map->set_multi($k2, $1), 1, "$class: set_multi(k2, \$1)";
    is $map->get($k2), 'hello', "$class: set_multi value is the current capture";
}

# Integer keys and values reach the XS through SvIV, which is as magic-aware as
# SvPV -- and as easy to write as SvIV_nomg.  The stale-buffer trap is the same.
{
    my $map = Data::HashMap::Shared::II->new(path('num'), 100);
    prime_num();                            # buffer now holds 7
    "42" =~ /(\d+)/ or die;                 # match 42 without fetching
    ok $map->put($1, 420), 'II: put(\$1) with a numeric capture';
    is $map->get(42), 420, 'II: stored under the current numeric capture';
    ok !$map->exists(7), 'II: nothing stored under the stale numeric buffer';
    prime_num();
    "42" =~ /(\d+)/ or die;
    is $map->get($1), 420, 'II: get(\$1) reads the current numeric capture';
}

done_testing;
