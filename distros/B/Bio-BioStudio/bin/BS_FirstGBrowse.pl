#!/usr/bin/env perl

use Bio::BioStudio;
use Getopt::Long;
use Pod::Usage;
use English qw(-no_match_vars);

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_FirstGBrowse_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'chromosome=s' => \$p{CHROMOSOME},
	'help'         => \$p{HELP}
);
pod2usage(-verbose=>99) if ($p{HELP});

################################################################################
############################### SANITY CHECKING ################################
################################################################################
my $BS = Bio::BioStudio->new();

$p{CHROMOSOME} = $p{CHROMOSOME} || 'Escherichia_coli_MG1655_chr01_0_00';

my $chr = $BS->set_chromosome(
  -chromosome => $p{CHROMOSOME},
  -gbrowse    => 1
);
$chr->db(1);

print "\nAdded $p{CHROMOSOME} to GBrowse\n";
exit;

__END__

=head1 NAME

  BS_FirstGBrowse.pl

=head1 VERSION

  Version 2.10

=head1 DESCRIPTION

  This utility adds a chromosome to GBrowse.
    
=head1 ARGUMENTS

Required arguments:

Optional arguments:

  -c,   --chromosome : A chromosome in the repository to add to GBrowse.
                       Defaults to Escherichia_coli_MG1655_chr01_0_00
  -h,   --help : Display this message

=cut
