#!/usr/bin/env perl

use Bio::GeneDesign;
use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '5.56';
my $GDV = "GD_List_Codon_Tables_$VERSION";

local $| = 1;

##Get Arguments
my %p = ();
GetOptions (
      'help'          => \$p{HELP},
      'rscu'          => \$p{RSCU},
      'codon'         => \$p{CODON}
);
pod2usage(-verbose=>99, -sections=>"DESCRIPTION|ARGUMENTS") if ($p{HELP});

my $GD = Bio::GeneDesign->new();
my $cp = $GD->codon_path();
print "\nGeneDesign's codon directory is $cp\n";
my ($rscuref, $codref) = $GD->parse_organisms();

my @rscuorgs = sort keys %{$rscuref};
my $rscustr = "\nRSCU tables in $cp\n\t";
$rscustr .= join qq{\n\t}, @rscuorgs;
$rscustr .= "\n";

my @codorgs = sort keys %{$codref};
my $codstr = "\nCodon Definition tables in $cp\n\t";
$codstr .= join qq{\n\t}, @codorgs;
$codstr .= "\n";

if ($p{RSCU} && ! $p{CODON})
{
  print $rscustr;
}
elsif ($p{CODON} && ! $p{RSCU})
{
  print $codstr;
}
else
{
  print $rscustr . $codstr;
}

exit;

__END__

=head1 NAME

  GD_List_Codon_Tables.pl

=head1 VERSION

  Version 5.56

=head1 DESCRIPTION

  Lists the codon_tables subdirectory from GeneDesign's configuration

=head1 USAGE

  List all RSCU and codon tables that are inside GeneDesign's configuration
        GD_List_Codon_Tables.pl

  List only RSCU tables that are inside GeneDesign's configuration
        GD_List_Codon_Tables.pl --rscu

  List only alternative codon tables that are inside GeneDesign's configuration
        GD_List_Codon_Tables.pl --codon

=head1 ARGUMENTS

Optional arguments:

  -r,   --rscu : Display rscu tables only
  -c,   --codon : Display codon tables only
  -h,   --help : Display this message

=cut