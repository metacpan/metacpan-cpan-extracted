#!perl -w

use strict;
use Test qw(plan ok);

plan tests => 1;

use Data::Dump::Ruby qw(dump_ruby);

my %a = (a => 1, b => 2, c => 3);
$a{a} = \%a;
ok(dump_ruby(\%a), q((Proc.new {   a = { "a" => 'fix', "b" => 2, "c" => 3 }
  a["a"] = a
  a
 }).call))
