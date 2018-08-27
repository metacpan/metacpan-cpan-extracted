#!/usr/bin/perl

use strict;

BEGIN {
  $|  = 1;
  $^W = 1;
}

use lib "t/lib";
use SQLeetTest qw/requires_sqleet_sqlite/;
use Test::More;
use DBD::SQLeet;

BEGIN {
  requires_sqleet_sqlite('3.10.0');
}

use Test::NoWarnings;

plan tests => 13;

ok !DBD::SQLeet::strlike("foo_bar", "FOO1BAR");
ok !DBD::SQLeet::strlike("foo_bar", "FOO_BAR");
ok DBD::SQLeet::strlike("foo\\_bar", "FOO1BAR", "\\");
ok !DBD::SQLeet::strlike("foo\\_bar", "FOO_BAR", "\\");
ok DBD::SQLeet::strlike("foo!_bar", "FOO1BAR", "!");
ok !DBD::SQLeet::strlike("foo!_bar", "FOO_BAR", "!");
ok !DBD::SQLeet::strlike("%foobar", "1FOOBAR");
ok !DBD::SQLeet::strlike("%foobar", "%FOOBAR");
ok DBD::SQLeet::strlike("\\%foobar", "1FOOBAR", "\\");
ok !DBD::SQLeet::strlike("\\%foobar", "%FOOBAR", "\\");
ok DBD::SQLeet::strlike("!%foobar", "1FOOBAR", "!");
ok !DBD::SQLeet::strlike("!%foobar", "%FOOBAR", "!");
