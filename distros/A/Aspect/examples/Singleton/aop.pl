#!/usr/bin/perl

use strict;
use warnings;
use Aspect;

aspect Singleton => 'Printer::new';

my $printer1 = Printer->new;
my $printer2 = Printer->new;
print 'using new(): '. ($printer1 eq $printer2? '': 'not '). "equal\n";

# -----------------------------------------------------------------------------

package Printer;

sub new { bless {}, shift }

