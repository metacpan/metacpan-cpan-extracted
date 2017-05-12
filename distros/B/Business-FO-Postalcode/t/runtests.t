#!/usr/bin/env/perl -T

use strict;
use warnings;

use lib qw(t);

use Test::Class::Business::FO::Postalcode;
use Test::Class::Class::Business::FO::Postalcode;

Test::Class->runtests;