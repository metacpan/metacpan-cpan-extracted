#!/usr/bin/env perl

use Bio::BioStudio;
use Bio::GeneDesign;
use URI::Escape;
use English qw(-no_match_vars);
use Text::Wrap qw($columns &wrap);
use autodie qw(open close);
use Getopt::Long;
use Pod::Usage;

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_AddFromGFF_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'SPECIES=s'       => \$p{SPECIES},
  'PATH_TO_REPO=s'  => \$p{PATH},
  'INPUT=s'         => \$p{INPUT},
	'help'            => \$p{HELP},
);
if ($p{HELP})
{
  pod2usage(
    -verbose=>99,
    -sections=>'NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE'
  );
}

################################################################################
################################# SANITY CHECK #################################
################################################################################
my $GD = Bio::GeneDesign->new();

#The input file must exist and be a format we care to read.
die "\nBSERROR: You must supply an input file." if (! defined $p{INPUT});
die "\nBSERROR: Can't find input file $p{INPUT}." if (! -e $p{INPUT});

my $BS = $p{PATH}
  ? Bio::BioStudio->new(-repo => $p{PATH})
  : Bio::BioStudio->new();
my $repopath = $BS->path_to_repo();

die "\nBSERROR: No species name was given" if (! defined $p{SPECIES});
my %slist = $BS->species_list();
if (exists $slist{$p{SPECIES}})
{
  die "\nBSERROR: $p{SPECIES} already exists in the repo at $repopath... "
   . 'Manual intervention required.';
}

################################################################################
################################# CONFIGURING ##################################
################################################################################
my $name = $p{SPECIES};
my $db = Bio::DB::SeqFeature::Store->new
(
  -adaptor  => 'memory',
  -dsn      => $p{INPUT}
);
my @seqids = $db->seq_ids();
my $objcount = scalar @seqids;
my $chrcount = 1;
my $thick = $objcount < 2 ? 2 : $objcount;

foreach my $seqid (@seqids)
{
  my $sflag = 0;
  my $oseqid = $seqid;
  my @proced;
  if ($seqid !~ m{chr}msix)
  {
    $seqid = 'chr' . $seqid;
    $sflag++;
  }
  my @featlist = $db->features(-seq_id => $seqid);
  foreach my $feat (sort {$a->{start} <=> $b->{start}} @featlist)
  {
    next if ($feat->has_tag('Parent') || $feat->has_tag('parent_id'));
    #print "Working on $feat\n";
    $feat->seqid($seqid) if ($sflag);
    push @proced, gff3_string($feat) . "\n";
    #Uniquing subfeature ids
    my @subs = flatten_subfeats($feat);
    if (scalar @subs)
    {
      my %typehsh;
      my $pname = $feat->display_name;
      $typehsh{$_}++ foreach (map {$_->primary_tag} @subs);
      my %seenhash = map {$_ => 1} keys %typehsh;
      foreach my $sub (@subs)
      {
        #print "\t subfeature $sub\n";
        $sub->seqid($seqid) if ($sflag);
        my $dname = $sub->display_name;
        my $type = $sub->primary_tag;
        my $sfname;
        if ($typehsh{$type} > 1)
        {
          $sfname  = $sub->Tag_parent_id . "_$type" . "_$seenhash{$type}";
        }
        else
        {
          $sfname = $sub->Tag_parent_id . "_$type";
        }
        $sub->remove_tag('load_id');
        $sub->add_tag_value('load_id', $sfname);
        $sub->update();
        $seenhash{$type}++;
        push @proced, gff3_string($sub) . "\n";
      }
    }
  }
  my $rpath = $BS->prepare_repository($name, $seqid);
  my $cname = $name . q{_} . $seqid . q{_0_00.gff};
  my $path = $rpath . $cname;
  open (my $GFF, '>', $path) || die "can't write $path, $OS_ERROR\n";
  print {$GFF} "##gff-version 3\n#\n";
  print {$GFF} @proced;
  my $chrseq = $db->fetch_sequence(-seqid=> $oseqid);
  print {$GFF} "##FASTA\n";
  $columns = 81;
  print {$GFF} q{>} . $seqid . "\n";
  print {$GFF} wrap(q{}, q{}, $chrseq), "\n";
  close $GFF;
  print "Wrote $cname to $path\n";
}

print "\n\n";

exit;

sub flatten_subfeats
{
  my ($feature) = @_;
  my @subs = $feature->get_SeqFeatures();
  push @subs, $_->get_SeqFeatures foreach (@subs);
  return @subs;
}

sub gff3_string
{
  my ($feat) = @_;
  my ($seqid, $source, $type, $start, $end, $score, $strand, $phase,) =
  ($feat->seq_id(), $feat->source_tag(), $feat->primary_tag(), $feat->start(),
   $feat->end(), $feat->score(), $feat->strand(), $feat->phase(),);
  $score = $score ? $score  : q{.};
  $phase = $phase && ($phase == 1 || $phase == 2 || $phase == 0) ? $phase : q{.};
  $strand = $strand == -1 ? q{-} : $strand == 1  ? q{+} : q{.};
  my $str = "$seqid\t$source\t$type\t$start\t$end\t$score\t$strand\t$phase\t";
  if ($feat->has_tag('load_id'))
  {
    $str .= 'ID=' . $feat->Tag_load_id . q{;};
    $str .= 'Name=' . $feat->Tag_load_id . q{;};
  }
  elsif ($feat->display_name)
  {
    $str .= 'ID=' . $feat->display_name . q{;};
    $str .= 'Name=' . $feat->display_name . q{;};
  }
  else
  {
    print q{};
  }
  if ($feat->has_tag('parent_id'))
  {
    $str .= 'Parent=' . $feat->Tag_parent_id . q{;};
  }
  foreach my $tag (sort{$a cmp $b} $feat->get_all_tags())
  {
    next if ($tag eq 'load_id' || $tag eq 'parent_id' || $tag eq 'display_name');
    my @vals = $feat->each_tag_value($tag);
    if (scalar @vals )
    {
      my $attstr = join q{,}, @vals;
      $attstr =~ s{\h+}{ }msixg;
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
  $str =~ s{\r}{}msixg;
  return $str;
}


__END__

=head1 NAME

  BS_AddFromGFF.pl

=head1 VERSION

  Version 2.10

=head1 DESCRIPTION

  This utility adds chromosome files to the BioStudio genome repository from
  gff inputs.

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
