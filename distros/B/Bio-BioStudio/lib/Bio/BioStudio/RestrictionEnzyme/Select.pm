=head1 NAME

Bio::BioStudio::RestrictionEnzyme::Select

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

BioStudio functions

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::RestrictionEnzyme::Select;
require Exporter;

use Bio::BioStudio::RestrictionEnzyme;
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
  ProposeCandidates
  NextCandidate
  wtISS
  ProposeExcisors
  removeEnzyme
  addEnzyme
  annotateEnzyme
  removeFromMarker
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);

=head1 Functions

=head2 ProposeCandidates

 Given a position along the chromosome, nominates low penalty restriction sites

=cut

sub ProposeCandidates
{
  my ($lastpos, $p, $flag, $REDB, $ESSENTIALS, $gmask) = @_;
  my $RES = $REDB->enzyme_definitions();
  my ($min, $max) = $flag ==  0
      ? ($p->{CHUNKLENMIN}, $p->{CHUNKLENMAX})
      : ($p->{CHUNKLENMIN}, $flag);
  my $rcpos = $lastpos - $min > 0 ?  $lastpos - $min  : 1;
  my $lcpos = $lastpos - $max > 0 ?  $lastpos - $max  : 1;
  my $lef = $lcpos - $p->{CHUNKLENMAX} > 0 ? $lcpos - $p->{CHUNKLENMAX} : 1;
  my $rig = $flag ? $flag + $lastpos : $lastpos;
  #print "\tCHECKING  lc $lcpos, rc $rcpos, lef $lef, rig $rig, last $lastpos, flag $flag, chunkolap ", $p->{CHUNKOLAP}, "\n";
  my @pool = @{$REDB->search(
    -left => $lef - $p->{CHUNKOLAP},
    -right => $rig + $p->{CHUNKOLAP},
  )};
  my @candidates = grep {$_->start >= $lcpos && $_->end <= $rcpos} @pool;
  my @finalists;
  my %rids = map {$_->id => 1} @candidates;
  my %memoi;
  my %memoe;
  foreach my $rid (keys %rids)
  {
    $memoi{$rid} = [] if (! exists $memoi{$rid});
    $memoe{$rid} = [] if (! exists $memoe{$rid});
    my @buds = grep {$_->id eq $rid} @pool;
    foreach my $bud (@buds)
    {
      my $presence = $bud->presence;
      if ($presence eq 'intergenic')
      {
        push @{$memoi{$rid}}, $bud;
      }
      elsif ($presence eq 'existing')
      {
        push @{$memoe{$rid}}, $bud;
      }
    }
  }
  foreach my $re (@candidates)
  {
    next if ($re->eligible);
    my $rstart = $re->start;
    my $rname  = $re->name;
    my $rid = $re->id;
    next if ($rid eq 'NmeAIII');
    my $size = $re->end - $rstart + 1;
    my $maskbit = $gmask->count_features_in_range($rstart - 1, $size);
    #Drop if exonic in exon overlap
    next if ($re->presence ne 'intergenic' && $maskbit > 1);
    my @ibuds = @{$memoi{$rid}};
    my @igenics = grep {abs($_->start - $rstart) <= $p->{CHUNKLENMAX} && $_->name ne $rname} @ibuds;
    #Drop if too many intergenics around
    next if (scalar @igenics);
    my $gene = $re->presence ne 'intergenic'  ? $re->featureid  : undef;
    my @ebuds = @{$memoe{$rid}};
    my @exonics = grep {abs($_->start - $rstart) <= $p->{CHUNKLENMAX} && $_->name ne $rname} @ebuds;
    my $ess_flag = $gene && $ESSENTIALS->{$gene} eq 'Essential'   ? 1 : 0;
    my $fgw_flag = $gene && $ESSENTIALS->{$gene} eq 'fast_growth' ? 1 : 0;
    my $lap_flag = 0;
    my @movers;
    foreach my $ex (@exonics)
    {
      next if ($ex->start > $rig + $p->{CHUNKOLAP});
      my $egene = $ex->featureid;
      my $emaskbit = $gmask->count_features_in_range($ex->start - 1, $size);
      $lap_flag++ if ($emaskbit > 1);
      last if $lap_flag;
      $ess_flag++ if ($ESSENTIALS->{$egene} eq 'Essential');
      $fgw_flag++ if ($ESSENTIALS->{$egene} eq 'fast_growth');
      push @movers, $ex->name;
    }
    #Drop if it requires modification in exon overlap
    next if ($lap_flag != 0);
    my $distance = abs($rstart - $lcpos);

    # Score is a function of distance from largest possible mark
    my $score = $distance <= 5000 ?  0  :  0.0008  * $distance - 4;
    # Plus the log of the price per unit
    $score   += log $RES->{$rid}->score;
    # Plus one tenth point for each orf modified
    $score   += 0.1 * scalar @movers;
    # Plus one half point for each fast growth orf modified
    $score   += 0.5 * $fgw_flag;
    # Plus one point for each essential orf modified
    $score   += 1.0 * $ess_flag;
    # Ignore if score is too high
    next if ($score > 1);
    $re->score($score);
    $re->movers(\@movers) if (scalar @movers);
    push @finalists, $re;
  }
  return \@finalists;
}

