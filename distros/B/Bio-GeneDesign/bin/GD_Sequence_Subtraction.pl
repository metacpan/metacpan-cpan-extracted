#!/usr/bin/env perl

use Bio::GeneDesign;
use Getopt::Long;
use Pod::Usage;
use File::Basename;

use strict;
use warnings;

my $VERSION = '5.54';
my $GDV = "GD_Sequence_Subtraction_$VERSION";
my $GDS = "_SS";

local $| = 1;

##Get Arguments
my %p = ();
GetOptions (
      'input=s'       => \$p{INPUT},
      'enzymes=s'     => \$p{ENZYMES},
      'removes=s'     => \$p{SEQUENCES},
      'revcom'        => \$p{REVCOMP},
      'organism=s'    => \$p{ORGS},
      'rscu=s'        => \$p{FILES},
      'output=s'      => \$p{OUTPUT},
      'format=s'      => \$p{FORMAT},
      'split'         => \$p{SPLIT},
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

$p{FORMAT} = $p{FORMAT} || $suffix || "genbank";

$p{REVCOMP} = $p{REVCOMP} || 0;

#The output path must exist, and we'll need it to end with a slash
$p{OUTPUT} = $p{OUTPUT} || ".";
$p{OUTPUT} .= "/" if (substr($p{OUTPUT}, -1, 1) !~ /[\/]/);
die "\n GDERROR: $p{OUTPUT} does not exist.\n"
  if ($p{OUTPUT} && ! -e $p{OUTPUT});

#We sort out organisms and RSCU tables.
$p{FILES} = $p{FILES} || undef;
$p{ORGS} = $p{ORGS} || undef;
unless ($p{ORGS} || $p{FILES})
{
  warn "\n GDWARNING: no usable RSCU input was provided; codon replacements"
    . " will be subjective.\n";
  $p{ORGS} = "Unbiased";
}

#We must get a list of recognizeable enzymes or a set of forbidden sequences.
die "\n GDERROR: Neither a list of enzymes nor a file of sequences to be "
  . "removed were supplied.\n"
  if (! $p{ENZYMES} && ! $p{SEQUENCES});

################################################################################
################################# CONFIGURING ##################################
################################################################################
my @fileswritten;
my @seqstowrite;

$GD->set_restriction_enzymes();

#Set up removal information
my @TAROBJS = ();
if ($p{SEQUENCES})
{
  foreach my $remseq (split (",", $p{SEQUENCES}))
  {
    my ($siter, $sfilename, $ssuffix) = $GD->import_seqs($remseq);
    while ( my $obj = $siter->next_seq() )
    {
      push @TAROBJS, $obj;
    }
  }
}
if ($p{ENZYMES})
{
  foreach my $enz (split (",", $p{ENZYMES}))
  {
    if (exists $GD->enzyme_set->{$enz})
    {
      push @TAROBJS, $GD->enzyme_set->{$enz};
    }
    else
    {
      print "\n GDWARNING: Skipping $enz : not in enzyme set\n";
    }
  }
}

die "\n GDERROR: no removal input was provided.\n"
  unless (scalar(@TAROBJS));

my %works = ();
if ($p{ORGS})
{
  foreach my $org (split (",", $p{ORGS}))
  {
    $works{$org} = {on => $org, path => undef};
  }
}
if ($p{FILES})
{
  foreach my $file ( split ( ",", $p{FILES} ) )
  {
    $works{$file} = {on => basename($file), path => $file};
  }
}

################################################################################
############################ SEQUENCE  Subtraction #############################
################################################################################
while ( my $obj = $iterator->next_seq() )
{
  my $clone = $obj->clone;
  foreach my $work (keys %works)
  {
    print "Performing changes for organism " . $works{$work}->{on} . "...\n";
    my $olddesc = $obj->desc();
    $GD->set_organism(
        -organism_name => $works{$work}->{on},
        -rscu_path     => $works{$work}->{path});

    my $oldpep = $GD->translate(-sequence => $clone);
    my @minuslist = ();
    my @misslist = ();
    foreach my $tar (@TAROBJS)
    {
      my $id = $tar->id;
      my $revcom = exists $GD->enzyme_set->{$id} ?  1 : $p{REVCOMP};
      my $prepcount = $GD->positions(-sequence => $obj,
                                     -query => $tar,
                                     -reverse_complement => $revcom);
      my $precount = scalar(keys %$prepcount);
      unless ($precount)
      {
        #print "\t" . $obj->id . " has no occurences of $id\n";
        next;
      }
      $obj = $GD->subtract_sequence(
          -sequence  => $obj,
          -remove    => $tar
      );
      my $postcount = $GD->positions(-sequence => $obj,
                                     -query => $tar,
                                     -reverse_complement => $revcom);
      my $oops = scalar(keys %$postcount);
      my $s = $precount > 1 ? "s" : q{};
      if ($oops)
      {
        warn "\tGDWARNING: Failed to remove $oops of $precount instances of $id"
            . " from " . $obj->id . "\n";
        push @misslist, $id;
      }
      else
      {
        print  "\t$precount instance$s of $id removed from " . $obj->id . "\n";
        push @minuslist, $id;
      }
      my $newpep = $GD->translate(-sequence => $obj);
      if ( $newpep->seq ne $oldpep->seq)
      {
        warn "GDWARNING: The translation of " . $obj->id . " has changed!\n";
        $obj->desc($obj->desc . "[BADTRANS]");
      }
    }
    
    if (scalar @minuslist || scalar @misslist)
    {
      $obj->desc($olddesc . " subtracted with $works{$work}->{on} RSCU values");
    }
    if (scalar @minuslist)
    {
      my $minusstring = join ',', @minuslist; 
      $obj->desc($obj->desc . " [-$minusstring]");
    }
    if (scalar @misslist)
    {
      my $missstring = join ',', @misslist; 
      $obj->desc($obj->desc . " [~$missstring]");
    }

    if ($p{SPLIT})
    {
      push @fileswritten, $GD->export_seqs(
        -filepath   => $p{OUTPUT} . $obj->id . $GDS,
        -format     => $p{FORMAT},
        -sequences  => [$obj],
      );
    }
    else
    {
      push @seqstowrite, $obj;
    }
  }
}
if (scalar @seqstowrite)
{
  push @fileswritten, $GD->export_seqs(
    -filepath   => $p{OUTPUT} . $filename . $GDS,
    -format     => $p{FORMAT},
    -sequences  => \@seqstowrite,
  );
}

print "\n";
print "Wrote $_\n" foreach @fileswritten;
print "\n";
print $GD->attitude() . " brought to you by $GDV\n\n";

exit;

__END__

=head1 NAME

  GD_Sequence_Subtraction.pl

=head1 VERSION

  Version 5.54

=head1 DESCRIPTION

  Given at least one nucleotide sequence and at least one short nucleotide
  sequence, the Sequence_Subtraction script seeks to remove the short sequence
  without changing the first frame translation of the large nucleotide sequence.
  The short sequence can be a restriction enzyme recognition site, in which case
  both the sequence and its reverse complement will be removed.

  If an organism or RSCU file is provided, the script will take RSCU values into
  account when making changes.

  Output will be named according to the name of the input file, and will be
  tagged with the _SS suffix.

=head1 USAGE

  -e OR -s must be provided. If both are given both will be processed.

=head1 ARGUMENTS

Required arguments:

  -in,  --input : a file containing nucleotide sequences.
  -e,   --enzymes : a comma separated list of restriction enzymes that can be
    found in the enzyme file specified in the config directory. All restriction
    enzymes in the list will have their recognition sites removed from the input
    sequences.
  OR
  -rem,  --removes : a file containing short nucleotide sequences, or paths to
    several separated by commas. Any instances of the short sequences will be
    removed from the input sequences.

Optional arguments:

  -org,   --organism : an organism whose RSCU table can be found in the config
    directory, or several separated by commas. flat is an option.
  -rscu,  --rscu : path to an RSCU table generated by GD_Generate_RSCU_Table.pl,
    or several separated by commas.
  -rev, --revcom : Whether or not to remove the sequence in both orientations.
    Assumed 1 for enzymes and 0 for other sequences.
  -out, --output : path to an output directory
  -f,   --format : output format of sequences
  -s,   --split : output all sequences as separate files
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