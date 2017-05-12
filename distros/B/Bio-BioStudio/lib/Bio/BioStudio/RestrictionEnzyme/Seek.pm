#
# BioStudio restriction finding functions
#

=head1 NAME

Bio::BioStudio::RestrictionEnzyme::Seek

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::RestrictionEnzyme::Seek;
require Exporter;

use Bio::GeneDesign::Basic qw(:GD);
use Bio::GeneDesign::Codons qw(_translate);
use Bio::BioStudio::Parallel qw(:BS);
use Bio::BioStudio::RestrictionEnzyme;
use Bio::BioStudio::RestrictionEnzyme::Store;
use Digest::MD5;
use Storable;
use autodie qw(open close);
use File::Find;
use POSIX;
use Carp;
use English qw(-no_match_vars);

use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '2.10';

our @EXPORT_OK = qw(
  farm_search
  serial_search
  find_enzymes_in_CDS
  find_IIBs_in_CDS
  find_enzymes_in_igen
  farm_filter
  serial_filter
  filter
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

=head1 Functions

=head2 farm_search

=cut

sub farm_search
{
  my ($chr, $featlist, $p) = @_;
  my $chrname = $chr->name();
  my $redbname = $chrname . '_RED';
  my $GD = $chr->GD();
  my $RES = $GD->set_restriction_enzymes(-enzyme_set => $p->{ENZYME_SET});
  my @regs = grep {$_->class ne 'IIB'} values %{$RES};
  
  my $key = Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$$));
  my $tmp_path = Bio::BioStudio::ConfigData->config('tmp_path');
  
  my $tree = $GD->build_prefix_tree(-input => \@regs, -peptide => 1);
  my $treefilename = $tmp_path . $key . '.ptree';
  store $tree, $treefilename;

  my $parampath = $tmp_path . $key . '.param';
  store $p, $parampath;
    
  my @JOBLIST;
  my @OUTS;
  my @CLEANUP = ($treefilename);
  my $exec = 'BS_auto_gather_enzymes.pl';
  # Take each feature and create a taskfarmer work order for it.
  #
  my @feats = sort {$b->end - $b->start <=> $a->end - $a->start} @{$featlist};
  foreach my $feat (@feats)
  {
    my $name = $feat->display_name;
    my $outpath = $tmp_path . $key . q{_} . $name . '.out';
    my $cmd = $exec . q{ -chr } . $chrname . q{ -key } . $key;
    $cmd .= q{ -feature } . $name;
    push @JOBLIST, $cmd . q{:} . $outpath . q{:0};
    push @OUTS, $outpath;
  }
  my $jobs = join "\n", @JOBLIST;
  my $morefiles = taskfarm($jobs, $chrname, $key, 32);
  
  my @reals = ();
  foreach my $out (@OUTS)
  {
    if (-e $out)
    {
      push @reals, $out;
    }
    else
    {
      print "Failed on $out\n";
    }
  }
  my $loadpath = $tmp_path . $key . q{_} . $redbname . '.load';
  my $catcmd = "cat @reals > $loadpath";
  safeopen($catcmd);
  chmod 0777, $loadpath;
  my $REDB = Bio::BioStudio::RestrictionEnzyme::Store->new
  (
    -name => $redbname,
    -enzyme_definitions => $RES,
    -create => 1,
    -file => $loadpath
  );
  $REDB->dumpfile($loadpath);
  $REDB->load();
  push @CLEANUP, @OUTS, @{$morefiles};
  cleanup(\@CLEANUP);
  return $REDB;
}

=head2 serial_search

=cut