=head2 NextCandidate

=cut

sub NextCandidate
{
#my ($candlist, $usedhangref, $hangsurvey, $usedsiteref,
#                                $flag, $prevenz, $excisor, $omarker, $p) = @_;
  my ($REDB, $candlist, $usedhangref, $hangsurvey, $usedsiteref, $flag, $ch, $mch, $wtchr, $newchr, $altmask, $p) = @_;
  my $prevenz = $ch->prevcand;
  my $excisor = $mch->excisor;
  my $omarker = $mch->omarker;
  my $GD = $wtchr->GD();
  my $RES = $REDB->enzyme_definitions;
  my $foundcand = undef;
  while (! $foundcand && scalar @{$candlist})
  {
    my $candidate = shift @{$candlist};
    #my $enz = $candidate->id;
    next if (exists $usedsiteref->{$candidate->id});
    if ($flag)
    {
      my $ISSseq = $altmask->count_features_in_range($candidate->end, $p->{ISSMIN});
      if ($ISSseq > 0)
      {
        #print "\t\t\t\t discard: candidate $enz exists in an ISS inviable location...\n";
        next;
      }
      my $wtISSseq = wtISS($candidate->start, $candidate->start + $p->{ISSMIN}, $newchr, $wtchr);
      my $ihsh = $candidate->positions($wtISSseq);
      if (scalar(keys %{$ihsh}))
      {
        #print "\t\t\t\t discard: candidate $enz occurs in the targeting wildtype sequence...\n";
        next;
      }
      if ($p->{MARKER} && exists($omarker->static_enzymes->{$candidate->id}))
      {
        #print "\t\t\t\t discard: candidate $enz occurs in the intergenic region of the target marker...\n";
        next;
      }
    }
    my $enztype = $candidate->type;
    my %hanghsh = %{$candidate->overhangs};
    my @changs = keys %hanghsh;
    @changs = sort {$hangsurvey->{"$a.$enztype"} <=> $hangsurvey->{"$b.$enztype"}} @changs;
    @changs = grep { suitable_overhang( $GD, $usedhangref, $_, $enztype ) && $_} @changs;

    unless (scalar @changs)
    {
      #print "\t\t\t\t discard: candidate $enz has no suitable overhangs...\n";
      next;
    }
    my $hang = undef;
    if (! $prevenz || $candidate->presence eq 'intergenic')
    {
      $hang = $changs[0];
    }
    else
    {
      foreach my $phang (@changs)
      {
        my ($oldseq, $newseq) = NewSequence($newchr, $candidate, $phang);
        unless($newseq)
        {
          next;
        }
        my $oSTATUS = $GD->restriction_status(-sequence => $oldseq);
        my $nSTATUS = $GD->restriction_status(-sequence => $newseq);
        next if ($nSTATUS->{$prevenz->id} != $oSTATUS->{$prevenz->id} && $prevenz->id ne $candidate->id);
        next if ($nSTATUS->{$candidate->id} != 1);
        next if ($excisor && $nSTATUS->{$excisor->id} != 0);
        $hang = $phang;
        my @createds = grep {$nSTATUS->{$_} > $oSTATUS->{$_} && $_ ne $candidate->id} keys %{$RES};
        $candidate->creates(\@createds) if (scalar @createds);
        last;
      }
    }
    unless ($hang)
    {
      #print "\t\t\t\t discard: candidate $enz would introduce an untenable enzyme as a side effect...\n";
      next;
    }
    $candidate->phang($hang);
    my $gnah = $GD->rcomplement($hang);
    $usedhangref->{$hang} = {} unless (exists $usedhangref->{$hang});
    $usedhangref->{$gnah} = {} unless (exists $usedhangref->{$gnah});
    $usedhangref->{$hang}->{$enztype}++;
    $usedhangref->{$gnah}->{$enztype}++;
    $foundcand = $candidate;
  }
  return $foundcand ? $foundcand  : undef;
}

