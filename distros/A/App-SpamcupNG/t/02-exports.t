use warnings;
use strict;
use Test::More;

BEGIN {
    use_ok( 'SpamcupNG', qw(read_config main_loop get_browser) );
}

done_testing;

# vim: filetype=perl
