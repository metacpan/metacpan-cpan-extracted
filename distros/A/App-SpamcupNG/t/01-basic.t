use warnings;
use strict;
use Test::More;

my $module = 'App::SpamcupNG';
require_ok($module);
can_ok( $module, qw(read_config main_loop get_browser) );

done_testing;

# vim: filetype=perl
