# $Id: _length.t,v 1.1 2006-02-20 12:36:01 jonasbn Exp $

use strict;
use Test::More tests => 2;
use Business::DK::PO;
use Test::Exception;

dies_ok {Business::DK::PO::_length("123", 1, 2)} 'assertion error';

dies_ok {Business::DK::PO::_length("12", 3, 4)} 'assertion error';
