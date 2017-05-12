#
# BioStudio restriction finding functions
#

=head1 NAME

Bio::BioStudio::CodonJuggling

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::CodonJuggling;
require Exporter;

use Bio::Tools::Run::StandAloneBlastPlus;
use Bio::GeneDesign::Basic qw(_compare_sequences);
use Bio::BioStudio::Parallel qw(:BS);
use Digest::MD5;
use Storable;
use autodie qw(open close);
use File::Find;
use POSIX;
use English qw(-no_match_vars);

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  serial_juggling
  farm_juggling
  juggle_gene
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

=head1 Functions

=head2 farm_juggling

=cut

sub farm_juggling
{
  my ($newchr, $p) = @_;
  my $state = {};
  my $chrname = $newchr->name;
  my $key = Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$$));
  my $tmp_path = Bio::BioStudio::ConfigData->config('tmp_path');

  my $parampath = $tmp_path . $key . '.param';
  store $p, $parampath;
    
  my @pgenes = $newchr->db->features(
    -seq_id     => $newchr->seq_id,
    -range_type => 'contains',
    -types      => 'gene',
    -start      => $p->{STARTPOS},
    -end        => $p->{STOPPOS},
  );
  
  #Find tags, pick tags, implement tags, check for errors
  my @JOBLIST;
  my @OUTS;
  my @CLEANUP = ($parampath);
  my $exec = 'BS_auto_codon_juggle.pl';
  my $hookups = {};
  my $memo = {};
  foreach my $gene (@pgenes)
  {
    my $gname  = $gene->display_name;
    my $cmd = $exec . q{ -chr } . $chrname . q{ -key } . $key;
    $cmd .= q{ -gid } . $gname;
    my $outpath = $tmp_path . $key . q{_} . $gname . '.out';
    push @JOBLIST, $cmd . q{:} . $outpath . q{:0};
    push @OUTS, $outpath;
    $hookups->{$outpath} = $gname;
  }
  my $jobs = join "\n", @JOBLIST;
  my $morefiles = taskfarm($jobs, $chrname, $key);
  foreach my $out (@OUTS)
  {
    if (! -e $out)
    {
      my $gid = $hookups->{$out};
      $state->{$gid}->[2] .= ' Codon juggling failed! ';
      next;
    }
    my $result = retrieve($out);
    foreach my $gname (keys %{$result})
    {
      if (exists $state->{$gname})
      {
        $state->{$gname}->[0] += $result->{$gname}->[0];
        $state->{$gname}->[1] += $result->{$gname}->[1];
        $state->{$gname}->[2] .= $result->{$gname}->[2];
        push @{$state->{$gname}->[3]}, @{$result->{$gname}->[3]};
      }
      else
      {
        $state->{$gname} = $result->{$gname};
      }
    }
  }
  foreach my $gname (sort keys %{$state})
  {
    add_codons($newchr, $state->{$gname}->[3]);
  }
  push @CLEANUP, @OUTS, @{$morefiles};
  cleanup(\@CLEANUP);
  return $state;
}

=head2 serial_juggling

=cut

sub serial_juggling
{
  my ($newchr, $p) = @_;
  my $state = {};
  my $mask = $newchr->empty_mask();
  my @pgenes = $newchr->db->features(
    -seq_id     => $newchr->seq_id,
    -range_type => 'contains',
    -types      => 'gene',
    -start      => $p->{STARTPOS},
    -end        => $p->{STOPPOS},
  );
  foreach my $pgene (@pgenes)
  {
    my @subfeats = $newchr->flatten_subfeats($pgene);
    my @CDSes = grep {$_->primary_tag eq 'CDS'} @subfeats;
    next if (! scalar @CDSes);
    $mask->add_to_mask(\@subfeats);
    my $result = juggle_gene($newchr, $mask, $pgene->display_name, $p);
    foreach my $gname (keys %{$result})
    {
      if (exists $state->{$gname})
      {
        $state->{$gname}->[0] += $result->{$gname}->[0];
        $state->{$gname}->[1] += $result->{$gname}->[1];
        $state->{$gname}->[2] .= $result->{$gname}->[2];
        push @{$state->{$gname}->[3]}, @{$result->{$gname}->[3]};
      }
      else
      {
        $state->{$gname} = $result->{$gname};
      }
    }
  }
  foreach my $gname (sort keys %{$state})
  {
    add_codons($newchr, $state->{$gname}->[3]);
  }
  return $state;
}