=head2 wtISS

=cut

sub wtISS
{
  my ($lef, $rig, $newchr, $wtchr) = @_;
  ($lef, $rig) = ($rig, $lef) if ($lef > $rig);
  my $size = abs($rig - $lef + 1);
  my @genes = $newchr->fetch_features(-type => 'gene');
  my @lefngenes = sort {abs($a->end - $lef) <=> abs($b->end - $lef)  } @genes;
  my @rigngenes = sort {abs($a->start - $rig) <=> abs($b->start - $rig)} @genes;
  my ($lefgene, $riggene) = ($lefngenes[0], $rigngenes[0]);

  my @wtlefgenes = $wtchr->fetch_features(
      -type => 'gene',
      -name => $lefgene->display_name
  );
  my @wtriggenes = $wtchr->fetch_features(
      -type => 'gene',
      -name => $riggene->display_name
  );
  my ($wtlefgene, $wtriggene) = ($wtlefgenes[0], $wtriggenes[0]);

  my $lefendoffset = $lefgene->end - $lef;
  my $rigstartoffset = $rig - $riggene->start;

  my $wtstart = $wtlefgene->end - $lefendoffset + 1;
  my $wtend   = $wtriggene->start + $rigstartoffset - 1;

  my $wtISS = lc substr $wtchr->sequence, $wtstart - 1, $wtend - $wtstart + 1;
  my $checkseq = substr $wtISS, $size / 2;

  return $checkseq;
}

=head2 suitable_overhang

=cut

sub suitable_overhang
{
  my ($GD, $used_overhangs_ref, $overhang, $type) = @_;
  return 0 if (! $overhang);
  my $gnahrevo = $GD->rcomplement($overhang);
  my %hsh = %{$used_overhangs_ref};
  return 0 if ( $overhang eq $gnahrevo );
  return 0 if ( exists $hsh{$overhang} && exists $hsh{$overhang}->{$type} );
  return 0 if ( exists $hsh{$gnahrevo} && exists $hsh{$gnahrevo}->{$type} );
  return 1;
}

=head2 NewSequence

=cut

sub NewSequence
{
  my ($newchr, $candidate, $ohang) = @_;
  my $GD = $newchr->GD();
  my $chrseq = $newchr->sequence();
  #print "\t\t\t determining what the chosen overhang for " . $candidate->id . " will look like in place...\n";
  my $start = $candidate->start;
  my $end = $candidate->end;
  my $strand = $candidate->strand;
  my $site = $candidate->recseq;
  my $cut = $candidate->cutseq;
  my ($lef, $rig) = (0, 0);
  ($lef, $rig) = ($1, $2) if ($cut =~ $candidate->class_regexes->{IIA});
  ($lef, $rig) = ($rig, $lef) if ($rig < $lef);
  $rig = 0 if ($rig < 0);
  my @CDSes = $newchr->fetch_features(-name => $candidate->featureid);
  my $CDS = $CDSes[0];
  my $offset = $candidate->offset || 0;
  if ($CDS->strand == -1)
  {
    $end ++ while (($CDS->end - $end) % 3 != 0);
    $start -- while (($end - $start + 1) /3  < length $candidate->peptide);
  }
  else
  {
    $start -- while (($start - $CDS->start) % 3 != 0);
    $end ++ while (($end - $start + 1) /3  < length $candidate->peptide);
  }
  my $testseq = substr $chrseq, $start - 1, $end - $start + 1;
  $testseq = $GD->rcomplement($testseq) if ($CDS->strand == -1);
  my $aa = $GD->translate(-sequence => $testseq);
  $site = $GD->rcomplement($site) if ($strand == -1);
  my $alnmat = $GD->pattern_aligner(
    -sequence => $testseq,
    -pattern => $site,
    -peptide => $aa
  );
  return (undef, undef) if (! $alnmat);
  unless ($candidate->type eq 'b')
  {
    substr($alnmat, $offset, length $ohang) = $ohang;
  }
  my $newpatt = $GD->pattern_adder(-sequence => $testseq, -pattern => $alnmat);
  $newpatt = $GD->rcomplement($newpatt) if ($CDS->strand == -1);
  $testseq = $GD->rcomplement($testseq) if ($CDS->strand == -1);
  my $pattlen = length $newpatt;
  my $contextlen = 60 + $pattlen;
  $start -=20;
  my $context = substr $chrseq, $start -1, $contextlen;
  my $oldtext = $context;
  substr($context, 20, $pattlen) = $newpatt;
  return ($oldtext, $context);
}

