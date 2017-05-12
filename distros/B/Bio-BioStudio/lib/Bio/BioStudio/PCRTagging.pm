#
# BioStudio restriction finding functions
#

=head1 NAME

Bio::BioStudio::PCRTagging

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::PCRTagging;
require Exporter;

use Bio::GeneDesign::Codons qw(_translate);
use Bio::GeneDesign::Basic qw(_compare_sequences _complement _ntherm);
use Bio::Tools::Run::StandAloneBlastPlus;
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
  serial_tagging
  farm_tagging
  tag_gene
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

=head1 Functions

=head2 farm_tagging

=cut

sub farm_tagging
{
  my ($newchr, $genome, $p) = @_;
  my $GD = $newchr->GD;
  my $chrname = $newchr->name;
  my $key = Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$$));
  my $tmp_path = Bio::BioStudio::ConfigData->config('tmp_path');

  my $bdir = Bio::BioStudio::ConfigData->config('tmp_path');
  my $factory = Bio::Tools::Run::StandAloneBlastPlus->new(
    -db_dir  => $bdir,
    -db_name => $key,
    -db_data => $genome,
    -create  => 1
  );
  $factory->make_db();
  $factory->_register_temp_for_cleanup($key);

  my $parampath = $tmp_path . $key . '.param';
  store $p, $parampath;
  
  my %report = ();

  my @genes = $newchr->db->features(
    -seq_id     => $newchr->seq_id,
    -types      => 'gene',
    -start      => $p->{STARTPOS},
    -end        => $p->{STOPPOS},
    -range_type => 'contains'
  );
  @genes = sort {$b->end - $b->start <=> $a->end - $a->start} @genes;

  #Find tags, pick tags, implement tags, check for errors
  my @JOBLIST;
  my @OUTS;
  my @CLEANUP = ($parampath);
  my $exec = 'BS_auto_tag_genes.pl';
  my $hookup = {};
  foreach my $gene (@genes)
  {
    my $gid  = $gene->Tag_load_id;
    my $cmd = $exec . q{ -chr } . $chrname . q{ -key } . $key;
    $cmd .= q{ -gid } . $gid;
    my $outpath = $tmp_path . $key . q{_} . $gid . '.out';
    push @JOBLIST, $cmd . q{:} . $outpath . q{:0};
    push @OUTS, $outpath;
    $hookup->{$gid} = $outpath;
  }
  my $jobs = join "\n", @JOBLIST;
  my $morefiles = taskfarm($jobs, $chrname, $key);

  @genes = sort {$a->start <=> $b->start} @genes;
  foreach my $gene (@genes)
  {
    my $gid = $gene->Tag_load_id;
    my $outpath = $hookup->{$gid};
    if (! -e $outpath)
    {
      $report{$gid} = 'TAGGING FAILED!';
      next;
    }
    my $result = retrieve($outpath);
    my @tags = @{$result->[1]};
    my $comment = $result->[0];
    if (scalar @tags)
    {
      add_tags($newchr, $gene, $result->[1]);
    }
    $report{$gid} = $comment;
  }
  push @CLEANUP, @OUTS, @{$morefiles};
  cleanup(\@CLEANUP);
  $factory->cleanup();
  return \%report;
}

=head2 serial_tagging

=cut

sub serial_tagging
{
  my ($newchr, $genome, $p) = @_;
  my $mask = $newchr->type_mask(['CDS', 'intron']);
  my $GD = $newchr->GD;

  my $bdir = Bio::BioStudio::ConfigData->config('tmp_path');
  my $factory = Bio::Tools::Run::StandAloneBlastPlus->new(
    -db_dir  => $bdir,
    -db_data => $genome,
    -create  => 1
  );
  $factory->make_db();
  my %report = ();

  my @genes = $newchr->db->features(
    -seq_id     => $newchr->seq_id,
    -types      => 'gene',
    -start      => $p->{STARTPOS},
    -end        => $p->{STOPPOS},
    -range_type => 'contains'
  );

  #Find tags, pick tags, implement tags, check for errors
  foreach my $gene (@genes)
  {
    my $gid  = $gene->Tag_load_id;
    my $result = tag_gene($newchr, $mask, $factory, $gid, $p);
    my @tags = @{$result->[1]};
    my $comment = $result->[0];
    if (scalar @tags)
    {
      add_tags($newchr, $gene, $result->[1]);
    }
    $report{$gid} .= $comment;
  }
  $factory->cleanup();
  return \%report;
}

