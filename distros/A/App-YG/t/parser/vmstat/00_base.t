use strict;
use Test::More;

BEGIN {
    use_ok 'App::YG::Vmstat';
}

can_ok 'App::YG::Vmstat' => qw/parse labels/;

done_testing;
