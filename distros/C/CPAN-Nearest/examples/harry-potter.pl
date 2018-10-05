#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use CPAN::Nearest 'search';
my $file = "$ENV{HOME}/.cpan/sources/modules/02packages.details.txt.gz";
my $close_name = search ($file, 'Harry::Potter');
print "$close_name\n";
