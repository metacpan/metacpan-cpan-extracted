use strict;
use Test::More;

BEGIN {
    use_ok 'App::YG::Apache::Error';
}

can_ok 'App::YG::Apache::Error' => qw/parse labels/;

done_testing;