sub serial_search
{
  my ($chr, $featlist, $p) = @_;
  my $chrname = $chr->name();
  my $chrlen = $chr->len();
  my $redbname = $chrname . '_RED';
  my $RES = $chr->GD->set_restriction_enzymes(-enzyme_set => $p->{ENZYME_SET});
  my @regs = grep {$_->class ne 'IIB'} values %{$RES};
  my @bees = grep {$_->class eq 'IIB'} values %{$RES};

  ## Create and populate the prefix tree of restriction enzyme recognition sites
  my $tree = $chr->GD->build_prefix_tree(-input => \@regs, -peptide => 1);

  my $tmp_path = Bio::BioStudio::ConfigData->config('tmp_path');
  my $filename = $tmp_path . $redbname . '.out';
  #my @feats = sort {$b->end - $b->start <=> $a->end - $a->start} @{$featlist};
  my @feats = sort {$a->end - $a->start <=> $b->end - $b->start} @{$featlist};
  chmod 0777, $filename;
  open my $OUT, '>', $filename;
  foreach my $feat (@feats)
  {
    my $id = $feat->display_name;
    #print "Checking $id\n";
    my $results;
    my $besults;
    if ($feat->primary_tag eq 'CDS')
    {
      $besults = find_IIBs_in_CDS($chr, \@bees, $feat);
      $results = find_enzymes_in_CDS($chr, $tree, $feat);
    }
    else
    {
      $results = find_enzymes_in_igen($chr, $feat->start, $feat->end);
    }
    foreach my $enz (@{$results}, @{$besults})
    {
      print $OUT $enz->line_report(q{.}, "\n");
    }
    #print "\tGot ", scalar @{$results}, " plus ", scalar @{$besults}, " from $id\n";
  }
  close $OUT;
  my $REDB = Bio::BioStudio::RestrictionEnzyme::Store->new
  (
    -name => $redbname,
    -enzyme_definitions => $RES,
    -create => 1,
    -file => $filename
  );
  $REDB->dumpfile($filename);
  $REDB->load();
  return $REDB;
}

=head2 find_enzymes_in_CDS

=cut

