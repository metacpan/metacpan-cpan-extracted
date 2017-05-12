#!/usr/bin/perl

use strict;
use warnings;

my $printer1 = Printer->new;
my $printer2 = Printer->new;
print 'using new(): '. ($printer1 eq $printer2? '': 'not '). "equal\n";

my $printer3 = Printer->instance;
my $printer4 = Printer->instance;
print 'using instance(): '. ($printer3 eq $printer4? '': 'not '). "equal\n";

# -----------------------------------------------------------------------------

package Printer;

my $Instance;

sub instance { $Instance ||= Printer->new }

sub new { bless {}, shift }

