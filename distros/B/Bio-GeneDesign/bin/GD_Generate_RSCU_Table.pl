#!/usr/bin/env perl

use Bio::GeneDesign;
use Getopt::Long;
use Pod::Usage;
use File::Basename;

use strict;
use warnings;

my $VERSION = '5.56';
my $GDV = "GD_Generate_RSCU_Table_$VERSION";
my $GDS = ".rscu";

local $| = 1;

##Get Arguments
my %p = ();
GetOptions (
      'input=s'       => \$p{INPUT},
      'output=s'      => \$p{OUTPUT},
      'organism=s'    => \$p{ORG},
      'codontable=s'  => \$p{CODONPATH},
      'help'          => \$p{HELP}
);

################################################################################
################################ SANITY  CHECK #################################
################################################################################
pod2usage(-verbose=>99, -sections=>"NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE")
  if ($p{HELP});

my $GD = Bio::GeneDesign->new();

#The input file must exist and be a format we care to read.
die "\n GDERROR: You must supply an input file.\n"
  if (! $p{INPUT});
my ($iterator, $filename, $suffix) = $GD->import_seqs($p{INPUT});

#The output path must exist, and we'll need it to end with a slash
$p{OUTPUT} = $p{OUTPUT} || ".";
$p{OUTPUT} .= "/" if (substr($p{OUTPUT}, -1, 1) !~ /[\/]/);
die "\n GDERROR: $p{OUTPUT} does not exist.\n"
  if ($p{OUTPUT} && ! -e $p{OUTPUT});
my $outputpath = $p{OUTPUT} . $filename . $GDS;

#Organism, if defined, should exist - otherwise warn about standard tables
$p{CODONPATH} = $p{CODONPATH} || undef;
$p{ORG} = $p{ORG} || "Standard";
$GD->set_codontable(-organism_name => $p{ORG}, -table_path => $p{CODONPATH});

################################################################################
############################### RSCU  CRUNCHING ################################
################################################################################
my @seqobjs = ();
while ( my $obj = $iterator->next_seq() )
{
  my $seq = $obj->seq;
  ##REPLACE THIS WITH CODE THAT ACTUALLY EXTRACTS GENES
  if (length($seq) % 3)
  {
    warn "\nGDWARNING: ", $obj->id, " is the wrong length for a gene. " .
          "It will be skipped\n";
    next;
  }
  push @seqobjs, $obj;
}
my $comment = "RSCU values gathered from $filename ($GDV)";
my $string = $GD->generate_RSCU_file(
  -sequences => \@seqobjs,
  -comments  => [$comment]
);

open (my $OUT, '>', $outputpath ) || die "can't write to $outputpath, $!";
print $OUT $string;
close $OUT;

print "\n";
print "Wrote $outputpath\n";
print "\n";
print $GD->attitude() . " brought to you by $GDV\n\n";

exit;

__END__

=head1 NAME

  GD_Generate_RSCU_Table.pl

=head1 VERSION

  Version 5.56

=head1 DESCRIPTION

  Given at least one protein-coding gene as input, the Generate_RSCU_Table
  script generates a table of RSCU values that represents the bias in codon
  usage.

  Output will be named according to the name of the input file, and will be
  named  "inputfilename_GDRSCU.rscu".

=head1 ARGUMENTS

Required arguments:

  -i,   --input : a file containing nucleotide sequences.

Optional arguments:

  -out, --output : path to an output directory
  -org, --organism : an organism whose codon table can be found in the
      config directory, necessary if the organism being parsed doesn't use the
      standard codon table
      OR
  -c,   --codontable : path to a codon table; necessary if the organism being
      parsed doesn't use the standard codon table
  -h,   --help : Display this message.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Sarah Richardson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the GeneDesign developers may
not be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
