#!/usr/bin/perl
# vim: set ft=perl:

use DBI;
use Test::More;

plan tests => 5;

use_ok("DBD::Google");
use_ok("DBD::Google::db");
use_ok("DBD::Google::dr");
use_ok("DBD::Google::parser");
use_ok("DBD::Google::st");
