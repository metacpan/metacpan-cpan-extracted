# $Id: _calculate_sum.t,v 1.1 2006-02-20 12:36:01 jonasbn Exp $

use strict;
use Test::More tests => 1;
use Business::DK::PO;

is(43, Business::DK::PO::_calculate_sum("123456789"));
