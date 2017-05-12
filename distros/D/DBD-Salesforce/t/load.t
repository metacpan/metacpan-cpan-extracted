#!/usr/bin/perl
# vim: set ft=perl:

use DBI;
use Test::More;

plan tests => 6;

use_ok("Salesforce");
use_ok("DBD::Salesforce");
use_ok("DBD::Salesforce::db");
use_ok("DBD::Salesforce::dr");
use_ok("DBD::Salesforce::st");
use_ok("SQL::Dialects::Salesforce");