=head2 ProposeExcisors

  Given a position along the chromosome, nominates IIB sites

=cut

sub ProposeExcisors
{
  my ($lastpos, $mch, $REDB, $ESSENTIALS, $newchr, $wtchr, $gmask, $p) = @_;
  my $marker = $mch->omarker;
  my $RES = $REDB->enzyme_definitions();
  my @IIBs = grep {$RES->{$_}->class eq 'IIB'} keys %{$RES};
  if ($p->{MARKERS})
  {
    @IIBs  = grep {! exists($marker->static_enzymes->{$_})} @IIBs;
  }
  my %lookfors = map {$_ => 1} @IIBs;
  my $right = $lastpos + $p->{ISSMIN};
  my $left = $right - $p->{CHUNKLENMAX};
  my $rawgrab = $REDB->search( -left => $left, -right => $right );
  my @pool = grep {exists $lookfors{$_->id}} @{$rawgrab};
  my %igenics = map {$_->id => 1} grep {$_->presence eq 'intergenic'} @pool;
  @IIBs = grep {! exists $igenics{$_}} @IIBs;
  my $wtISS = wtISS($lastpos, $right, $newchr, $wtchr);
  my @finalists;
  foreach my $enz (@IIBs)
  {
    my $checkhsh = $RES->{$enz}->positions($wtISS);
    next if (scalar keys %{$checkhsh} != 0);
    my ($ess_flag, $fgw_flag, $lap_flag) = (0, 0, 0);
    my $size = $RES->{$enz}->len();
    my @movers;
    my @exonics = grep {$_->presence eq 'existing' && $_->id eq $enz} @pool;
    my @igenics = grep {$_->presence eq 'intergenic' && $_->id eq $enz} @pool;
    next if (scalar @igenics);
    foreach my $ex (@exonics)
    {
      my $egene = $ex->featureid;
      my $emaskbit = $gmask->count_features_in_range($ex->start - 1, $size);
      $lap_flag++ if ($emaskbit > 1);
      $ess_flag++ if ($ESSENTIALS->{$egene} eq 'Essential');
      $fgw_flag++ if ($ESSENTIALS->{$egene} eq 'fast_growth');
      push @movers, $ex->name;
    }
    next if ($lap_flag != 0);
    my $score = 0;
    $score   += log $RES->{$enz}->score;
    $score   += 0.1 * scalar @movers;
    $score   += 0.5 * $fgw_flag;
    $score   += 1.0 * $ess_flag;
    my $name = $p->{MARKERS}  ? $marker->name : 'ISS';
    my $newfeat = Bio::BioStudio::RestrictionEnzyme->new(
      -enzyme => $RES->{$enz},
      -name => $enz . q{_} . $name,
      -score => $score,
      -presence => 'a',
      -start => $right
    );
    $newfeat->movers(\@movers) if (scalar @movers);
    push @finalists, $newfeat;
  }
  return \@finalists;
}

=head2 removeEnzyme

=cut

