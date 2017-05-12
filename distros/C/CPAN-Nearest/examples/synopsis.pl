#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use CPAN::Nearest 'search';
my $mod = 'Lingua::Stop::Wars';
my $pfile = "$ENV{HOME}/.cpan/sources/modules/02packages.details.txt.gz";
print "Nearest to $mod in $pfile is '", search ($pfile, $mod), "'.\n";