=head2 tag_gene

=cut

sub tag_gene
{
  my ($chr, $mask, $factory, $gid, $p) = @_;
  my $gene = $chr->fetch_features(-name => $gid);
  my $cDNA = $chr->make_cDNA($gene);
  my $dir = $gene->strand;
  my $return = undef;

  if (length $cDNA < $p->{MINORFLEN})
  {
    return ['too short', []];
  }
  
  #Extract all possible tags from the gene
  #
  my @pretags = @{find_tags($gene, $chr, $mask, $p)};
  if (scalar @pretags < 2)
  {
    return ['no more than one good tag preBLAST', []];
  }

  #BLAST all tags against the latest version of the genome
  # only keep tags that hit wtseq once and newseq never
  my @posttags = @{BLAST_tags(\@pretags, $factory)};
  if (scalar @posttags < 2)
  {
    return ['no more than one good tag postBLAST', []];
  }
  if ($posttags[0]->start + $p->{MINAMPLEN} > $posttags[-1]->end)
  {
    return ['bad tag range postBLAST', []];
  }

  #choose tag pairs
  #
  my $tagtarget = length($cDNA) - $p->{MINORFLEN};
  $tagtarget = $tagtarget / $p->{ORF_TAG_INC};
  $tagtarget = ($tagtarget % $p->{ORF_TAG_INC}) + 1;
  $p->{TARGET} = $tagtarget;
  my @chosen = @{pair_tags($gene, \@posttags, $mask, $factory, $p)};
  my $tagcount = scalar @chosen;
  if (! $tagcount)
  {
    return ['no good tag pairs', []];
  }
  my $plural = $tagcount > 1 ? q{s} : q{};
  return ["$tagcount pair$plural chosen", \@chosen];
}

=head2 find_tags

=cut

