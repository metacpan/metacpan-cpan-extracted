# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-apacheSSI.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('CGI::apacheSSI') };

#########################
# Include the CGI::apacheSSI specific tests here.
#########################