sub find_enzymes_in_CDS
{
  my ($chr, $tree, $feat) = @_;
  my $GD = $chr->GD();
  my $phase = $feat->phase || 0;
  my $nucseq = $feat->seq->seq;
  my $aaseq = $GD->translate(-sequence => $nucseq, -frame => 1 + $phase);
  my $hits = $GD->search_prefix_tree(-tree => $tree, -sequence => $aaseq);
  my $results = [];
  my $RES = $GD->enzyme_set;
  my $fstart = $feat->start;
  my $fend = $feat->end;
  my $forient = $feat->strand;
  foreach my $rog (@{$hits})
  {
    my $enz       = $rog->[0];
    my $enzyme    = $RES->{$enz};
    my $class     = $enzyme->class();
    my $type      = $enzyme->type();
    my $nucstart  = $rog->[1] * 3;
    my $realpos   = $fstart + $nucstart;
    my $peptide   = $rog->[2];
    my @notes     = @{$rog->[3]};
    my $flip = 0;
    my $recsite   = $enzyme->recseq();
    if ($notes[0] ne $recsite)
    {
      $flip++;
      $recsite = _complement($recsite, 1);
    }
    my $presence  = 'p';
    my $ohang     = {};
    my ($mattersbit, $ohangstart, $ohangend, $fabric) = (q{}, 0, 0, q{});
    my ($offset, $situ, $pproof, $sitelen) = (0, q{}, q{}, 0);

  ##Figure Possible overhangs
    if ($type eq 'b')
    {
      $situ = substr $nucseq, $nucstart, (length $peptide) * 3;
      $pproof = _translate($situ, 1, $GD->{codontable});
      $ohangstart = 0;
    }
    elsif ($class eq 'IIP')
    {
      $sitelen = $enzyme->len;
      if ($sitelen + $realpos <= $fend)
      {
        my ($lef, $rig) = (undef, undef);
        ($lef, $rig) = (length $1, length $2) if ($enzyme->cutseq() =~ $enzyme->classex());
        ($lef, $rig) = ($rig, $lef) if ($rig < $lef);
        $ohangstart = $enzyme->len - $rig + 1;
        $ohangend = $enzyme->len - $lef;
        $situ = substr $nucseq, $nucstart, (length $peptide) * 3;
        ($fabric, $offset) = $GD->pattern_aligner(
          -sequence => $situ,
          -pattern => $recsite,
          -peptide => $peptide,
          -offset => 1
        );
        my $situstart = $ohangstart + $offset - 1;
        my $situlen = $ohangend - $ohangstart + 1;
        $mattersbit = substr $situ, $situstart, $situlen;
        $pproof = _translate($situ, 1, $GD->{codontable});
      }
    }
    elsif ($class eq 'IIA')
    {
      my ($lef, $rig) = ($enzyme->inside_cut, $enzyme->outside_cut);
      $sitelen = $rig >= 0 ? $enzyme->len + $rig  : $enzyme->len;
      if ($sitelen + $realpos <= $fend)
      {
        my $nuclen = (length $peptide) * 3;
        $nuclen++ while($nuclen % 3 != 0);
        $situ = substr $nucseq, $nucstart, $nuclen;
        ($fabric, $offset) = $GD->pattern_aligner(
          -sequence => $situ,
          -pattern => $recsite,
          -peptide => $peptide,
          -offset => 1
        );
        my $add;
        if ($flip == 1)
        {
          $ohangstart = $enzyme->len + $lef + 1;
          if ($rig > 0)
          {
            $add = $rig - ((length $fabric) - ($offset + $enzyme->len));
            $add ++ while ($add % 3 != 0);
            $situ .= substr $nucseq, $nucstart + $nuclen, $add;
            $fabric .= 'N' x $add;
          }
        }
        else
        {
          if ($rig > 0)
          {
            $add =  $rig - $offset;
            $add ++ while ($add % 3 != 0);
            $situ = substr($nucseq, $nucstart - $add, $add) . $situ;
            $fabric = 'N' x $add . $fabric;
            $nucstart = $nucstart - $add;
            $ohangstart = $add - $rig + 1;
          }
          else
          {
            $ohangstart = $offset + abs($rig) + 1;
          }
        }
        $mattersbit = substr $nucseq, $nucstart + $ohangstart + 1, $rig - $lef;
        $pproof = _translate($situ, 1, $GD->{codontable});
      }
    }
    else
    {
      print 'I do not recognize this type of enzyme: ' . $enzyme->id;
    }
    if ($realpos + $sitelen <= $fend)
    {
      if ($fabric eq '0')
      {
        print "oh no bad fabric, $enz, $fabric, $peptide\n";
        next;
      }
      my $lenm = $mattersbit ? length $mattersbit : 0;
      my $matstart = $ohangstart + $offset - 1;
         $matstart-- while($matstart % 3 != 0);
      my $matend = $ohangstart + $offset + $lenm - 1;
         $matend++ while($matend % 3 != 2);
      my $matlen = $matend - $matstart + 1;
      my $peproof = substr $pproof, ($matstart / 3), $matlen / 3;
      my $what = substr $fabric, $matstart, $matlen;
      my $transcs = _amb_transcription($what);
      foreach my $swapseq (@{$transcs})
      {
        next if (_translate($swapseq, 1, $GD->{codontable}) ne $peproof);
        substr $fabric, $matstart, $matlen, $swapseq;
        my $tohang = substr $fabric, $ohangstart +  $offset - 1, $lenm;
        $ohang->{$tohang}++ if ($tohang);#if ($tohang ne $GD->rcomplement($tohang));
      }
    }

  ##Determine Presence
    $presence = 'e' if ($situ =~ $enzyme->regex()->[$flip - 1]);
    next if ($presence eq 'p' && ! $pproof);
    my $ohangoffset = $ohangstart + $offset - 1;
    my $sitestart;
    $sitestart = $fstart + $nucstart if ($forient != -1);
    $sitestart = $fend - $nucstart + 1 - $enzyme->len if ($forient == -1);
    my $name = $enzyme->id . q{_} . $sitestart . q{_} . $pproof;
    my $strand = $flip == 2 ? -1 : 1;
    if ($sitestart + $sitelen - 1 > $fend)
    {
      $ohang = $mattersbit ? {$mattersbit => 1} : {};
    }
    push @{$results}, Bio::BioStudio::RestrictionEnzyme->new
    (
      -enzyme => $enzyme,
      -name => $name,
      -presence => $presence,
      -start => $sitestart,
      -end => $sitestart + $enzyme->len - 1,
      -feature  => $feat,
      -overhangs  => $ohang,
      -strand => $strand,
      -peptide => $pproof,
      -offset => $ohangoffset
    );
  }
  return $results;
}