sub find_tags
{
  my ($gene, $chr, $mask, $p) = @_;
  my $MINTAGLEN        = $p->{MINTAGLEN},
  my $MAXTAGLEN        = $p->{MAXTAGLEN},
  my $MINTAGMELT       = $p->{MINTAGMELT},
  my $MAXTAGMELT       = $p->{MAXTAGMELT},
  my %BADAAS           = %{$p->{BADAAS}},
  my $MINPERDIFF       = $p->{MINPERDIFF},
  my $THREEPRIMEBUFFER = $p->{THREEPRIMEBUFFER},
  my $FIVEPRIMEBUFFER  = $p->{FIVEPRIMEBUFFER},

  my $gid = $gene->Tag_load_id;
  my $cDNA = $chr->make_cDNA($gene);
  my $GD = $chr->GD();
  my $gstart = $gene->start();
  my ($rstart, $rstop) = ($gstart, $gene->end);
  my $dir = $gene->strand;
  if ($dir != 1)
  {
    $rstart += $THREEPRIMEBUFFER;
    $rstop  -= $FIVEPRIMEBUFFER;
  }
  else
  {
    $rstart += $FIVEPRIMEBUFFER;
    $rstop  -= $THREEPRIMEBUFFER;
  }
  
  my $geneseq = $gene->seq->seq;
  my $aaseq = _translate($cDNA, 1, $GD->{codontable});
  
  #Extract all possible tags from the gene
  #
  my $chrseq = $chr->sequence;
  my @pretags = ();
  my $count = $MAXTAGLEN;
  while ($rstart + $count < $rstop - $MINTAGLEN)
  {
    #Make the wide oligo and the oligo
    my $woligo = substr $chrseq, $rstart - 1, $count + 2;
    my $wolen = length $woligo;

    my $tstart = $dir == 1  ? $rstart + 2 : $rstart;
    my $oligo = substr $chrseq, $tstart - 1, $count;
    my $olen = length $oligo;
    
    #Exclude oligos that begin or end in unswappable codons
    my $peptide = _translate($woligo, $dir, $GD->{codontable});
    my $firstres = substr $peptide,  0, 1;
    my $lastres  = substr $peptide, -1, 1;
    if (exists $BADAAS{$firstres} || exists $BADAAS{$lastres})
    {
      ($count, $rstart) = counterset($count, $rstart, $MINTAGLEN, $MAXTAGLEN);
      next;
    }
    
    #Exclude oligos that don't meet melting standard
    my $currTm = _ntherm($oligo);
    if ($currTm  < $MINTAGMELT || $currTm > $MAXTAGMELT)
    {
      if ($currTm < $MINTAGMELT)
      {
        $rstart = $rstart + 3;
        $count = $MAXTAGLEN;
      }
      elsif ($currTm > $MAXTAGMELT)
      {
        ($count, $rstart) = counterset($count, $rstart, $MINTAGLEN, $MAXTAGLEN);
      }
      next;
    }
        
    #Exclude oligos that aren't entirely in exons or lapped by other genes
    my @ofeats = $mask->feature_objects_in_range($rstart, $count);
    my @ifeats = grep { $_->primary_tag eq 'intron' } @ofeats;
    if (scalar @ifeats || scalar @ofeats > 1)
    {
      ($count, $rstart) = counterset($count, $rstart, $MINTAGLEN, $MAXTAGLEN);
      next;
    }

    #Recode oligos
    $woligo = _complement($woligo, 1) if ($dir == -1);
    my $wmdoligo = $GD->codon_juggle(
      -sequence => $woligo,
      -algorithm => 'most_different_sequence'
    );
    
    #Ensure that the first two bases are the same
    if ((substr $wmdoligo, 0, 2) ne (substr $woligo, 0, 2))
    {
      my $codon = substr $woligo, 0, 3;
      my $aa = $GD->{codontable}->{$codon};
      my $di = substr $codon, 0, 2;
      my $possibles = $GD->{reversecodontable}->{$aa};
      my @choices = grep {(substr $_, 0, 2) eq $di} @{$possibles};
      @choices = grep {(substr $_, -1) ne (substr $codon, -1)} @choices;
      substr $wmdoligo, 0, 3, $choices[0];
    }
    $woligo = _complement($woligo, 1) if ($dir == -1);
    $wmdoligo = _complement($wmdoligo, 1) if ($dir == -1);
    my $mdoligo = $dir == 1
      ? substr($wmdoligo, 2, $wolen - 2)
      : substr($wmdoligo, 0, $wolen - 2);

    #Exclude oligos whose recodes don't meet percent difference standard
    my $comps = _compare_sequences($oligo, $mdoligo);
    if ( $comps->{P} < $MINPERDIFF)
    {
      ($count, $rstart) = counterset($count, $rstart, $MINTAGLEN, $MAXTAGLEN);
      next;
    }
    
    #Exclude oligos whose recodes don't meet melting standard
    my $MDTm = _ntherm($mdoligo);
    if ($MDTm  < $MINTAGMELT || $MDTm > $MAXTAGMELT)
    {
      ($count, $rstart) = counterset($count, $rstart, $MINTAGLEN, $MAXTAGLEN);
      next;
    }
    
    my $offset = $tstart - $gstart + 1;
    my $tagid = $gid . q{_} . $offset;
    my $tag = Bio::BioStudio::SeqFeature::Tag->new(
      -start          => $offset,
      -end            => $offset + $olen - 1,
      -display_name   => $tagid,
      -ingene         => $gid,
      -wtseq          => $oligo,
      -newseq         => $mdoligo,
      -wtpos          => $tstart,
      -difference     => $comps->{P},
      -translation    => $peptide,
    );
    push @pretags, $tag;
    
    ($count, $rstart) = counterset($count, $rstart, $MINTAGLEN, $MAXTAGLEN);
  }
  return \@pretags;
}

