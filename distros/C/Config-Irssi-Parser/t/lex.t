#!/usr/bin/perl
# vim: set ft=perl:
use strict;
use warnings;
use Test::More;
use Fatal qw(:open :close);

plan tests => 2;
my $class = "Config::Irssi::Lexer";
use_ok($class);


my $fh;
open $fh, "t/config";
my $lexer = mklexer($fh);
isa_ok($lexer, 'CODE');

close $fh;
