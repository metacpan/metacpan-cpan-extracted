#!perl
#
# test that printer instances do not persist across requests
#

use strict;
use Test::More tests => 1;
use Apache::TestRequest 'GET_BODY';

my $printer_a = GET_BODY "/TestApache__Singleton__Request__printer_instance";
my $printer_b = GET_BODY "/TestApache__Singleton__Request__printer_instance";

isnt $printer_a, $printer_b, 'not same instance';
