#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/../t";

use Test::Class::Date::Holidays::Local;
use Test::Class::Date::Holidays::Adapter;
use Test::Class::Date::Holidays;

use Test::Class::Date::Holidays::Produceral;
use Test::Class::Date::Holidays::Supered;
use Test::Class::Date::Holidays::Abstracted;
use Test::Class::Date::Holidays::Polymorphic;
use Test::Class::Date::Holidays::Nonpolymorphic;

Test::Class->runtests();
