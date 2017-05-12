
# $Id: 00.load.t,v 1.2 2008-06-11 08:08:00 jonasbn Exp $

use strict;
use Test::More tests => 2;

use_ok( 'Business::DK::CVR' );
use_ok( 'Data::FormValidator::Constraints::Business::DK::CVR' );