=head2 BLAST_tags

=cut

sub BLAST_tags
{
  my ($tagarr, $factory) = @_;
  my @tags = @{$tagarr};
  
  #BLAST all tags against the latest version of the genome
  my @tagobjs = ();
  foreach my $tag (@tags)
  {
    my $id = $tag->display_name;
    my $wtobj  = Bio::Seq->new(-seq => $tag->wtseq(),  id => 'wt_' . $id);
    my $newobj = Bio::Seq->new(-seq => $tag->newseq(), id => 'md_' . $id);
    push @tagobjs, $wtobj, $newobj;
  }
  
  $factory->run(
    -method           => 'blastn',
    -query            => \@tagobjs,
    -method_args => [
      -word_size      => 17,
      -perc_identity  => 70
  ]);
  $factory->rewind_results;
  my %hits;
  while (my $result = $factory->next_result)
  {
    my $name = $result->query_name();
    while( my $hit = $result->next_hit())
    {
      while( my $hsp = $hit->next_hsp())
      {
        $hits{$name}++;
      }
    }
  }
  
  #only keep tags that hit wtseq once and newseq never
  my @posttags;
  foreach my $tag (sort {$a->start <=> $b->start} @tags)
  {
    my $id = $tag->display_name;
    my $wthits = $hits{'wt_' . $id} || 0;
    my $mdhits = $hits{'md_' . $id} || 0;
    next if ($wthits > 1 || $mdhits > 0);
    push @posttags, $tag;
  }
  $factory->cleanup;
  return \@posttags;
}

=head2 pair_tags

=cut

