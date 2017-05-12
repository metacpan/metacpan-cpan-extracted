#! perl

#
# 03-env-bool.t
#
# Tests for the 'bool' constant type, where values 
# are forced to true/false values
#

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    $ENV{'FALSE'}        = 0;
    $ENV{'TRUE'}         = 1;
    $ENV{'STRING_FALSE'} = 'FALSE';
    $ENV{'STRING_TRUE'}  = 'TRUE';
}

use Constant::FromGlobal { bool => 1, env => 1 },
                         qw/ FALSE TRUE STRING_FALSE STRING_TRUE /;

ok(!FALSE,       "FALSE should be set to a false value");
ok(TRUE,         "TRUE should be set to a true value");
ok(STRING_FALSE, "'FALSE' should be set to a true value");
ok(STRING_TRUE,  "'TRUE' should be set to a true value");

done_testing;
