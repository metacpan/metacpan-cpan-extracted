#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 4;

use t::lib::helper;

t::lib::helper::compare( '  2006-Dec-08'          => '2006-12-08T00:00:00' );
t::lib::helper::compare( '2006-Dec-08  '          => '2006-12-08T00:00:00' );
t::lib::helper::compare( '  2006-Dec-08  '        => '2006-12-08T00:00:00' );
t::lib::helper::compare( 'January    8,    1999'  => '1999-01-08T00:00:00' );