sub removeEnzyme
{
  my ($newchr, $rfeat) = @_;
  my $GD = $newchr->GD();
  if ($rfeat->presence eq 'intergenic')
  {
    die 'WTF? ' . $rfeat->name . "? This is immutable...\n";
  }
  my $rfeatstart = $rfeat->start;
  my $rfeatend = $rfeat->end;
  my $rpeptide = $rfeat->peptide;
  my $rpeplen = length $rpeptide;
  my @remgenes = $newchr->fetch_features(
    -type => 'CDS',
    -name => $rfeat->featureid
  );
  my $rCDS = $remgenes[0];
  my $cstart = $rCDS->start;
  my $cend = $rCDS->end;
  my $corient = $rCDS->strand;
  my $genename = $rCDS->Tag_parent_id;
  if ($corient == -1)
  {
    $rfeatend++ while (($cend - $rfeatend) % 3 != 0);
    $rfeatstart-- while (($rfeatend - $rfeatstart + 1) / 3  < $rpeplen);
  }
  else
  {
    $rfeatstart-- while (($rfeatstart - $cstart) % 3 != 0);
    $rfeatend++ while (($rfeatend - $rfeatstart + 1) /3  < $rpeplen);
  }
  my $testseq = substr $newchr->sequence(), $rfeatstart - 1, $rfeatend - $rfeatstart + 1;
  $testseq = $GD->rcomplement($testseq) if ($corient == -1);
  
  my $newpatt = $GD->subtract_sequence(-sequence => $testseq, -remove => $rfeat);
  if ($newpatt eq $testseq)
  {
    #print "\tROHNOES ", $rfeat->name, " from $rCDS ($testseq to $newpatt)\n";
    return undef;
  }
  $newpatt = $GD->rcomplement($newpatt) if ($corient == -1);
  $testseq = $GD->rcomplement($testseq) if ($corient == -1);
  my $id = $rfeat->name . '_removed';
  my $csv = Bio::BioStudio::SeqFeature::CDSVariant->new(
    -start        => $rfeatstart,
    -end          => $rfeatend,
    -display_name => $id,
    -wtseq        => $testseq,
    -newseq       => $newpatt,
    -infeat       => $genename,
  );
  my $csvcomment = "coding_sequence_variant $id added";
  return $newchr->add_feature(-feature => $csv, -comments => [$csvcomment]);
}

=head2 addEnzyme

=cut

sub addEnzyme
{
  my ($newchr, $recsite) = @_;
  my $GD = $newchr->GD();
  my $RES = $GD->enzyme_set();
  my $start = $recsite->start;
  my $end = $recsite->end;
  my $strand = $recsite->strand;
  my $enz = $recsite->enzyme;
  my $enzyme = $RES->{$enz};
  my $site = $enzyme->recseq;
  my $cut = $enzyme->cutseq;
  my ($lef, $rig) = (0, 0);
  ($lef, $rig) = ($1, $2) if ($cut =~ $enzyme->class_regexes->{IIA});
  ($lef, $rig) = ($rig, $lef) if ($rig < $lef);
  $rig = 0 if ($rig < 0);
  my @ingenes = $newchr->fetch_features(
    -type => 'CDS',
    -name => $recsite->infeat(),
  );
  my $CDS = $ingenes[0];
  my $genename = $CDS->Tag_parent_id;
  my $peptide = $recsite->peptide();
  die ("can't find gene for $recsite from @ingenes!\n") unless $CDS;
  my $ohang = $recsite->ohang;
  my $offset = $recsite->ohangoffset || 0;
  if ($CDS->strand == -1)
  {
    $end ++ while (($CDS->end - $end) % 3 != 0);
    $start -- while (($end - $start + 1) /3  < length $peptide);
  }
  else
  {
    $start -- while (($start - $CDS->start) % 3 != 0);
    $end ++ while (($end - $start + 1) /3  < length $peptide);
  }
  my $testseq = substr $newchr->sequence(), $start - 1, $end - $start + 1;
  $testseq = $GD->rcomplement($testseq) if ($CDS->strand == -1);
  my $aa = $GD->translate($testseq);
  $site = $GD->rcomplement($site) if ($strand == -1);
  my $alnmat = $GD->pattern_aligner($testseq, $site, $aa);
  unless ($enzyme->type eq 'b')
  {
    substr $alnmat, $offset, length $ohang, $ohang;
  }
  my $newpatt = $GD->pattern_adder($testseq, $alnmat);
  $newpatt = $GD->rcomplement($newpatt) if ($CDS->strand == -1);
  $testseq = $GD->rcomplement($testseq) if ($CDS->strand == -1);
  $recsite->wtseq($testseq);
  $recsite->newseq($newpatt);
  $recsite->infeat($genename);
  $recsite->start($start);
  $recsite->end($end);
  my $id = $enz . q{_} . $start;
  $recsite->display_name($id);
  if (! $newpatt || $aa ne $peptide)
  {
    print "\tAdding $recsite to $CDS...\n";
    print "\tAOHNOES\t$enz w/ $peptide @ $start in $CDS\t($aa  ? $testseq ? ";
    print "$site) ($alnmat $newpatt $testseq)\n\n";
    return;
  }
  my $recsitecomment = "enzyme_recognition_site $id added";
  return $newchr->add_feature(-feature => $recsite, -comments => [$recsitecomment]);
}

