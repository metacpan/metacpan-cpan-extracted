#!/usr/local/bin/perl -T

# $Id$

# $HeadURL$

use strict;
use warnings;

use lib qw(t);

use Test::Class::Business::DK::Postalcode;
use Test::Class::Data::FormValidator::Constraints::Business::DK::Postalcode;


Test::Class->runtests;