#!/usr/bin/perl

# Load testing for Data::Vitals

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;

# Does the module load
use_ok('Data::Vitals'               );
use_ok('Data::Vitals::Util'         );
use_ok('Data::Vitals::Height'       );
use_ok('Data::Vitals::Circumference');
use_ok('Data::Vitals::Hips'         );
use_ok('Data::Vitals::Waist'        );
use_ok('Data::Vitals::Frame'        );
use_ok('Data::Vitals::Chest'        );
use_ok('Data::Vitals::Underarm'     );