sub pair_tags
{
  my ($gene, $tagarr, $mask, $factory, $p) = @_;
  my $TARGET = $p->{TARGET};
  my $MAXLEN = $p->{MAXAMPLEN};
  my $MINLEN = $p->{MINAMPLEN};
  my $MAXOLAP = $p->{MAXAMPOLAP};
  my @tags = @{$tagarr};
  my $tagcount = 0;
  my @chosen;
  my %usedtags = ();
  my $tmask = Bio::BioStudio::Mask->new(-sequence => $gene);
  my $amask = Bio::BioStudio::Mask->new(-sequence => $gene);

  foreach my $utag (sort sortdiff @tags)
  {
    my $ustart = $utag->start;
    my $uend = $utag->end;
    my $ulen = $uend - $ustart + 1;
    my $mcount = $tmask->count_features_in_range($ustart, $ulen);
    next if ($mcount > 0);

    my %possibles;
    my @pool = grep {! exists $usedtags{$_->display_name}} @tags;
    foreach my $dtag (@pool)
    {
      my $dstart = $dtag->start;
      my $dend = $dtag->end;
      my $flen = $dend - $ustart;
      my $tlen = $uend - $dstart;
      my $upver = $flen <= $MAXLEN && $flen >= $MINLEN;
      my $dnver = $tlen <= $MAXLEN && $tlen >= $MINLEN;
      next if (! ($upver || $dnver));
      
      #nominal size of the amplicon, with and without intron removal
      my $tstart = $ustart < $dstart  ? $ustart : $dstart;
      my $tend   = $ustart < $dstart  ? $dend   : $uend;
      my $pampsize = $tend - $tstart + 1;
      my @ofeats = $mask->feature_objects_in_range($tstart, $pampsize);
      my @ifeats = grep { $_->primary_tag() eq 'intron' } @ofeats;
      my $intronbp = 0;
      $intronbp += $_->length() foreach (@ifeats);
      my $ampsize = $pampsize - $intronbp;
      next if ($ampsize > $MAXLEN || $ampsize < $MINLEN);
     
      #would this tag overlap a previously chosen tag
      my $dtaglen = $dend - $dstart + 1;
      my $dcount = $tmask->count_features_in_range($dstart, $dtaglen);
      next if ($dcount > 0);
     
      #how badly would would overlap an existing amplicon
      my %occs = $amask->occlusion($tstart, $pampsize);
      my $occflag = 0;
      my $maxolap = 0;
      foreach my $occ (keys %occs)
      {
        my $olap = $occs{$occ};
        $occflag++ if ($olap > ($MAXOLAP / 100));
        $maxolap = $olap if ($olap > $maxolap);
      }
      next if ($occflag > 0);
      
      my $diffd = $dtag->difference();
      $possibles{$dtag->display_name} = [$maxolap, $diffd, $dtag];
    }
    next if (! scalar(keys %possibles));
    my @downstreams = sort {  $possibles{$a}->[0] <=> $possibles{$b}->[0]
                           || $possibles{$a}->[1] <=> $possibles{$b}->[1] }
                      keys %possibles;
    my @downbuds = map {$possibles{$_}->[2]} @downstreams;
    
    my $partner = BLAST_pairs($utag, \@downbuds, $factory);
    if ($partner)
    {
      $tagcount++;
      $usedtags{$utag->display_id}++;
      $usedtags{$partner->display_id}++;
      $tmask->add_to_mask([$utag, $partner]);
      my ($tstart, $tend) = (undef, undef);
      if ($ustart < $partner->start)
      {
        $tstart = $ustart;
        $tend = $partner->end;
        push @chosen, [$utag, $partner];
      }
      else
      {
        $tstart = $partner->start;
        $tend = $utag->end;
        push @chosen, [$partner, $utag];
      }
      my $amp = Bio::SeqFeature::Generic->new(
        -start          => $tstart,
        -end            => $tend,
        -display_name   => 'anonamp' . $tagcount,
        -primary_tag    => 'amplicon',
      );
      $amask->add_to_mask([$amp]);
    }
    last if ($tagcount == $TARGET);
  }
  return \@chosen;
}

=head2 BLAST_pairs

=cut