=head2 find_IIBs_in_CDS

=cut

sub find_IIBs_in_CDS
{
  my ($chr, $enzlist, $feat) = @_;
  my $chrseq = $chr->sequence();
  my $chrlen = length $chrseq;
  my $GD = $chr->GD;
  my $RES = $GD->enzyme_set();
  my @list = map {$_->id} @{$enzlist};
  my $results = [];
  my $fstart = $feat->start;
  my $fend = $feat->end;
  my $forient = $feat->strand;
  my $seq = substr $chrseq, $fstart - 1, $fend - $fstart + 1;
  my $SITESTATUS = $GD->restriction_status(-sequence => $seq);
  foreach my $enzid ( grep {$SITESTATUS->{$_} >= 1} @list)
  {
    my $enz = $RES->{$enzid};
    my $enzlocs = $enz->positions($seq);
    my ($rlef, $rrig) = ($3, $4) if ($enz->cutseq =~ $enz->class_regexes->{IIB});
    ($rlef, $rrig) = ($rrig, $rlef) if ($rrig < $rlef);
    foreach my $enzpos (keys %{$enzlocs})
    {
      my $siteseq = $enzlocs->{$enzpos};
      my $strand = ($siteseq =~ $enz->regex->[0]) ? 1  : -1;
      my $sitestart = $enzpos + $fstart;
      my $sitend = $sitestart + $enz->len - 1;
      if ($forient == -1)
      {
        $sitend++ while (($fend - $sitend) % 3 != 0);
        $sitestart-- while (($sitend - $sitestart + 1) % 3 != 0 );
      }
      else
      {
        $sitestart-- while (($sitestart - $fstart) % 3 != 0);
        $sitend++ while (($sitend - $sitestart + 1) % 3 != 0 );
      }
      my $pretrans = substr $chrseq, $sitestart - 1, $sitend - $sitestart + 1;
      $pretrans = $GD->rcomplement($pretrans) if ($forient == -1);
      my $peptide = $GD->translate(-sequence => $pretrans);
      push @{$results}, Bio::BioStudio::RestrictionEnzyme->new(
        -enzyme => $enz,
        -name => $enz->id . q{_} . $sitestart,
        -presence => 'e',
        -start => $sitestart,
        -end => $sitend,
        -feature => $feat,
        -peptide => $peptide,
        -eligible => 'no',
        -overhangs  => {'NULL' => 1},
        -strand => $strand,
        -offset => $rlef
      );
    }
  }
  return $results;
}

=head2 find_enzymes_in_igen

=cut

