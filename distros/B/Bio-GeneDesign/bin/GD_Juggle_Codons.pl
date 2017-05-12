#!/usr/bin/env perl

use Bio::GeneDesign;
use Getopt::Long;
use File::Basename;
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '5.54';
my $GDV = "GD_Juggle_Codons_$VERSION";
my $GDS = "_CJ";

my %ALGNAME = (most_different_sequence => 1, balanced => 1,
  random => 1, high => 1, least_different_RSCU => 1);

local $| = 1;

##Get Arguments
my %p = ();
GetOptions (
      'input:s'     => \$p{INPUT},
      'output:s'    => \$p{OUTPUT},
      'format:s'    => \$p{FORMAT},
      'rscu:s'      => \$p{FILES},
      'organism:s'  => \$p{ORGS},
      'algorithm:s' => \$p{ALGS},
      'split'       => \$p{SPLIT},
      'string:s'    => \$p{STRING},
      'help'        => \$p{HELP}
);

################################################################################
################################ SANITY  CHECK #################################
################################################################################
pod2usage(-verbose=>99, -sections=>"NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE")
  if ($p{HELP});

my $GD = Bio::GeneDesign->new();

#The input file must exist and be a format we care to read.
die "\n GDERROR: You must supply an input.\n"
  if (! $p{INPUT} && ! $p{STRING});
  
die "\n GDERROR: Either a file or a string input, please.\n"
  if ($p{INPUT} && $p{STRING});
  
my ($iterator, $filename, $suffix) = (undef, undef, undef);

if ($p{INPUT})
{
  ($iterator, $filename, $suffix) = $GD->import_seqs($p{INPUT});
}
elsif ($p{STRING})
{
  ($iterator, $filename, $suffix) = $GD->import_seq_from_string($p{STRING});
}

$p{FORMAT} = $p{FORMAT} || $suffix || 'genbank';

#The output path must exist, and we'll need it to end with a slash
$p{OUTPUT} = $p{OUTPUT} || q{.};
$p{OUTPUT} = $GD->endslash($p{OUTPUT});
die "\n GDERROR: $p{OUTPUT} does not exist.\n"
  if ($p{OUTPUT} && ! -e $p{OUTPUT});

#We must get a list of organisms or a set of rscu files
die "\n GDERROR: Neither an organism nor an RSCU table were supplied.\n"
  if (! $p{ORGS} && ! $p{FILES});
$p{ORGS}       = $p{ORGS}   || q{};
$p{FILES}      = $p{FILES}  || q{};

$p{ALGS}       = $p{ALGS}   || "balanced";
#We must recognize all of the algorithm input
die "\n GDERROR: Unrecognized algorithm $_.\n"
  foreach (grep {! exists $ALGNAME{$_}} split(q{,}, $p{ALGS}));

################################################################################
################################# CONFIGURING ##################################
################################################################################
my @fileswritten;
my @seqstowrite;

my %works = ();
foreach my $org (split (q{,}, $p{ORGS}))
{
  $works{$org} = {on => $org, path => undef};
}
foreach my $file ( split ( q{,}, $p{FILES} ) )
{
  $works{$file} = {on => basename($file), path => $file};
}

################################################################################
############################### CODON  JUGGLING ################################
################################################################################
while ( my $obj = $iterator->next_seq() )
{
  foreach my $work (keys %works)
  {
    $GD->set_organism(
        -organism_name => $works{$work}->{on},
        -rscu_path     => $works{$work}->{path}
    );
    foreach my $alg (split(q{,}, $p{ALGS}))
    {
      my $newobj = $GD->codon_juggle(
          -sequence  => $obj,
          -algorithm => $alg
      );
      if ($p{SPLIT})
      {
        push @fileswritten, $GD->export_seqs(
          -filepath  => $p{OUTPUT} . $newobj->id . $GDS,
          -sequences => [$newobj],
          -format    => $p{FORMAT},
        );
      }
      else
      {
        push @seqstowrite, $newobj;
      }
    }
  }
}
if ($p{STRING})
{
  if (scalar @seqstowrite)
  {
    print $seqstowrite[0]->seq, "\n";
  }
  else
  {
    print "0\n";
  }
}
elsif ($p{INPUT})
{
  push @fileswritten, $GD->export_seqs(
    -filepath  => $p{OUTPUT} . $filename . $GDS,
    -sequences => \@seqstowrite,
    -format    => $p{FORMAT},
  );

  print "\n";
  print "Wrote $_\n" foreach @fileswritten;
  print "\n";
  print $GD->attitude() . " brought to you by $GDV\n\n";
}

exit;

__END__

=head1 NAME

  GD_Juggle_Codons.pl

=head1 VERSION

  Version 5.54

=head1 DESCRIPTION

  Given at least one protein-coding gene as input, the Juggle_Codons script can
  use several algorithms to modify the sequence without altering its
  translation. It is thus possible to generate a sequence that is optimized for
  expression, as different as possible from the original sequence, or some
  combination of the two.

  If no algorithm is specified, the balanced algorithm will be used. These are
  the algorithms provided by default with GeneDesign; you can make your own; see
  developer docs.

  Output will be named according to the name of the input file, and will be
  tagged with _CJ.

  Algorithms:
    high: The high algorithm replaces every codon in the input sequence with
        the most translationally optimal codon as specified by the input RSCU
        tables or known RSCU tables (if organism is specified). If the codon is
        already the ideal codon it is left alone.
    balanced: The balanced algorithm uses the rscu data to determine a
         likelihood of codon replacement.
    most_different_sequence: The most different sequence algorithm attempts to
        change as many bases as possible within the codon, preferring
        transversions over transitions.
    least_different_RSCU: The least different RSCU algorithm attempts to replace
        as many codons as possible while minimizing disruption of the original
        average RSCU value for the sequence. It will not make a replacement if
        the absolute change in RSCU value is greater than 1.
    random: The random algorithm makes random replacements.

=head1 USAGE

  -r OR -org must be provided. If both are given the table will be treated as
      another organism, named after the table's filename.

  Generate high and most different sequences given the yeast rscu table
    ./GD_Juggle_Codons.pl -i sequences.FASTA -org yeast\
                                                 -a most_different_sequence,high

  Use my rscu table to generate balanced sequences
    ./GD_Juggle_Codons.pl -i seqs.FASTA -r /my/dir/myrscu.rscu -a balanced

  Use my rscu table to pipeline balanced sequences
    ./GD_Juggle_Codons.pl -st ATCGATCCC -r /my/dir/myrscu.rscu -a balanced

=head1 ARGUMENTS

Required arguments:

  -org, --organism : an organism whose RSCU table can be found in the config
      directory, or several separated by commas
    AND/OR
  -r,   --rscu : path to an RSCU table generated by GD_Generate_RSCU_Table.pl

Optional arguments:

  -a,   --algorithm : which algorithms to use (see above), comma separated
          defaults to balanced
  -i,   --input : a file containing nucleotide sequences
  -st.  --string : a string containing DNA only - the program will return a
          DNA only string. this is intended for pipelining.
  -out, --output : path to an output directory
  -f,   --format : default genbank
  -sp,  --split : output all sequences as separate files
  -h,   --help : Display this message

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, GeneDesign developers
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