sub BLAST_pairs
{
  my ($utag, $dntags, $factory) = @_;
  #BLAST the pair to check amplification uniqueness.
  #
  my %phits = ();
  my %objs = ();
  # The utag wt and new sequences, forwards
  my $uid = $utag->display_name;
  my $uwtid = 'rcwt_' . $uid;
  $phits{$uwtid} = [];
  $objs{$uwtid} = Bio::Seq->new(-seq => $utag->wtseq(),  id => $uwtid);
  my $unewid = 'rcmd_' . $uid;
  $phits{$unewid} = [];
  $objs{$unewid} = Bio::Seq->new(-seq => $utag->newseq(), id => $unewid);
  # The dtags wt and new sequences, reverses
  my @dtagids = ();
  my @downbuds = @{$dntags};
  my %refs;
  foreach my $dtag (@downbuds)
  {
    my $did = $dtag->display_name;
    $refs{$did} = $dtag;
    push @dtagids, $did;
    my $dwtid = 'rcwt_' . $did;
    $phits{$dwtid} = [];
    $objs{$dwtid} = Bio::Seq->new(-seq => $dtag->wtseq(),  id => $dwtid);
    my $dnewid = 'rcmd_' . $did;
    $phits{$dnewid} = [];
    $objs{$dnewid} = Bio::Seq->new(-seq => $dtag->newseq(), id => $dnewid);
  }
  
  my @pairobjs = values %objs;
  $factory->run(
    -method               => 'blastn',
    -query                => \@pairobjs,
    -method_args => [
      -word_size          => 4,
      -gapextend          => 2,
      -gapopen            => 1,
      -penalty            => -1,
      -perc_identity      => 70,
      -best_hit_overhang  => .25
  ]);
  $factory->rewind_results;
  while (my $result = $factory->next_result)
  {
    my $name = $result->query_name();
    my $qlen = length $objs{$name}->seq;
    while( my $hit = $result->next_hit())
    {
      while( my $hsp = $hit->next_hsp())
      {
        next if $hsp->percent_identity < 85;
        next if ($hsp->length < .7 * $qlen);
        push @{$phits{$name}}, [$hit, $hsp];
      }
    }
  }
  my $partner = undef;
  my @Fwts = @{$phits{'rcwt_' . $uid}};
  my @Fmds = @{$phits{'rcmd_' . $uid}};
  foreach my $dtagid (@dtagids)
  {
    my ($wtnogo, $mdnogo) = (0, 0);
    my @Rwts = @{$phits{'rcwt_' . $dtagid}};
    foreach my $Rwpair (@Rwts)
    {
      my ($Rwhit, $Rwhsp) = @{$Rwpair};
      foreach my $Fwpair (@Fwts)
      {
        my ($Fwhit, $Fwhsp) = @{$Fwpair};
        #Pass if hits are on different chromosomes
        next if ($Rwhit->name ne $Fwhit->name);
        #Pass if hits are on the same strand
        next if ($Rwhsp->strand eq $Fwhsp->strand);
        $wtnogo++;
      }
    }
    my @Rmds = @{$phits{'rcmd_' . $dtagid}};
    foreach my $Rmpair (@Rmds)
    {
      my ($Rmhit, $Rmhsp) = @{$Rmpair};
      foreach my $Fmpair (@Fmds)
      {
        my ($Fmhit, $Fmhsp) = @{$Fmpair};
        #Pass if hits are on different chromosomes
        next if ($Rmhit->name ne $Fmhit->name);
        #Pass if hits are on the same strand
        next if ($Rmhsp->strand eq $Fmhsp->strand);
        $mdnogo++;
      }
    }
    if ($mdnogo + $wtnogo == 0)
    {
      $partner = $refs{$dtagid};
      last;
    }
  }
  $factory->cleanup;
  return $partner;
}

=head2 counterset

=cut

sub counterset
{
  my ($count, $start, $minlen, $maxlen) = @_;
  $start = $start + 3 if ($count < $minlen + 2);
  $count = $count >= $minlen + 2 ? $count - 3 : $maxlen;
  return ($count, $start);
}

=head2 add_tags

  Add tags and amplicons to database, make sequence changes

=cut

sub add_tags
{
  my ($chr, $gene, $tagarr, $report) = @_;
  my @chosen = @{$tagarr};
  my $tagcount = scalar @chosen;
  my $gstart = $gene->start;
  my $gend = $gene->end;
  my $gid = $gene->Tag_load_id;
  my $tcount = 1;
  foreach my $tagpair (@chosen)
  {
    my ($gutag, $gdtag) = @{$tagpair};
    my $adjust = $gstart - 1;
    $gutag->start($gutag->start() + $adjust);
    $gdtag->start($gdtag->start() + $adjust);
    $gutag->end($gutag->end() + $adjust);
    $gdtag->end($gdtag->end() + $adjust);
    my $utagid = $gutag->display_name;
    my $dtagid = $gdtag->display_name;
    my $aid = $gid . '_amp' . $tcount;
    my $comment  = "PCR_product $aid annotated ";
    $comment .= "(tags $utagid and $dtagid added)";
  
    my $amp = Bio::BioStudio::SeqFeature::Amplicon->new(
      -start          => $gutag->start,
      -end            => $gdtag->end,
      -ingene         => $gid,
      -uptag          => $utagid,
      -dntag          => $dtagid,
      -display_name   => $aid,
    );
    $chr->add_feature(-feature => $gutag);
    $chr->add_feature(-feature => $gdtag);
    $chr->add_feature(-feature => $amp, -comments => [$comment]);
    $tcount++;
  }
  return;
}

=head2 sortdiff

=cut

sub sortdiff
{
  return $b->difference() <=> $a->difference() || $a->start <=> $b->start;
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
