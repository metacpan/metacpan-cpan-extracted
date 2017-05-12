#!/usr/bin/perl -w

use strict;

use Test::More tests => 2;

use_ok('Class::DBI::Loader::Informix','Class::DBI::Loader::Informix loads');
use_ok('Class::DBI::Informix','Class::DBI::Informix loads');
