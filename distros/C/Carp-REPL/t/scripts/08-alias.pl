#!perl
use strict;
use warnings;
use Carp::REPL 'noprofile';

my $numerator = 10;
my $denominator = 0;

our $n = 100;
our $d = 0;

my %frac = (n => 1000, d => 0);
my %frac2 = (n => 10000, d => 0);

Carp::REPL::repl();

print "<" . $numerator / $denominator . ">\n";
print "<" . $n / $d . ">\n";
print "<" . $frac{n} / $frac{d} . ">\n";
print "<" . $frac2{n} / $frac2{d} . ">\n";
print "\n\$ ";
