use warnings;
use strict;
use Test::More;

BEGIN {
    use_ok( 'App::SpamcupNG', qw(read_config main_loop) );
}

done_testing;

# vim: filetype=perl
