# $Id: _argument.t,v 1.1 2006-02-20 12:36:01 jonasbn Exp $

use strict;
use Test::More qw(no_plan);
use Business::DK::PO;
use Test::Exception;

dies_ok {Business::DK::PO::_argument()} 'assertion error';

dies_ok {Business::DK::PO::_argument(1)} 'assertion error';

dies_ok {Business::DK::PO::_argument(1, 2)} 'assertion error';