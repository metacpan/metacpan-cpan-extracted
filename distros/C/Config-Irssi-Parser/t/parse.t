#!/usr/bin/perl
# vim: set ft=perl:
use strict;
use warnings;
use Test::More;
use Fatal qw(:open :close);

plan tests => 6;
my $class = "Config::Irssi::Parser";
use_ok($class);
can_ok($class, "new", "parse");

my $parser = $class->new;
ok(defined $parser, "parser is defined");
ok($parser->isa($class), "Is subclass of $class");

my $fh;
open $fh, "t/config";
my $data;
ok(defined($data = $parser->parse($fh)), "Can parse t/config...");

close $fh;

is(ref($data), "HASH", "parsed structure is a hash");
