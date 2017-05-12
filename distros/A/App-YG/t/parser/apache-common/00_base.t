use strict;
use Test::More;

BEGIN {
    use_ok 'App::YG::Apache::Common';
}

can_ok 'App::YG::Apache::Common' => qw/parse labels/;

done_testing;