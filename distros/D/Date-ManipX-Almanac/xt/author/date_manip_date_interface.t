package main;

use 5.010;

use strict;
use warnings;

use Date::Manip::Date;
use Date::ManipX::Almanac::Date;
use Test2::V0;

use lib qw{ tools };
BEGIN {
    local $@ = undef;
    eval {
	require My::Symdump;
	1;
    } or plan skip_all => 'Cannot load My::Symdump';
}

is [ sort
    Date::ManipX::Almanac::Date->__date_manip_date_public_interface() ],
    [ My::Symdump->dmd_public_interface() ],
    'All Date::Manip::Date public methods are accounted for';

done_testing;

1;

# ex: set textwidth=72 :
