#!/usr/bin/perl -T

use strict;
use warnings;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	plan ('tests' => 4);
}

use Data::SimplePath 'AUTO_ARRAY'   => 0,      # defaults to true
                      'REPLACE_LEAF' => 0,      # defaults to true
		      'SEPARATOR'    => '|';    # defaults to '/'

# check if the private method _global returns the correct values (there is no other way to access
# the config variables):
is ( Data::SimplePath::_global ('AUTO_ARRAY'  ),   0, 'AUTO_ARRAY set to 0'   );
is ( Data::SimplePath::_global ('REPLACE_LEAF'),   0, 'REPLACE_LEAF set to 0' );
is ( Data::SimplePath::_global ('SEPARATOR'   ), '|', 'SEPARATOR set to |'    );

# note: tests of the _global method can be found in 06-config.t!
