#!/usr/bin/perl

use strict;
use warnings;

my $double  = "double quoted string";
my $single  = 'single quoted string';
my $q       = q<q{} quoted string>;
my $qq      = qq<qq{} quoted string>;
my $heredoc = <<'.';
heredoc string
   with two lines
.
