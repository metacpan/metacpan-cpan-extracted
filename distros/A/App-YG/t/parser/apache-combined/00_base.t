use strict;
use Test::More;

BEGIN {
    use_ok 'App::YG::Apache::Combined';
}

can_ok 'App::YG::Apache::Combined' => qw/parse labels/;

done_testing;