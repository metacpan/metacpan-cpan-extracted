#!/usr/bin/env perl

use Bio::BioStudio;
use Bio::GeneDesign;
use URI::Escape;
use English qw(-no_match_vars);
use Text::Wrap qw($columns &wrap);
use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_AddFromGenbank_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
      'SPECIES=s'       => \$p{SPECIES},
      'PATH_TO_REPO=s'  => \$p{PATH},
      'INPUT=s'         => \$p{INPUT},
			'help'            => \$p{HELP}
);
if ($p{HELP})
{
  pod2usage(
    -verbose=>99,
    -sections=>"NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE"
  );
}

################################################################################
################################# SANITY CHECK #################################
################################################################################
my $GD = Bio::GeneDesign->new();

#The input file must exist and be a format we care to read.
die "\nBSERROR: You must supply an input file.\n" unless (defined $p{INPUT});
my ($iterator, $filename, $suffix) = $GD->import_seqs($p{INPUT});

my $BS = $p{PATH}
  ? Bio::BioStudio->new(-repo => $p{PATH})
  : Bio::BioStudio->new();
my $repopath = $BS->path_to_repo();

die "\nBSERROR: No species name was given" unless (defined $p{SPECIES});
my %slist = $BS->species_list();
if (exists $slist{$p{SPECIES}})
{
  die "\nBSERROR: $p{SPECIES} already exists in the repo at $repopath... "
   . "Manual intervention required.\n";
}

################################################################################
################################# CONFIGURING ##################################
################################################################################
my $name = $p{SPECIES};
my $chrcount = 1;
my $src = 'genbank';

#this should be replaced with the actual count of chromosomes to be imported
my $objcount = 2;
my $thick = $objcount < 2 ? 2 : $objcount;

while (my $obj = $iterator->next_seq)
{
  my %feattypecount = ();
  my $id = 'chr' . $GD->pad($chrcount, $thick, '0');
  $chrcount++;
  print "working on $id\n";
  my %loci = ();
  my @featlines;
  my @gfffeats;
  my @featlist = $obj->get_SeqFeatures;
  foreach my $feat (@featlist)
  {
    $feattypecount{$feat->primary_tag}++;
    my $lid = q{};
    if ($feat->has_tag('locus_tag'))
    {
      $lid = join(q{}, $feat->get_tag_values('locus_tag'));
      push @{$loci{$lid}}, $feat;
    }
    elsif ($feat->primary_tag eq 'source')
    {
      my $cfeat = make_feature($id, $src, $feat);
      $cfeat->{ID} = $id;
      $cfeat->{type} = 'chromosome';
      my @tags = $feat->get_all_tags();
      my $atts;
      foreach my $tag (@tags)
      {
        push @{$atts->{$tag}}, $feat->get_tag_values($tag);
      }
      $cfeat->{atts} = $atts;
      push @gfffeats, $cfeat;
    }
    else
    {
      my $nfeat = make_feature($id, $src, $feat);
      my $fid = $feat->has_tag('name')
        ? join(q{}, $feat->get_tag_values('name'))
        : $feat->has_tag('standard_name')
          ? join(q{}, $feat->get_tag_values('standard_name'))
          : $feat->primary_tag .q{_} . $feattypecount{$feat->primary_tag};

      $nfeat->{ID} = $fid;
      $nfeat->{type} = $feat->primary_tag;
      my @tags = $feat->get_all_tags();
      my $atts;
      foreach my $tag (@tags)
      {
        push @{$atts->{$tag}}, $feat->get_tag_values($tag);
      }
      $nfeat->{atts} = $atts;
      push @gfffeats, $nfeat;
    }
  }
  foreach my $lid (sort keys %loci)
  {
    my @lfeats = @{$loci{$lid}};
    my @genes = grep {$_->primary_tag eq 'gene'} @lfeats;
    my $gcount = scalar @genes;
    if ($gcount == 1)
    {
      my $gene = $genes[0];
      my @CDSes = grep {$_->primary_tag eq 'CDS'} @lfeats;
      my @other = grep {$_->primary_tag ne 'gene' && $_->primary_tag ne 'CDS'} @lfeats;
      my $gfeat = make_feature($id, $src, $gene);
      $gfeat->{ID} = $lid;
      my @gtags = grep {$_ ne 'locus_tag'} $gene->get_all_tags();
      my $atts;
      my @children;
      foreach my $gtag (@gtags)
      {
        push @{$atts->{$gtag}}, $gene->get_tag_values($gtag);
      }
      my %ctypehsh = ();
      foreach my $child (@CDSes)
      {
        my @ctags = grep { $_ ne 'locus_tag'
                        && $_ ne 'translation'
                        && $_ ne 'transl_table'
                        && $_ ne 'codon_start'
        } $child->get_all_tags();
        foreach my $ctag (@ctags)
        {
          if (! exists $atts->{$ctag})
          {
            push @{$atts->{$ctag}}, $child->get_tag_values($ctag);
          }
        }
        my $cfeat = make_feature($id, $src, $child);
        $cfeat->{Parent} = $lid;
        my $type = $child->primary_tag();
        $ctypehsh{$type}++;
        $cfeat->{ID} = $lid . q{_} . $type . "_" . $ctypehsh{$type};
        push @children, $cfeat;
      }
      foreach my $child (@other)
      {
        my @ctags = $child->get_all_tags();
        my $catts;
        foreach my $ctag (@ctags)
        {
          push @{$catts->{$ctag}}, $child->get_tag_values($ctag);
        }
        my $cfeat = make_feature($id, $src, $child);
        $cfeat->{Parent} = $lid;
        my $type = $child->primary_tag();
        $ctypehsh{$type}++;
        $cfeat->{ID} = $lid . q{_} . $type . "_" . $ctypehsh{$type};
        $cfeat->{atts} = $catts;
        push @children, $cfeat;
      }
      $gfeat->{atts} = $atts;
      push @gfffeats, $gfeat;
      push @gfffeats, @children;
    }
    elsif ($gcount > 1)
    {
      die 'Too many genes at locus ' . $lid;
    }
    else
    {
      print "nothing to do at $lid yet\n";
    }
  }
  my $rpath = $BS->prepare_repository($name, $id);
  my $cname = $name . q{_} . $id . q{_0_00.gff};
  my $path = $rpath . $cname;
  my $seqlen = length $obj->seq;
  if ($seqlen == 0)
  {
    print "\tNO SEQUENCE IN GENBANK FILE!\n";
  }
  open (my $GFF, '>', $path) || die "can't write $path, $OS_ERROR\n";
  print $GFF "##gff-version 3\n#\n";
  foreach my $feat (sort {$a->{start} <=> $b->{start}} @gfffeats)
  {
    print $GFF gff3_string($feat), "\n";
  }
  print $GFF "##FASTA\n";
  $columns = 81;
  print $GFF q{>} . $id . "\n";
  print $GFF wrap(q{}, q{}, $obj->seq), "\n";
  close $GFF;
  print "Wrote $cname to $path\n";
}


