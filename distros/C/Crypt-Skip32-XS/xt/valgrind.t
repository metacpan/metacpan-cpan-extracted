use strict;
use warnings;
use Test::More;

eval "use Test::Valgrind";
if ($@) {
    plan skip_all => 'Test::Valgrind is not installed.';
}

leaky();

