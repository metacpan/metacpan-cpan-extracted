#!/usr/bin/perl -w

use strict;
use Parse::CPAN::Packages;

# must have downloaded
my $p = Parse::CPAN::Packages->new("/usr/local/minicpan/modules/02packages.details.txt.gz");

# either a filename as above or pass in the contents of the file

my $m = $p->package("Acme::Colour");

# $m is a Parse::CPAN::Packages::Package object
print $m->package, "\n";    # Acme::Colour
print $m->version, "\n";    # 1.00