=head2 juggle_gene

=cut

sub juggle_gene
{
  my ($chr, $mask, $gid, $p) = @_;
  my $gene = $chr->fetch_features(-name => $gid);
  my $GD = $chr->GD();
  my $chrseq = $chr->sequence();
  my $return = {};

  my $offset = $gene->start() - 1;
  my $gmask = Bio::BioStudio::Mask->new(-sequence => $gene, -offset => $offset);
  my @subfeats = $chr->flatten_subfeats($gene);
  $gmask->add_to_mask(\@subfeats);
  my %subs = map {$_->primary_id => 1} @subfeats;
  $subs{$gid}++;
  
  my $orient = $gene->strand();
  my $gstart = $gene->start();
  my $gend = $gene->end();
  my $glen = $gend - $gstart + 1;
  #number of codons, number of alts, notes, $gid, codons
  $return->{$gid} = [0, 0, q{}, []];
  
  my $x = $gstart;
  while ($x <= $gend - 2)
  {
    ##Adjust for introns
    my %posa = $gmask->what_objects_overlap($x);
    my @introns = grep {$_->primary_tag eq 'intron'} values %posa;
    $x = $introns[0]->end + 1 if (scalar @introns);
    my $basea = $x;
    $x++;
    
    my %posb = $gmask->what_objects_overlap($x);
    @introns = grep {$_->primary_tag eq 'intron'} values %posb;
    $x = $introns[0]->end + 1 if (scalar @introns);
    my $baseb = $x;
    $x++;
    
    my %posc = $gmask->what_objects_overlap($x);
    @introns = grep {$_->primary_tag eq 'intron'} values %posc;
    $x = $introns[0]->end + 1 if (scalar @introns);
    my $basec = $x;
    $x++;
    
    ##Codon sequence
    my $cod = (substr $chrseq, $basea - 1, 1)
            . (substr $chrseq, $baseb - 1, 1)
            . (substr $chrseq, $basec - 1, 1);
    next if ($orient <  0 && $cod ne $p->{MORF});
    next if ($orient >= 0 && $cod ne $p->{FROM});
    
    ##Annotate a potential codon change
    my $newcod = $orient > 0  ? $p->{TO}  : $p->{OT};
    my $oldcod = $orient > 0 ? $p->{FROM} : $p->{MORF};
    my $oset = $basea - $gstart + 1;
    my $codname = $gid . q{_} . $p->{OLDAA} . $oset . $p->{NEWAA};

    my $codon = Bio::BioStudio::SeqFeature::Codon->new(
      -start        => $basea,
      -end          => $basec,
      -primary_tag  => $p->{SWAPTYPE},
      -display_name => $codname,
      -wtseq        => $oldcod,
      -newseq       => $newcod,
      -parent       => $gid
    );

    ## Check for overlaps
    my $maskbit = $mask->count_features_in_range($basea, 3);
    
    ## No overlap involved - make the change and move on
    #
    if ($maskbit == 1)
    {
      $return->{$gid}->[0]++;
      push @{$return->{$gid}->[3]}, $codon;
      next;
    }
    
    ## Overlap involved:
    #
    my @featlaps = $mask->feature_objects_in_range($basea, 3);
    my @theseolaps = grep {! exists $subs{$_->primary_id}} @featlaps;
    my $lapcount = scalar @theseolaps;
    # If there are more than one overlapping features, no change can be made
    if ($lapcount > 1)
    {
      $return->{$gid}->[2] .= "cannot change codon at $basea (too occluded) ";
      next;
    }
    # If there are zero, we have run into an internal error
    elsif ($lapcount < 1)
    {
      $return->{$gid}->[2] .= "cannot change codon at $basea (INTERNAL ERROR) ";
      next;
    }
    
    # If the only overlapping feature is an intron, no change can be made
    if ($theseolaps[0]->primary_tag eq 'intron')
    {
      $return->{$gid}->[2] .= "cannot change codon at $basea (overlaps an intron)";
      next;
    }
    
    # Now the overlap must be a CDS; determine the frame
    my $lapfeat = $theseolaps[0];
    my $lapname = $lapfeat->display_name;
    my $lapstart = $lapfeat->start;
    my $laporient = $lapfeat->strand;
    my $laplen = $lapfeat->end - $lapstart + 1;
    my $CDSseq = substr $chrseq, $lapstart - 1, $laplen;
    my $frame = ($basea - $lapstart) % 3;
    my $length = $basec - ($basea - $frame) + 1;
    $length++ while ($length % 3 != 0);
    my $syncodstart = $basea - $lapstart - $frame;
    my $inframe = substr $CDSseq, $syncodstart, $length;
    my $lappep = $laporient == 1
      ?  $GD->translate($inframe)
      :  $GD->translate($GD->rcomplement($inframe));
    my $orientswit = $lapfeat->strand eq $orient  ?  0  :  1;
    my $changes  = $chr->allowable_codon_changes($p->{FROM}, $p->{TO});
    my %allowed = %{$changes->{$orientswit}};
    my $allowflag = exists $allowed{$lappep}  ? 1 : 0;
    
    # If the change doesn't preserve overlapping sequence and no exceptions were
    # provided, skip
    my $lapstatus = $lapfeat->Tag_orf_classification;
    my $genstatus = $gene->Tag_orf_classification;
    my $dubwhack = $lapstatus eq 'Dubious' && $genstatus ne 'Dubious' ? 1 : 0;
    my $verwhack = $genstatus ne 'Dubious'  ? 1 : 0;
    
    if ($allowflag == 0 && (! $p->{ALLWHACK}
      || ! ($dubwhack && $p->{DUBWHACK}) || ! ($verwhack && $p->{VERWHACK})))
    {
      $return->{$gid}->[2] .= "cannot change codon at $basea (overlaps $lapname)";
      next;
    }

    # Add the codon for this gene
    $return->{$gid}->[0]++;
    push @{$return->{$gid}->[3]}, $codon;

    # Add the codon for the overlapping gene
    my $newCDSseq = substr $chrseq, $lapstart - 1, $laplen;
    my $newframe = substr $newCDSseq, $syncodstart, $length;
    
    for (my $offset = 0; $offset <= $length - 3; $offset += 3)
    {
      my $oldsyncod = substr $inframe, $offset, 3;
      my $newsyncod = substr $newframe, $offset, 3;
      my $pos = $syncodstart + $offset + $lapstart + 1;
      if ($oldsyncod ne $newsyncod)
      {
        my $newLcod = $newsyncod;
        if ($laporient == -1)
        {
          $newLcod = $GD->rcomplement($newLcod);
        }
        my $newLaa = $GD->codontable->{$newLcod};
    
        my $oldLcod = $oldsyncod;
        if ($laporient == -1)
        {
          $oldLcod = $GD->rcomplement($oldLcod);
        }
        my $oldLaa = $GD->codontable->{$oldLcod};

        my $swaptype = $GD->codon_change_type(-from => $oldLcod, -to => $newLcod);
        $newLcod = $newsyncod if ($laporient == -1);
        $oldLcod = $oldsyncod if ($laporient == -1);
        
        my $Loffset = $pos - $lapstart + 1;
        my $parent = $lapfeat->has_tag('parent_id') ? $lapfeat->Tag_parent_id : $lapname;
        $return->{$parent} = [0, 0, q{}, []] if (! exists $return->{$parent});
        my $codLname = $parent . q{_} . $oldLaa . $Loffset . $newLaa;
        my $modnote = " $codLname modified to accommodate $p->{FROM} to $p->{TO} change in $gid";

        my $Lcodon = Bio::BioStudio::SeqFeature::Codon->new(
          -start        => $pos - 1,
          -end          => $pos+1,
          -primary_tag  => $swaptype,
          -display_name => $codLname,
          -wtseq        => $oldLcod,
          -newseq       => $newLcod,
          -parent       => $parent,
          -Note         => $modnote,
        );
        $return->{$parent}->[1]++;
        $return->{$parent}->[2] .= $modnote;
        push @{$return->{$parent}->[3]}, $Lcodon;
      }
    }
  }
  return $return;
}

=head2 add_codons

=cut

sub add_codons
{
  my ($chr, $codarr) = @_;
  my @codons = @{$codarr};
  foreach my $codon (@codons)
  {
    my $comment = $codon->primary_tag . q{ } . $codon->display_name . ' added';
    $chr->add_feature(-feature => $codon, -comments => [$comment]);
  }
  return;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

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
