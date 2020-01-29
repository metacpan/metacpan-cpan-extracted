#!/usr/bin/perl

use strict;
use warnings;

use Data::Validate::Chemistry qw( is_European_Community_number );
use Test::More tests => 1;

ok( is_European_Community_number( '200-003-9' ), '"200-003-9" is European Community number for dexamethasone' );