=head2 annotateEnzyme

=cut

sub annotateEnzyme
{
  my ($newchr, $recsite) = @_;
  #print "Annotating $recsite...\n";
  my $GD = $newchr->GD();
  my $RES = $GD->enzyme_set();
  my $id = $recsite->display_name();
  my $enz = $recsite->enzyme;
  my $enzyme = $RES->{$enz};
  my $start = $recsite->start;
  my $end = $recsite->end;
  my $strand = $recsite->strand;
  my $site = $enzyme->recseq;
  my $sitelen = length $site;
  my $cut = $enzyme->cutseq;
  my ($lef, $rig) = (0, 0);
  ($lef, $rig) = ($1, $2)     if ($cut =~ $enzyme->class_regexes->{IIA});
  ($lef, $rig) = ($rig, $lef) if ($rig < $lef);
  $rig = 0 if ($rig < 0);
  if ($strand == 1)
  {
    $end = $start + $sitelen - 2;
  }
  elsif ($strand == -1)
  {
    $start = $start - $rig;
    $end = $start + $sitelen + $rig - 2;
  }
  $recsite->start($start);
  $recsite->end($end);
  my $recsitecomment = "enzyme_recognition_site $id annotated";
  return $newchr->add_feature(-feature => $recsite, -comments => [$recsitecomment]);
}

=head2 removeFromMarker

=cut

sub removeFromMarker
{
  my ($chr, $marker, $enzarr) = @_;
  my $GD = $chr->GD();
  my $RES = $GD->enzyme_set();
  my $mdb = $marker->db;
  my @mgenes = $mdb->features(-type => 'CDS');
  my @regions = $mdb->features(-type => 'region');
  my $markerseq = $regions[0]->seq->seq;
  my @enzymes = @{$enzarr};
  foreach my $gene (@mgenes)
  {
    my $gseq = $gene->seq->seq;
    my $aaseq = $GD->translate($gseq);
    foreach my $remsite (@enzymes)
    {
      my $enz = $RES->{$remsite};
      my $temphash = $enz->positions($gseq);
      foreach my $result (sort {$b <=> $a} keys %{$temphash})
      {
        my $framestart = $result % 3;
        my $startpos = $result - $framestart;
        my $seglen = (int( length($temphash->{$result}) / 3 + 2)) * 3;
        my $critseg = substr $gseq, $startpos, $seglen;
        my $newcritseg = $GD->subtract_sequence(
          -sequence => $critseg,
          -remove => $enz
        );
        substr $gseq, $startpos, $seglen, $newcritseg;
        die "OHNOES! bad trans\n" if ($aaseq ne $GD->translate($gseq));
      }
      my $nSITE_STATUS = $GD->restriction_status($gseq);
      die "\t\t\t\tOHNOES! bad remove\n" if ($nSITE_STATUS->{$remsite} != 0);
    }
    substr $markerseq, $gene->start - 1, $gene->end - $gene->start + 1, $gseq;
  }
  return $markerseq;
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
