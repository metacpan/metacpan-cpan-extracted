#!perl
#
# test that printer instances persist across requests
#

use strict;
use Test::More tests => 1;
use Apache::TestRequest 'GET_BODY';

my $printer_a = GET_BODY "/TestApache__Singleton__Process__printer_instance";
my $printer_b = GET_BODY "/TestApache__Singleton__Process__printer_instance";

is $printer_a, $printer_b, 'printers are same instance';