print "\n\n";

exit;


sub make_feature
{
  my ($id, $source, $feat) = @_;
  my $hsh = {};
  $hsh->{seq_id} = $id;
  $hsh->{source} = $source;
  $hsh->{start} = $feat->start();
  $hsh->{end} = $feat->end();
  $hsh->{type} = $feat->primary_tag();
  $hsh->{strand} = $feat->strand();
  $hsh->{phase} = $feat->frame();
  $hsh->{score} = $feat->score();
  return $hsh;
}

sub gff3_string
{
  my ($hsh) = @_;
  my $seq_id = $hsh->{seq_id};
  my $source = $hsh->{source};
  my $type   = $hsh->{type};
  my $start  = $hsh->{start};
  my $end    = $hsh->{end};

  my $score  = $hsh->{score};
  $score = $score ? $score  : q{.};

  my $strand = $hsh->{strand};
  $strand = $strand == -1 ? q{-} : $strand == 1  ? q{+} : q{.};

  my $phase  = $hsh->{phase};
  $phase = $phase && ($phase == 1 || $phase == 2 || $phase == 0) ? $phase : q{.};

  my $str = "$seq_id\t$source\t$type\t$start\t$end\t$score\t$strand\t$phase\t";


  $str .= 'ID=' . $hsh->{ID} . q{;};
  $str .= 'Name=' . $hsh->{ID} . q{;};

  if (exists $hsh->{Parent})
  {
    $str .= 'Parent=' . $hsh->{Parent} . q{;};
  }
  my $atts = $hsh->{atts};

  foreach my $tag (sort{$a cmp $b} keys %{$atts})
  {
    next if ($tag eq 'load_id' || $tag eq 'parent_id' || $tag eq 'display_name');
    my @vals = @{$atts->{$tag}};
    if (scalar(@vals))
    {
      my $attstr = join(q{,}, @vals);
      $attstr =~ s{\h+}{ }g;
      $attstr =~ s{\;}{\,}g;
      if ($tag eq 'Note')
      {
        $str .= "$tag=" . uri_escape($attstr, q{^\s^\d^\w^\-^\.^\_^\,^\(^\)}) . q{;};
      }
      else
      {
        $str .= "$tag=" . $attstr . q{;};
      }
    }
  }
  return $str;
}

__END__

=head1 NAME

  BS_AddFromGenbank.pl

=head1 VERSION

  Version 2.10

=head1 DESCRIPTION

  This utility adds chromosome files to the BioStudio genome repository from
  genbank inputs.

  Because BioStudio requires that every feature have a unique ID, this utility
  will also check to make sure that even subfeatures can be uniquely identified,
  and if they cannot, it will attempt to give them descriptive but unique names.

=head1 ARGUMENTS

Required arguments:

  -S, --SPECIES : The species name to be used
  -I, --INPUT : A genbank file containing one or more chromosome annotations

Optional arguments:

  -P, --PATH_TO_REPO : The path to the repo to be used; if not provided, uses
      the default as when BioStudio was installed
  -h, --help : Display this message

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Lawrence Berkeley
National Laboratory, the Department of Energy, and the BioStudio developers may
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