sub find_enzymes_in_igen
{
  my ($chr, $fstart, $fend) = @_;
  my $chrseq = $chr->sequence();
  my $GD = $chr->GD;
  my $RES = $GD->enzyme_set();
  my $results = [];
  my $seq = substr($chrseq, $fstart - 1, $fend - $fstart + 1);
  my $SITESTATUS = $GD->restriction_status(-sequence => $seq);
  foreach my $enzid ( grep {$SITESTATUS->{$_} >= 1} keys %{$SITESTATUS})
  {
    my $enz = $RES->{$enzid};
    my $class = $enz->class();
    my $enzlocs = $enz->positions($seq);
    foreach my $enzpos (keys %{$enzlocs})
    {
      my $siteseq = $enzlocs->{$enzpos};
      my $strand = ($siteseq =~ $enz->regex->[0]) ? 1  : -1;
      my $sitestart = $enzpos + $fstart + 1;
      my ($ohangoffset, $ohangseq) = (0, q{});
      my $eligible = undef;
      if ($class eq 'IIP')
      {
        ($ohangoffset, $ohangseq) = $enz->overhang($siteseq);
      }
      elsif ($class eq 'IIA')
      {
        my ($lef, $rig) = (undef, undef);
        ($lef, $rig) = ($1, $2) if ($enz->cutseq =~ $enz->class_regexes->{IIA});
        ($lef, $rig) = ($rig, $lef) if ($rig < $lef);
        my $newseq;
        if ($strand == 1)
        {
          $newseq = substr($chrseq, $sitestart-2, $enz->len + $rig + 5);
        }
        else
        {
          $newseq = substr($chrseq, $sitestart - ($rig+7), $enz->len + $rig+5);
        }
        ($ohangoffset, $ohangseq) = $enz->overhang($siteseq, $newseq, $strand);
      }
      elsif ($class eq 'IIB')
      {
        my ($rlef, $rrig) = (undef, undef);
        ($rlef, $rrig) = ($3, $4) if ($enz->cutseq =~ $enz->class_regexes->{IIB});
        ($rlef, $rrig) = ($rrig, $rlef) if ($rrig < $rlef);
        ($ohangoffset, $ohangseq) = ($rlef, 'NULL');
        $eligible = 'no';
      }
      my $ohang = $ohangseq ?  {$ohangseq => 1} : {};
      push @{$results}, Bio::BioStudio::RestrictionEnzyme->new(
        -enzyme => $enz,
        -name => $enz->id . q{_} . $sitestart,
        -presence => 'i',
        -start => $sitestart,
        -end => $sitestart + $enz->len - 1,
        -eligible => $eligible,
        -overhangs  => $ohang,
        -strand => $strand,
        -offset => $ohangoffset
      );
    }
  }
  return $results;
}

=head2 farm_filter

=cut

sub farm_filter
{
  my ($chr, $REDB, $p) = @_;
  my $chrname = $chr->name();
  my $chrlen = $chr->len();

  my ($drcount, $igcount) = (0, 0);
  my $key = Digest::MD5::md5_hex(Digest::MD5::md5_hex(time().{}.rand().$$));
  my $tmp_path = Bio::BioStudio::ConfigData->config('tmp_path');

  my $parampath = $tmp_path . $key . '.param';
  store $p, $parampath;
      
  my @JOBLIST;
  my @OUTS;
  my @CLEANUP = ();
  my $exec = 'BS_auto_filter_enzymes.pl';
  my $step = ceil($chrlen / 48);
  my ($left, $right) = (1, $step);
  while ($left < $chrlen)
  {
    my $cmd = $exec . q{ -chr } . $chrname . q{ -key } . $key;
    $cmd .= q{ -left } . $left . q{ -right } . $right;
    my $outpath = $tmp_path . $key . q{_} . $left . q{-} . $right . '.out';
    push @JOBLIST, $cmd . q{:} . $outpath . q{:0};
    push @OUTS, $outpath;
    $left = $right + 1;
    $right += $step;
  }
  my $jobs = join "\n", @JOBLIST;
  my $morefiles = taskfarm($jobs, $chrname, $key, 32);
  foreach my $out (@OUTS)
  {
    if (-e $out)
    {
      my $resarr = retrieve($out);
      my ($adrcount, $aigcount) = @{$resarr};
      $drcount += $adrcount;
      $igcount += $aigcount;
    }
    else
    {
      print "Failed to get $out back\n";
    }
  }
  push @CLEANUP, @OUTS, @{$morefiles};
  cleanup(\@CLEANUP);
  return ($drcount, $igcount);
}

=head2 serial_filter

=cut

sub serial_filter
{
  my ($chr, $REDB, $p) = @_;
  my $chrname = $chr->name();
  my $chrlen = $chr->len();
  my $pool = $REDB->search(-left => 1, -right => $chrlen);
  my $mask = $chr->type_mask('gene');
  my @res = @{$pool};
  my ($drcount, $igcount) = (0, 0);
  foreach my $re (@res)
  {
    my ($culls, $ignores, $ineligibles) = filter($re, $REDB, $mask, $p->{CHUNKLENMIN});
    $drcount += $culls;
    $igcount += $ignores;
  }
  return ($drcount, $igcount);
}

