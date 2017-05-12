#!/usr/bin/perl

use strict;
use warnings;

use FindBin::Real;

use HTML::TreeBuilder;

# --------------------

my($root)            = HTML::TreeBuilder -> new;
my($input_file_name) = FindBin::Real::Bin . '/../data/currency.html';
my($result)          = $root -> parse_file($input_file_name) || die "Can't parse: $input_file_name";
my(@node)            = $root -> look_down(_tag => 'select', name => 'from');
my(@option)          = $node[0] -> look_down(_tag => 'option');

my($s, @s);

my(%currency) = map{$s = ${$_ -> content_array_ref}[0]; @s = split(/\s\(/, $s); $s[1] =~ s/\)//; ($s[0] => $s[1])} @option;

$root -> delete;

my($output_file_name) = FindBin::Real::Bin . '/../data/currencies.txt';

open(OUT, "> $output_file_name") || die "Can't open(> $output_file_name): $!";
print OUT "# code, name\n";
print OUT map{"$currency{$_}, $_\n"} sort keys %currency;
close OUT;
