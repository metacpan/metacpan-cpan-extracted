#!/usr/local/bin/perl -T

use strict;
use warnings;

use lib qw(t);

use Test::Class::Business::GL::Postalcode;
use Test::Class::Class::Business::GL::Postalcode;

Test::Class->runtests;