=head2 filter

Given an enzyme in the database, determine if it will ever be eligible for
landmark status. If the site is "p", remove it from the db.  If the site is "e"
or "i", mark it ineligible in the db so it can be skipped in future analyses.

=cut

sub filter
{
  my ($re, $REDB, $mask, $minspan) = @_;
  my $drcount = 0;
  my $igcount = 0;
  return ($drcount, $igcount, 1) if ($re->eligible && $re->eligible eq 'no');

  my $redbid = $re->dbid;
  #IGNORE: if it is IIB
  if ($re->class eq 'IIB')
  {
    $REDB->screen([$redbid]);
    $igcount++;
    return ($drcount, $igcount, 0);
  }
  
  my $rstart = $re->start;
  my $rend = $re->end;
  my $repres = $re->presence;
  my $lef = $rstart - $minspan;
  my $rig = $rstart + $minspan;
  my $pool = $REDB->search(-left => $lef, -right => $rig, -enzyme => $re->id);
  my @reals = grep { $_->presence ne 'potential' } @{$pool};
  my @buds = grep { $_->name ne $re->name } @reals;
  
  #DROP: if there are too many intergenics around
  my @igenics = grep {$_->presence eq 'intergenic'} @buds;
  my $i_flag = scalar @igenics;
  if ($i_flag)
  {
    my @sum = map {$_->dbid} @igenics;
    if ($repres eq 'potential')
    {
      $REDB->cull([$redbid]);
      $drcount++;
      if ($i_flag > 1)
      {
        $REDB->screen(\@sum);
        $igcount += $i_flag;
      }
    }
    if ($repres ne 'potential')
    {
      push @sum, $redbid;
      $REDB->screen(\@sum);
      $igcount += $i_flag + 1;
    }
    return ($drcount, $igcount, 0);
  }
  
  #Drop if exonic in an exonic overlap
  my $size = $re->end - $rstart + 1;
  my $maskbit = $mask->count_features_in_range($rstart, $size);
  if ($maskbit > 1)
  {
    if ($repres eq 'potential')
    {
      $REDB->cull([$redbid]);
      $drcount++;
    }
    if ($repres ne 'potential')
    {
      $REDB->screen([$redbid]);
      $igcount++;
    }
    return ($drcount, $igcount, 0);
  }

  #Drop if would require modification in exon overlap
  my $gene = $repres ne 'intergenic'  ? $re->featureid  : q{};
  my @exonics = grep {$_->presence eq 'existing'} @buds;
  my $mod_flag = scalar @exonics;
  my $lap_flag = 0;
  foreach my $ex (@exonics)
  {
    my $esize = $ex->end - $ex->start + 1;
    my $emaskbit = $mask->count_features_in_range($ex->start, $esize);
    $lap_flag++ if ($emaskbit != 1);
  }
  if ($lap_flag != 0) #DROP: modification in exon overlap
  {
    my @sum = map {$_->dbid} @exonics;
    if ($repres eq 'potential')
    {
      $REDB->cull([$redbid]);
      $drcount++;
      if ($mod_flag > 1)
      {
        $REDB->screen(\@sum);
        $igcount += $mod_flag;
      }
    }
    if ($repres ne 'potential')
    {
      push @sum, $redbid;
      $REDB->screen(\@sum);
      $igcount += $mod_flag + 1;
    }
    return ($drcount, $igcount, 0);
  }
  
  # Score is the log of the price per unit plus 1/10 point for each orf modified
  my $score   = log($re->score) + (0.2 * $mod_flag);
  if ($score > 0.5) #DROP: score too high (>1)
  {
    if ($repres eq 'potential' && $re->class ne 'IIB')
    {
      $REDB->cull([$redbid]);
      $drcount++;
    }
    if ($repres ne 'potential' || $re->class eq 'IIB')
    {
      $REDB->screen([$redbid]);
      $igcount++;
    }
    return ($drcount, $igcount, 0);
  }
  return ($drcount, $igcount, 0);
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
