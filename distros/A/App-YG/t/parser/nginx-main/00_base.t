use strict;
use Test::More;

BEGIN {
    use_ok 'App::YG::Nginx::Main';
}

can_ok 'App::YG::Nginx::Main' => qw/parse labels/;

done_testing;