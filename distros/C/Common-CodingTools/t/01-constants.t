#!perl -T

use 5.008;
use strict;
no strict 'subs'; # Constants throw the off.
use warnings FATAL => 'all';

use Test::More tests => 24;

#   ___                          _ _ ___         _ _          _____         _     
#  / __|___ _ __  _ __  ___ _ _ (_|_) __|___  __| (_)_ _  __ |_   _|__  ___| |___ 
# | (__/ _ \ '  \| '  \/ _ \ ' \ _ | (__/ _ \/ _` | | ' \/ _` || |/ _ \/ _ \ (_-< 
#  \___\___/_|_|_|_|_|_\___/_||_(_|_)___\___/\__,_|_|_||_\__, ||_|\___/\___/_/__/ 
#                                                        |___/
#  Constants Tests

BEGIN {
    use_ok('Common::CodingTools', qw( :constants )) || BAIL_OUT("Bail out! Can't load Common::CodingTools qw(:constants)");
}

ok(TRUE       == 1, ' TRUE       = ' . TRUE);
ok(FALSE      == 0, ' FALSE      = ' . FALSE);
ok(ON         == 1, ' ON         = ' . ON);
ok(OFF        == 0, ' OFF        = ' . OFF);
ok(ACTIVE     == 1, ' ACTIVE     = ' . ACTIVE);
ok(INACTIVE   == 0, ' INACTIVE   = ' . INACTIVE);
ok(HEALTHY    == 1, ' HEALTHY    = ' . HEALTHY);
ok(UNHEALTHY  == 0, ' UNHEALTHY  = ' . UNHEALTHY);
ok(EXPIRED    == 1, 'EXPIRED    = ' . EXPIRED);
ok(NOTEXPIRED == 0, 'NOTEXPIRED = ' . NOTEXPIRED);
ok(CLEAN      == 1, 'CLEAN      = ' . CLEAN);
ok(DIRTY      == 0, 'DIRTY      = ' . DIRTY);
ok(HAPPY      == 1, 'HAPPY      = ' . HAPPY);
ok(UNHAPPY    == 0, 'UNHAPPY    = ' . UNHAPPY);
ok(SAD        == 0, 'SAD        = ' . SAD);
ok(ANGRY      == 0, 'ANGRY      = ' . ANGRY);
ok(SUCCESS    == 1, 'SUCCESS    = ' . SUCCESS);
ok(SUCCESSFUL == 1, 'SUCCESSFUL = ' . SUCCESSFUL);
ok(SUCCEEDED  == 1, 'SUCCEEDED  = ' . SUCCEEDED);
ok(FAILURE    == 0, 'FAILURE    = ' . FAILURE);
ok(FAILED     == 0, 'FAILED     = ' . FAILED);
ok(FAIL       == 0, 'FAIL       = ' . FAIL);
ok((4 * atan2(1, 1)) == PI, 'PI         = ' . PI);
