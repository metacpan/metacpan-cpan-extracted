#!/usr/bin/perl

use Bio::BioStudio;
use Bio::BioStudio::RestrictionEnzyme::Seek qw(:BS);
use Bio::BioStudio::RestrictionEnzyme::Select qw(:BS);
use Getopt::Long;
use Pod::Usage;
use autodie qw(open close mkdir);
use English qw(-no_match_vars);
use POSIX;
use Carp;

use strict;
use warnings;

my $VERSION = '2.10';
my $bsversion = "BS_Segmenter_$VERSION";

local $OUTPUT_AUTOFLUSH = 1;

my %p;
GetOptions (
  'CHROMOSOME=s'     => \$p{CHROMOSOME},
  'EDITOR=s'         => \$p{EDITOR},
  'MEMO=s'           => \$p{MEMO},
  'OUTPUT=s'         => \$p{OUTPUT},
  'ENZYME_SET=s'     => \$p{ENZYME_SET},
  'MIN_CHUNK_SIZE=i' => \$p{CHUNKLENMIN},
  'MAX_CHUNK_SIZE=i' => \$p{CHUNKLENMAX},
  'WTCHR=s'          => \$p{WTCHR},
  'MARKERS=s'        => \$p{MARKERS},
  'LASTMARKER=s'     => \$p{LASTMARKER},
  'STARTPOS=i'       => \$p{STARTPOS},
  'STOPPOS=i'        => \$p{STOPPOS},
  'ISSMIN=i'         => \$p{ISSMIN},
  'ISSMAX=i'         => \$p{ISSMAX},
  'CHUNKNUM=i'       => \$p{CHUNKNUM},
  'CHUNKNUMMIN=i'    => \$p{CHUNKNUMMIN},
  'CHUNKNUMMAX=i'    => \$p{CHUNKNUMMAX},
  'CHUNKOLAP=i'      => \$p{CHUNKOLAP},
  'FPUTRPADDING=i'   => \$p{FPUTRPADDING},
  'TPUTRPADDING=i'   => \$p{TPUTRPADDING},
  'help'             => \$p{HELP}
);
if ($p{HELP})
{
  pod2usage(
    -verbose => 99,
    -sections=>'NAME|VERSION|DESCRIPTION|ARGUMENTS|USAGE'
  );
}
################################################################################
################################# SANITY CHECK #################################
################################################################################
my $BS = Bio::BioStudio->new();

if ($BS->SGE())
{
  require EnvironmentModules;
  import EnvironmentModules;
  module('load openmpi');
  module('load taskfarmermq/2.4');
  module('load biostudio');
  module('load blast+');
}

if (! $p{EDITOR} || ! $p{MEMO})
{
  die "BSERROR: Both an editor's id and a memo must be supplied.\n";
}
#Chromosome check
die "BSERROR: No chromosome was named.\n"  if (! $p{CHROMOSOME});
my $chr = $BS->set_chromosome(-chromosome => $p{CHROMOSOME});
my $chrlen = $chr->len();

die "BSERROR: No target chromosome was named.\n" if (! $p{WTCHR});
my $wtchr = $BS->set_chromosome(-chromosome => $p{WTCHR});

#Enzyme set check
$p{ENZYME_SET} = $p{ENZYME_SET} || 'nonpal_and_IIB';
$chr->GD->set_restriction_enzymes(-enzyme_set => $p{ENZYME_SET});
$wtchr->GD->set_restriction_enzymes(-enzyme_set => $p{ENZYME_SET});

$p{CHUNKLENMIN} = $p{CHUNKLENMIN} || 5000;     #|| 6000;
$p{CHUNKLENMAX} = $p{CHUNKLENMAX} || 10000;    #|| 9920;
die "BSERROR: The chunk length parameters do not parse.\n"
  if ($p{CHUNKLENMAX} < $p{CHUNKLENMIN});

$p{ISSMIN}       = $p{ISSMIN}       || 900;
$p{ISSMAX}       = $p{ISSMAX}       || 1500;
die "BSERROR: The ISS length parameters do not parse.\n"
  if ($p{ISSMAX} < $p{ISSMIN});

$p{STARTPOS}     = $p{STARTPOS}     || 1;
$p{STOPPOS}      = $p{STOPPOS}      || $chrlen;
die "BSERROR: The start and stop coordinates do not parse.\n"
  if ($p{STOPPOS} <= $p{STARTPOS});

die "BSERROR: No markers were named.\n" if (! $p{MARKERS});
my $BS_MARKERS = {};
$BS_MARKERS = $BS->custom_markers();
my %markers = map {$_ => -1} split q{,}, $p{MARKERS};
foreach my $marker (keys %markers)
{
  die "BSERROR: $marker not recognized as a marker.\n"
    if (! exists $BS_MARKERS->{$marker});
}
$p{MARKERHSH} = \%markers;
die "BSERROR: last marker $p{LASTMARKER} not recognized as a marker.\n"
  if ($p{LASTMARKER} && ! exists $BS_MARKERS->{$p{LASTMARKER}});

## Order the markers and determine which is the smallest
my ($markertally, $size, $smallest) = (0, undef, undef);
$p{MARKERORDER} = {};
if ($p{LASTMARKER} && exists $p{MARKERHSH}->{$p{LASTMARKER}})
{
  $p{MARKERHSH}->{$p{LASTMARKER}} = $markertally;
  $p{MARKERORDER}->{$markertally} = $p{LASTMARKER};
  $markertally++;
}
foreach my $marker (keys %{$p{MARKERHSH}})
{
  next if ($p{MARKERHSH}->{$marker} != -1);
  $p{MARKERORDER}->{$markertally} = $marker ;
  my $markersize = length $BS_MARKERS->{$marker}->sequence;
  $smallest = $marker if (! $size || $markersize < $size);
  $markertally++;
}
$p{SMALLESTMARKER} = $smallest;
$p{SMALLESTMARKERLEN} = length($BS_MARKERS->{$p{SMALLESTMARKER}}->sequence);
$p{MARKERCOUNT} = scalar keys %{$p{MARKERHSH}};

$p{CHUNKNUM}     = $p{CHUNKNUM}     || 4;
my $MAX_MEGA_CHUNK = $p{CHUNKNUM} * $p{CHUNKLENMAX};
my $MIN_MEGA_CHUNK = $p{CHUNKNUM} * $p{CHUNKLENMAX};
$p{CHUNKNUMMIN}  = $p{CHUNKNUMMIN}  || 3;
$p{CHUNKNUMMAX}  = $p{CHUNKNUMMAX}  || 5;
$p{CHUNKOLAP}    = $p{CHUNKOLAP}    || 40;
$p{FPUTRPADDING} = $p{FPUTRPADDING} || 500;
$p{TPUTRPADDING} = $p{TPUTRPADDING} || 100;
$p{OUTPUT} = 'txt' if (! $p{OUTPUT} || $p{OUTPUT} ne 'html');

################################################################################
################################# DATABASING  ##################################
################################################################################
my $RES = $chr->GD->set_restriction_enzymes(-enzyme_set => $p{ENZYME_SET});
my @ordlen = sort {$b->len <=> $a->len} values %{$RES};
my $pad = $ordlen[0]->len;

## find genes, find intergenic regions
## Load the database for the original chromosome
my @exons = $chr->fetch_features(-type => 'CDS');
my @igens = $chr->make_intergenic_features();
push @igens, $chr->fetch_features(-type => 'intron');
foreach my $igen (@igens)
{
  my $fstart = $igen->start - $pad;
  $fstart = 1 if ($fstart < 0);
  my $fend = $igen->end + $pad;
  $fend = $chrlen if ($fend > $chrlen);
  if ($igen->display_name =~ 'igenic_')
  {
    my $newname = 'igenic_' . $fstart . q{-} . $fend;
    $igen->display_name($newname);
  }
  $igen->start($fstart);
  $igen->end($fend);
}
my @features = ();
push @features, @exons, @igens;

my %ESSENTIALS;
foreach my $exon (@exons)
{
  my $status = $exon->Tag_essential_status || 'Nonessential';
  $ESSENTIALS{$exon->display_name} = $status;
}
my $redbname = $chr->name() . '_RED';

print "SCANNING...\n";
my $REDB = $BS->SGE
  ? farm_search($chr, \@features, \%p)
  : serial_search($chr, \@features, \%p);

print "FILTERING...\n";
my ($drcount, $igcount) = $BS->SGE
  ? farm_filter($chr, $REDB, \%p)
  : serial_filter($chr, $REDB, \%p);
print "\tscreened $drcount culls, $igcount ignores\n";

#my $REDB = Bio::BioStudio::RestrictionEnzyme::Store->new(
#  -name               => $redbname,
#  -enzyme_definitions => $RES
#);

################################################################################
############################ CONFIGURING SELECTION #############################
################################################################################
my $newchr = $chr->iterate(-chrver => 1);
$newchr->GD->set_restriction_enzymes(-enzyme_set => $p{ENZYME_SET});
my $GD = $newchr->GD();

## Gather genes and check for essentiality.  Mask the UTRs of essential
## and fast growth genes by modifying their start and stop sites.
## Find the right telomere and make the junction just before it
my @UTCS = $newchr->fetch_features(-type => qw(telmomere UTC));
@UTCS = sort {$b->start <=> $a->start} @UTCS;
my $rutc = $UTCS[0];
my $chrend = scalar @UTCS ? $rutc->start - 1 : $chrlen;

my @genes = $newchr->fetch_features(-type => 'gene');
my $gmask = $newchr->type_mask('gene');

my @efgenes = ();
foreach my $gene (@genes)
{
  my $status = $gene->has_tag('essential_status')
    ? $gene->Tag_essential_status
    : 'Nonessential';
  if ($status ne 'Nonessential')
  {
    my $newstart = $gene->strand == 1
        ? $gene->start - $p{FPUTRPADDING}
        : $gene->start - $p{TPUTRPADDING};
    $newstart = 1 if ($newstart < 1);
    $gene->start($newstart);
    my $newstop = $gene->strand == 1
        ? $gene->stop + $p{TPUTRPADDING}
        : $gene->stop + $p{FPUTRPADDING};
    $newstop = $chrend if ($newstop > $chrend);
    $gene->stop($newstop);
    push @efgenes, $gene;
  }
}

# Mask the regions that are not viable ISS locations:  Essential / Fast-Growth
#   genes, regions smaller than the smallest possible ISS site,
#   and regions with no non-essential genes in them
my $altmask = $newchr->empty_mask();
$altmask->add_to_mask(\@efgenes);
my @intergenics = @{$altmask->find_deserts()};
foreach my $range (@intergenics)
{
  my ($start, $end) = ($range->start, $range->end);
  if ($end - $start < $p{ISSMIN})
  {
    my $newfeat = Bio::SeqFeature::Generic->new(
      -start        => $start,
      -end          => $end,
      -display_name => "no_ISS_$start",
      -primary_tag  => 'forbid'
    );
    $altmask->add_to_mask([$newfeat]);
  }
}
my @ess = sort {(abs $b->start - $b->end) <=> (abs $a->start - $a->end)}
  @{$altmask->find_deserts()};

#fbound and tbound are the 5' and 3' bounds of segmentation, where we start and
# stop. default is the first and last base of the chromosome, respectively.
# lastpos is where we actually start counting from.
my $tbound = $p{STOPPOS} ? $p{STOPPOS} : $chrend;
$tbound = $chrend if ($tbound > $chrend);
my $lastpos = $tbound;
my $fbound = $p{STARTPOS} + ($p{CHUNKLENMAX} - (0.5 * $p{ISSMIN}));
$lastpos = $p{LASTMARKER}
  ? $tbound + length $BS_MARKERS->{$p{LASTMARKER}}->sequence
  : $tbound + length $BS_MARKERS->{$p{MARKERORDER}->{0}}->sequence;
$fbound = $fbound - $p{SMALLESTMARKERLEN};

my $markercount = 0;
my $firstmarker = 0;
my $foundcand = undef;
my $doISS = 0;
my $mchrollback = 0;
my $redomch = undef;
my $excisor = undef;
my $lastISSseq = undef;
my %usedsites;
my %deadends;

################################################################################
################################## SELECTING ###################################
################################################################################
print "SEGMENTING...\n";
my @mchs;

while (! $lastpos || ($lastpos - $fbound) >= $p{CHUNKLENMIN} * 2)
{
  my $mch = $redomch || Bio::BioStudio::Megachunk->new();
  $lastpos = $mch->end || $lastpos;

  $mch->excisor($excisor) if (! $mch->excisor);

  #decide where the start and stop of this megachunk will be.
  # frange and trange are the 5' and 3' boundaries of the megachunk.
  my $frange = $lastpos - $MAX_MEGA_CHUNK >= $fbound
    ? $lastpos - $MAX_MEGA_CHUNK
    : $fbound;
  $mch->frange($frange);
  $mch->trange($lastpos - $MIN_MEGA_CHUNK);

  #eligible regions have no masking - that is, no essential or fast growth genes
  # sort by distance from the last position and choose a start inside frange
  if (! $mch->start)
  {
    my @eligibles = grep { $_ >= $mch->frange && $_ <= $mch->trange}
                    sort {(abs $b - $lastpos) <=> (abs $a - $lastpos)} @ess;
    my $mchstart  = $eligibles[0] || $mch->frange;
    $mchstart = $fbound if ($lastpos < $MIN_MEGA_CHUNK);
    $mch->start($mchstart);
    $mch->end($lastpos);
  }

  #pick a marker for the megachunk and decide which marker will be next.
  # If lastmarker is specified but not in the marker group, take care
  $markercount = $mch->markercount || $markercount;
  if (! $mch->marker)
  {
    $mch->markercount($markercount);
    $mch->firstmarker($firstmarker);
    my ($markername, $omarkername);
    if ($p{LASTMARKER} && $firstmarker == 0
      && (! exists $p{MARKERHSH}->{$p{LASTMARKER}}))
    {
      $markername = $p{LASTMARKER};
      $omarkername = $p{MARKERORDER}->{$markercount};
      ($firstmarker, $markercount) = (1, 0);
    }
    else
    {
      $markername = $p{MARKERORDER}->{$markercount % $p{MARKERCOUNT}};
      $omarkername = $p{MARKERORDER}->{($markercount+1) % $p{MARKERCOUNT}};
    }
    $mch->marker($BS_MARKERS->{$markername});
    $mch->omarker($BS_MARKERS->{$omarkername});
  }

  #If there was a previous megachunk, its 5' enzyme becomes the 3' enzyme of
  # this megachunk. Mark it, its exclusions, and its creations, as used
  my @borders = ();
  if (! $mch->prevenz && $foundcand)
  {
    %usedsites = ();
    $mch->prevenz($foundcand);
    push @borders, $foundcand;
    %usedsites = ($foundcand->id => 1);
    $usedsites{$_}++ foreach (@{$RES->{$foundcand->id}->exclude});
    if ($foundcand->creates)
    {
      $usedsites{$_}++ foreach (@{$foundcand->creates});
    }
  }

  my $mchlen = $mch->end - $mch->start + 1;
print 'Making a megachunk ' . $mch->start . q{..} . $mch->end . " ~$mchlen bp ";
print "with $markercount " . $mch->marker->name . "\n";

  $mch->chunks([]) if (! $mch->chunks);
  my %usedhangs = ();
  my $chunknum = $mch->chunknum || 1;
  my $firsterr = 0;
  my $redoch = $mchrollback ? pop @{$mch->chunks} : undef;

  #Start to make chunks.
  while (abs($lastpos - $mch->start) > $p{CHUNKLENMIN} || $chunknum <= $p{CHUNKNUMMAX})
  {
    my $ch = $redoch || Bio::BioStudio::Chunk->new();
    $ch->number($chunknum);

    $ch->prevcand($foundcand) if (! $ch->prevcand);
    $lastpos = $ch->prevcand ? $ch->prevcand->end  : $lastpos;
    $mch->lastlastpos($lastpos);

    #Keep track of which overhangs and which sites are off limits
    my %tempsites = %usedsites;
    my %temphangs = %usedhangs;
    $ch->used_enzymes(\%tempsites) if (! $ch->used_enzymes);
    $ch->used_overhangs(\%temphangs) if (! $ch->used_overhangs);

    #
    my $issflag = $doISS;
    $issflag++ if ($chunknum == $p{CHUNKNUM} && $firsterr == 0)
                || $chunknum == $p{CHUNKNUMMAX};
    $issflag-- if ($mch->start <= $fbound);

    #Get the list of viable candidates for enzyme border
    # If this is the first (3' most) chunk, allow for the ISS sequence
    my $isslen = $chunknum == 1
          ? $p{CHUNKLENMAX} - (0.5 * $p{ISSMIN})
          : 0;
    $isslen -= length($mch->marker->sequence) if ($chunknum == 1);

    #Create the candidate list
    my @candlist;
    if (! $ch->enzlist)
    {
      my $candlistref = ProposeCandidates($lastpos, \%p, $isslen, $REDB, \%ESSENTIALS, $gmask);

      #Filter candidates by position and sort by score, with lower scores first.
      # If this is the 3' most chunk of the megachunk, don't pick REs that can't
      # be removed from the marker. If an ISS sequence is 3' of the chunk, don't
      # pick REs that are present in the wildtype sequence of the ISS sequence.
      @candlist = @{$candlistref};
      @candlist = grep {abs($_->start - $lastpos) >= $p{CHUNKLENMIN}} @candlist;
      @candlist = grep {abs($_->end   - $lastpos) <= $p{CHUNKLENMAX}} @candlist;
      @candlist = grep {$_->start > $mch->start} @candlist;
      @candlist = sort {$a->score <=> $b->score} @candlist;
      if ($chunknum == 1)
      {
        @candlist = grep {! exists($mch->marker->static_enzymes->{$_->id})} @candlist;
        if ($lastISSseq)
        {
          my $ihsh = $GD->restriction_status(-sequence => $lastISSseq);
          @candlist = grep {$ihsh->{$_->id} == 0} @candlist;
        }
      }
      my @cutlist = @candlist;
      $ch->bkupenzlist(\@cutlist);
    }
    else
    {
      @candlist = @{$ch->enzlist};
    }

    #Take a survey of how often overhang sequences appear among candidates
    # We will want to use overhangs that appear the least first
    my %ohangsurvey;
    foreach my $cand (@candlist)
    {
      my $enztype = $cand->type;
      $ohangsurvey{"$_.$enztype"}++ foreach (keys %{$cand->overhangs});
    }

    my @nonos = keys %{$ch->used_enzymes};
    my @nohgs = keys %{$ch->used_overhangs};
print "\t ch $chunknum \t", scalar @candlist, " possibilities\tflag $issflag";
print "\t firsterr $firsterr \t nonos: @nonos / @nohgs";
print "\t(" . $ch->prevcand->id . " @ $lastpos)" if ($ch->prevcand);
print "\n";

    #Pick a candidate
    %usedhangs = %{$ch->used_overhangs};
    %usedsites = %{$ch->used_enzymes};
    $foundcand = NextCandidate($REDB, \@candlist, \%usedhangs, \%ohangsurvey,
              \%usedsites, $issflag, $ch, $mch, $wtchr, $newchr, $altmask, \%p);

    #If no candidate can be picked, we will either have to move forward or back
    if (! $foundcand)
    {
      #if we've at least made the minimum number of chunks and this is the first
      # BSERROR, we will try relaxing the standards and moving up.
      if ($chunknum >= $p{CHUNKNUMMIN} && $firsterr == 0)
      {
        $firsterr++;
        $ch->enzlist($ch->bkupenzlist);
        $redoch = $ch;
        next;
      }
      #Otherwise, we need to reduce the number of possible chunks and rechoose.
      # we will restore a previous candidate and its workspace
      elsif ($chunknum > 1)
      {
        $redoch = pop @{$mch->chunks};
        $chunknum--;
        next;
      }
      #If we've backed all the way up to chunk 1, we need to redo the previous
      # megachunk entirely.
      elsif ($chunknum == 1)
      {
         last;
      }
      else
      {
        die "sorry, boss - ran into a hole!\n\n";
      }
    }
    $ch->enzlist(\@candlist);
    $ch->enzyme($foundcand);
    if (exists $deadends{$foundcand->name} && $deadends{$foundcand->name} == $chunknum)
    {
      print 'Been down this road... ';
      last;
    }
    if ($chunknum == 1 && ! $redoch)
    {
      $mch->firstchunk($foundcand) if (! $mch->firstchunk);
    }

##DEBUG UPDATE
print "\t  picked ", $foundcand->name, q{ };
print $foundcand->phang, q{ }, $foundcand->score;
    my @mustmovers = ();
    @mustmovers = @{$foundcand->movers} if $foundcand->movers;
print " (@mustmovers)" if $foundcand->movers;
print "\n";

    #Finish picking.  Reset used sites, push the candidate onto the stack.
    push @{$mch->chunks}, $ch;
    $redoch = undef;
    %usedsites = ();
    $usedsites{$_}++ foreach (@{$foundcand->exclude});
    if ($foundcand->creates)
    {
      $usedsites{$_}++ foreach (@{$foundcand->creates});
    }
    $lastpos = $foundcand->end;
    last if $chunknum == $p{CHUNKNUM} && $firsterr == 0;
    last if $chunknum == $p{CHUNKNUMMAX};
    last if ($lastpos < $p{CHUNKLENMIN});
    $chunknum++;
  #End chunk picking
  }

  #If fewer chunks are picked than allowed, we have to redo the whole megachunk.
  if ($chunknum < $p{CHUNKNUMMIN} && $lastpos > $p{CHUNKLENMIN})
  {
    $mchrollback = 1;
    $deadends{$mch->firstchunk->name} = 1 if ($mch->firstchunk);
    $redomch = pop @mchs;
    $redomch->pexcisor(undef);
    next;
  }
  if (! $mch->pexcisor && $lastpos > $p{CHUNKLENMIN})
  {
    my $rtest = $altmask->count_features_in_range($lastpos, $p{ISSMIN});
    die "wtf\n\n$rtest\n\n" if ($rtest > 0);
    my $plist = ProposeExcisors($lastpos, $mch, $REDB, \%ESSENTIALS, $newchr,
                                                           $wtchr, $gmask, \%p);
    my @partnerlist = sort {$a->score <=> $b->score} @{$plist};
    $excisor = $partnerlist[0];
    die 'cannot find IIB site!!!' if (! $excisor);
    my $rISSbound = $lastpos + $p{ISSMIN};
print "\t next excisor should be ", $excisor->id, q{ };
print $excisor->start, q{ }, $excisor->score, " @ $rISSbound\n";
    $lastISSseq = wtISS($lastpos, $excisor->start, $newchr, $wtchr);
    $lastpos = $excisor->start;
    $mch->pexcisor($excisor);
  }
  push @mchs, $mch;
  $redomch = undef;
  $mchrollback = 0;
  $markercount++;
  print "\n";
#End megachunk picking
}

################################################################################
################################### EDITING ####################################
################################################################################
print "COMMITTING...\n";
my $letter = 'A';
@mchs = reverse @mchs;
my @list = $newchr->db->get_features_by_type('enzyme_recognition_site');
my %saves = map {$_->display_name => 1} @list;
my $lastchunkname = undef;
my $z = 0;
my %chunkindex = ();
foreach my $mch (@mchs)
{
  $z++;
  my $megachunkname = $newchr->name() . q{.} . $letter;
  my @chlist = @{$mch->chunks};
  my @enzlist = sort {$a->start <=> $b->start} map {$_->enzyme} @chlist;
  my $chosenexcisor = $mch->excisor || undef;
  my $excisorid = $mch->excisor ? $chosenexcisor->id  : undef;
  my $mcstart = $letter eq 'A'  ? 1 : $enzlist[0]->start;
  my $mcend = $chosenexcisor ? $chosenexcisor->start : $tbound;
print $megachunkname, q{ (}, $mcstart, q{..}, $mcend, q{) }, $mch->marker->name;
print q{ }, $chosenexcisor->id, q{ }, $chosenexcisor->start if ($chosenexcisor);
print "\n";

  my $chlim = scalar @enzlist;
  $chlim++ if ($letter eq 'A');
  my @chunks;

  my ($cstart, $cend) = ($mcstart, $enzlist[1]->end);
  #
  # Commit the enzymes
  my $ecount = 0;
  foreach my $recsite (@enzlist)
  {
    $ecount++;
    my $enzname = $recsite->name;
    $saves{$enzname}++;
    my $e = Bio::BioStudio::SeqFeature::RestrictionSite->new(
      -start        => $recsite->start,
      -end          => $recsite->end,
      -score        => sprintf('%.3f', $recsite->score),
      -display_name => $enzname,
      -strand       => $recsite->strand,
      -presence     => $recsite->presence,
      -infeat       => $recsite->featureid,
      -enzyme       => $recsite->id,
      -ohang        => $recsite->phang,
      -peptide      => $recsite->peptide,
      -ohangoffset  => $recsite->offset,
      -megachunk    => $megachunkname,
    );

    my $chunkname = $megachunkname . $ecount;
    my $nchunkname = $megachunkname . ($ecount + 1);

    if ($z == 1 && $ecount == 1)
    {
      $e->chunks([$chunkname, $nchunkname]);
      push @{$chunkindex{$chunkname}}, $e;
      push @{$chunkindex{$nchunkname}}, $e;
      $lastchunkname = $nchunkname;
    }
    elsif ($z > 1 && $ecount == 1)
    {
      $e->chunks([$lastchunkname, $chunkname]);
      push @{$chunkindex{$chunkname}}, $e;
      push @{$chunkindex{$lastchunkname}}, $e;
      $lastchunkname = $chunkname;
    }
    elsif ($z == 1)
    {
      $e->chunks([$chunkname, $nchunkname]);
      push @{$chunkindex{$chunkname}}, $e;
      push @{$chunkindex{$nchunkname}}, $e;
      $lastchunkname = $nchunkname;
    }
    else
    {
      $e->chunks([$lastchunkname, $chunkname]);
      push @{$chunkindex{$chunkname}}, $e;
      push @{$chunkindex{$lastchunkname}}, $e;
      $lastchunkname = $chunkname;
    }
    if ($recsite->movers)
    {
      foreach my $recname (@{$recsite->movers})
      {
        my @recobjs = @{$REDB->search(-name => $recname)};
        my $recobj = $recobjs[0];
        next if (exists $saves{$recobj->name});
        removeEnzyme($newchr, $recobj);
      }
    }
    if ($recsite->presence ne 'intergenic')
    {
      $e = addEnzyme($newchr, $e);
    }
    else
    {
      $e = annotateEnzyme($newchr, $e);
    }
  }

  #
  # Commit the chunks
  my $chunknum = 0;
  my $lastenz = undef;
  while ($chunknum < $chlim)
  {
    $chunknum++;
    my $chunkname = $megachunkname . $chunknum;
    my @enzymes = @{$chunkindex{$chunkname}};
    my $lefenz = $enzymes[0];
    my $rigenz = $enzymes[-1];
    my $edgeflag = $lefenz->name eq $rigenz->name ? 1 : 0;
    if ($chunknum == 1 && $z == 1 && $edgeflag)
    {
      $cstart = $mcstart;
      my $difference = $p{CHUNKOLAP} - ($rigenz->end - $rigenz->start + 1);
      $cend = $rigenz->end + ceil($difference / 2);
    }
    elsif ($edgeflag)
    {
      my $difference = $p{CHUNKOLAP} - ($rigenz->end - $rigenz->start + 1);
      $cstart = $rigenz->start - ceil($difference / 2);
      $cend = $mcend;
    }
    else
    {
      my $sdifference = $p{CHUNKOLAP} - ($lefenz->end - $lefenz->start + 1);
      $cstart = $lefenz->start - ceil($sdifference / 2);
      my $edifference = $p{CHUNKOLAP} - ($rigenz->end - $rigenz->start + 1);
      $cend = $rigenz->end + ceil($edifference / 2);
    }
    $lastenz = $rigenz;
    my $c = Bio::BioStudio::SeqFeature::Chunk->new(
      -start        => $cstart,
      -end          => $cend,
      -display_name => $chunkname,
      -megachunk    => $megachunkname,
      #-enzymes      => \@benzes,
    );
    print "\t Made $chunkname: $cstart .. $cend\n";
    my $ccomment = "chunk $chunkname annotated";
    push @chunks, $newchr->add_feature(-feature => $c, -comments => [$ccomment]);
  }

  #
  #Ditch the excisor's movables
  if ($chosenexcisor)
  {
    my $blist = $REDB->search(
      -enzyme => $chosenexcisor->id,
      -left   => $chunks[-1]->start,
      -right  => $chunks[-1]->end
    );
    foreach my $brem (@{$blist})
    {
      removeEnzyme($newchr, $brem);
    }
  }

  #
  # Commit the megachunk
  my $d = Bio::BioStudio::SeqFeature::Megachunk->new(
    -start        => $chunks[0]->start,
    -end          => $chunks[-1]->end,
    -display_name => $megachunkname,
    -marker       => $mch->marker->name,
    -excisor      => $excisorid,
  );
  my $dcomment = "megachunk $megachunkname annotated";
  $newchr->add_feature(-feature => $d, -comments => [$dcomment]);
  $letter++;
  $letter = (substr $letter, -1) x (length $letter) if (length $letter > 1);
  print "\n\n";
}

################################################################################
############################### ERROR  CHECKING ################################
################################################################################
print "PROOFREADING...\n";
my $y = 0;
my @mchunklist = $newchr->db->get_features_by_type('megachunk');

my $chrseq = $newchr->sequence();

foreach my $megachunk (@mchunklist)
{
  $y++;
  my $mchname = $megachunk->display_name;
  my $excisorname = $megachunk->Tag_excisor;
  my @chunks = $newchr->db->features(
    -seq_id     => $newchr->seq_id(),
    -type       => 'chunk',
    -attributes => {'megachunk' => $mchname}
  );

  @chunks = sort {$a->start <=> $b->start} @chunks;
  my $chunknum = scalar @chunks;
  my $chunkcount = 0;
  foreach my $chunk (@chunks)
  {
    $chunkcount++;
    my $chname = $chunk->display_name;
    my @res = @{$chunkindex{$chname}};
    @res = map {$_->Tag_enzyme} @res;
    my $chunkseq = $newchr->current_sequence($chunk);
    my %realcount = ();
    $realcount{$_}++ foreach (@res);
    $realcount{$excisorname} = 0 if ($excisorname && $chunkcount == $chunknum);
    my %seens;
    foreach my $enz (keys %realcount)
    {
      next if (exists $seens{$enz});
      my @positions = keys %{$RES->{$enz}->positions($chunkseq)};
      if (scalar @positions != $realcount{$enz})
      {
        print "\tPOHNO $enz is not happening the right number of times in $chname\n";
      }
      $seens{$enz}++;
    }
  }
}

my @checkgenes = $newchr->db->features(
  -seq_id     => $newchr->seq_id,
  -types      => 'CDS',
);
foreach my $gene (@checkgenes)
{
  my $cdna = $chr->make_cDNA($gene);
	my $newcdna = $newchr->make_cDNA($gene);
  my $newpep = $GD->translate(-sequence => $newcdna);
  my $oldpep = $GD->translate(-sequence => $cdna);
  if ($newpep ne $oldpep)
  {
    my $gname = $gene->display_name;
    print "\tUHOH: $gname", 'Change in amino acid sequence;';
  }
}

#Tell chromosome to write itself
$newchr->add_reason($p{EDITOR}, $p{MEMO});
$newchr->write_chromosome();


################################################################################
################################## REPORTING ###################################
################################################################################
print "CARVING...\n";
our %BASES = map {$_ => 1} qw(A T C G);

our %NTIDES = (
  A => [qw(A)],     T => [qw(T)],     C => [qw(C)],     G => [qw(G)],
  R => [qw(A G)],   Y => [qw(C T)],   W => [qw(A T)],   S => [qw(C G)],
  K => [qw(G T)],   M => [qw(A C)],   B => [qw(C G T)], D => [qw(A G T)],
  H => [qw(A C T)], V => [qw(A C G)], N => [qw(A C G T)],
);
my $ASSEMBLYDIR = $newchr->path_in_repo() . $newchr->name . '_assemble/';
mkdir $ASSEMBLYDIR if (! -e $ASSEMBLYDIR);
my $MEGACHUNKDIR = $ASSEMBLYDIR . 'MEGACHUNKS/';
mkdir $MEGACHUNKDIR if (! -e $MEGACHUNKDIR);
my $CHUNKDIR   = $ASSEMBLYDIR . 'CHUNKS/';
mkdir $CHUNKDIR if (! -e $CHUNKDIR);
@genes = $newchr->fetch_features(-type => 'gene');
my $wtseq = $wtchr->sequence();
my @megachunklist = $newchr->db->get_features_by_type('megachunk');
my $mchunknum = scalar @megachunklist;
my $ze = 0;
my %skiptypes = map {$_ => 1} qw(chromosome megachunk chunk);
foreach my $megachunk (@megachunklist)
{
  $ze++;
  #
  #Print out megachunk and its overlapping features as genbank
  my $mchname = $megachunk->display_name;
  my $marker = $megachunk->Tag_marker;
  my $excisorid = $megachunk->Tag_excisor;
  my $mchobj = $newchr->genbank_feature(
    -feature => $megachunk,
    -skip_features => \%skiptypes,
    -ape_color => {'enzyme_recognition_site' => '#CC0000'},
  );
  my $mchpath = $MEGACHUNKDIR . $mchname . '.genbank';
  my $mapeout = Bio::SeqIO->new(-file => ">$mchpath", -format => 'genbank');
  $mapeout->write_seq($mchobj);

  print "Adding $marker to $mchname\n";
  #
  #Print out chunks and their overlapping features as genbank
  my @chunks = $newchr->db->features(
    -seq_id     => $newchr->seq_id(),
    -type       => 'chunk',
    -attribute  => {'megachunk' => $mchname}
  );
  @chunks = sort {$a->start <=> $b->start} @chunks;
  my $chunknum = scalar @chunks;
  my $chunkcount = 0;
  foreach my $chunk (@chunks)
  {
    $chunkcount++;
    my $flag = $chunkcount == $chunknum ? 1 : 0;
    my $chname = $chunk->display_name;
    my $chseq = $chunk->seq->seq;
    my $chstart = $chunk->start;
    my $chend   = $chunk->end;
    my $comment = "$chname from ";
    my @addfeatures = ();
    my %apeenzlist;
    my @res = $newchr->db->features(
      -seq_id     => $newchr->seq_id(),
      -type       => 'enzyme_recognition_site',
      -attribute  => {'chunks' => $chname}
    );
    @res = sort {$a->start <=> $b->start} @res;
    my ($lefre, $rigre) = ($res[0], $res[-1]);
    my $lzname = $lefre->Tag_enzyme;
    my $rzname = $rigre->Tag_enzyme;
    my $lefcom = ($chunkcount == 1 && $ze == 1) ? "the 5' telomere" : $lzname;
    my $rigcom = ($excisorid && $flag == 1) ? "to  $excisorid" : "to $rzname";
    my $chunklen = length $chseq;

    if ($flag != 1)
    {
      #A normal chunk, nothing fancy
      $comment .= "$chname from $lefcom $rigcom; $chunklen bp from ";
      $comment .= $chstart . q{..} . $chend;
      $apeenzlist{$lzname}++ if ($lefre ne $rigre);
      $apeenzlist{$rzname}++;
    }
    elsif ($flag == 1 && $ze != $mchunknum)
    {
      #We're going to add a marker to the end of this chunk
      # Make sure to remove the appropriate enzymes from marker sequence
      my @ores = $newchr->db->features(
        -seqid      => $newchr->seq_id(),
        -types      => 'enzyme_recognition_site',
        -start      => $megachunk->end - 2000,
        -end        => $megachunk->end,
        -range_type => 'contains',
      );
      die "oops, wrong number of midres, @ores\n" if (scalar @ores != 1);
      my $midre = $ores[0];
      my $midname = $midre->Tag_enzyme;
      my $midenz = join q{}, $midre->get_tag_values('enzyme');
      my %remhsh = map {$_ => 1} ($rzname, $lzname, $midenz);
      my @rems = keys %remhsh;
      print "\t\tRemoving @rems from marker $marker\n";
      my $realmarker = $BS_MARKERS->{$marker};
      my $markerregion = removeFromMarker($newchr, $realmarker, \@rems);

      ##Figure out where the ISS sequence is in the wild type chromosome
      my @midngenes = sort {(abs $a->end - $midre->start) <=> (abs $b->end - $midre->start)  } @genes;
      my @rigngenes = sort {(abs $a->start - $megachunk->end) <=> (abs $b->start - $megachunk->end)} @genes;
      my ($midgene, $riggene) = ($midngenes[0], $rigngenes[0]);
      my @wtmidgenes = $wtchr->db->features(
          -type   => 'gene',
          -name   => $midgene->display_name
      );
      my @wtriggenes = $wtchr->db->features(
          -type   => 'gene',
          -name   => $riggene->display_name
      );
      my $wtmidgene = $wtmidgenes[0];
      my $wtriggene = $wtriggenes[0];
      my $midendoffset = $midgene->end - $midre->end;
      my $rigstartoffset = $megachunk->end - $riggene->start;

      #Figure out how much wt to pad the IIB site with
      my $rigcut = $RES->{$excisorid}->cutseq;
      my $rigsite = $RES->{$excisorid}->recseq;
      my $lenrigclean = length $rigsite;
      my ($wlef, $clef, $wrig, $crig) = ($1, $2, $3, $4) if ($rigcut =~ $RES->{$excisorid}->class_regexes->{IIB});
      ($wlef, $clef) = ($clef, $wlef) if ($wlef < $clef);
      ($wrig, $crig) = ($crig, $wrig) if ($wrig < $crig);
      ($wlef, $wrig) = ($wlef + 5, $wrig + 5);
      my $wtextension = $wlef + $lenrigclean + $wrig;

      my $wtstart = $wtmidgene->end - $midendoffset + 1;
      my $wtend = $wtriggene->start + $rigstartoffset - 1;
      $wtend += $wtextension;
      my $synstart = $midre->end + 1;
      my $synend = $megachunk->end -1;
      my $synsize = $synend - $synstart + 1;
      my $wtISS = substr $wtseq, $wtstart - 1, $wtend - $wtstart + 1;
      my $wtcopy = $wtISS;
      substr $wtcopy, -($wrig + $lenrigclean), $lenrigclean, $rigsite;
      for my $x ((length $wtcopy) - ($wrig + $lenrigclean) .. (length $wtcopy) - ($wrig + 1))
      {
        my $wtb = substr $wtISS, $x, 1;
        my $reb = substr $wtcopy, $x, 1;
        if ($wtb eq $reb || $wtb =~ $GD->regex_nt(-sequence => $reb))
        {
          substr $wtcopy, $x, 1, $wtb;
        }
        else
        {
          my @choices = @{$NTIDES{$reb}};
          substr $wtcopy, $x, 1, $choices[0];
        }
      }
      $wtISS = $wtcopy;
      $wtISS = lc $wtISS;
      my $synISS = lc substr $chrseq, $synstart-1, $synend - $synstart + 1;
      my $preseq = substr $chrseq, $chstart - 1, $synstart - $chstart;

      my $newseq = $preseq . (substr $synISS, 0,  (int $synsize / 2))
                 . $markerregion . (substr $wtISS, $synsize / 2);
      $chseq = $newseq;
      $chunklen = length $chseq;
      my $start = index $newseq, (substr $realmarker->sequence, 0, 30);
      $comment .= "$lefcom to ($midenz) $rigcom; $chunklen bp total, ";
      $comment .= 'annotated from ' . $chstart . q{..} . $chend;
      $comment .= ";ISS: $midenz synseq ($synstart..$synend) <$marker>";
      $comment .= " wtseq ($wtstart..$wtend) $rigcom";
      $apeenzlist{$lzname}++;
      $apeenzlist{$midname}++ if ($midre ne $rigre && $midre ne $lefre);
      $apeenzlist{$rzname}++ if ($rigre ne $lefre);
      $apeenzlist{$excisorid}++;
      my $feat = Bio::SeqFeature::Generic->new
      (
        -primary => 'marker_gene',
        -start => $start + 1,
        -end   => $start + length($BS_MARKERS->{$marker}->sequence),
        -tag   => {
          label            => $marker,
          ApEinfo_fwdcolor => $BS_MARKERS->{$marker}->color,
          ApEinfo_revcolor => $BS_MARKERS->{$marker}->color
        }
      );
      push @addfeatures, $feat;
    }
    elsif ($ze == $mchunknum)
    {
      #The very last chunk in the last megachunk
      $comment  = "$lefcom to just before the 3' UTC; $chunklen bp ";
      $comment .= 'from ' . $chstart . ' to ' . $chend;
      $apeenzlist{$lzname}++;
    }

    foreach my $enz (keys %apeenzlist)
    {
      my $checkhsh = $RES->{$enz}->positions($chseq);
      my @positions = keys %{$checkhsh};
      my $rightcount = $apeenzlist{$enz};
      if (scalar @positions != $rightcount)
      {
        print "\t\t $enz wrong number of times in $chname!\n";
        print $chseq;
        print "\n\n";
      }
      foreach my $start (@positions)
      {
        my $feat = Bio::SeqFeature::Generic->new
        (
          -primary => 'found_enzyme',
          -start  => $start + 1,
          -end    => $start + $RES->{$enz}->len,
          -tag    => {
            label            => $enz,
            ApEinfo_fwdcolor => '#CC0000',
            ApEinfo_revcolor => '#CC0000'}
        );
        push @addfeatures, $feat;
      }
    }
    my $chobj = $newchr->genbank_feature(
      -feature => $chunk,
      -skip_features => \%skiptypes,
      -ape_color => {'enzyme_recognition_site' => '#990000'},
      -comment => $comment,
      -sequence => $chseq,
    );
    $chobj->add_SeqFeature($_) foreach (@addfeatures);
    my $chpath = $CHUNKDIR . $chname . '.genbank';
    my $apeout = Bio::SeqIO->new(-file => ">$chpath", -format => 'genbank');
    $apeout->write_seq($chobj);
  }
}

exit;

__END__

=head1 NAME

  BS_ChromosomeSegmenter.pl

=head1 VERSION

  Version 3.00

=head1 DESCRIPTION

 1) Scanning:
  This utility creates an exhaustive database of restriction enzyme recognition
   sites along a chromsome, both existing and potential.
  Every intergenic sequence is parsed for existing recognition sites. Those that
   are found are marked (i)mmutable. A prefix tree is created from all possible
   6-frame translations of restriction enzyme recognition sites, such that each
   node in the tree is an amino acid string that may be reverse translated to be
   a recognition site. Every exonic sequence in the chromosome is then searched
   with the prefix tree both for (e)xisting recognition sites and for sites
   where a (p)otential recognition site could be introduced without changing the
   protein sequence of the gene. As long as they occur within protein coding
   genes, existing and potential recognition sites may be manipulated to yield
   any of several different overhangs, all of which are computed by the
   algorithm.
  A score is assigned to every restriction enzyme site. The score is a function
   of the log of the enzyme's price per unit, plus two tenths for each orf that
   must be modified to make the enzyme unique within the range of the chunk
   size.

 2) Filtering:
  Every extant site is indexed so that later in the design process, when
    potential sites are considered, the number of sites that must be modified is
    a known contribution to the cost. However, all potential sites that could
    not be made unique under any useful circumstances are culled from the
    database.

 3) Segmenting:
  A set of restriction enzyme recognition site changes to a chromosome. The goal
    is to make the chromosome assemblable from multikilobase pieces called
    chunks, which in groups of roughly CHUNKNUM form larger pieces called
    megachunks. Megachunks end in special regions called InterSiteSequences
    (ISS), which consist of synthetic sequence, followed by a marker, followed
    by wild-type sequence, followed by a type IIB restriction enzyme recognition
    site.  The wild-type sequence targets the megachunk to its target chromosome
    for homologous recombination (thus wild type here can be any homologous
    chromosome, as long as gene order is the same). Megachunks alternate markers
    to allow a simple selection for successful integration. Markers should be
    defined in config/markers.

 4) Committing:
  If a successful plan was found in step three, the utility attempts to make all
    of the proposed changes.

 5) Proof reading:
  The new chromosome is checked for the existance of new restriction sites,
    their appropriate uniqueness, and the sanctity of coding sequences.

 6) Reporting:
  The megachunks and chunks of the new chromosome are exported to the genome
    repository in an assembly directory. Each file is a genbank annotation with
    restriction enzymes, ISS, and marker sequences specially highlighted.

=head1 ARGUMENTS

Required arguments:

  -CHR, --CHROMOSOME : The chromosome to be modified
  --WTCHR  : The chromosome that will receive chunks (usually wildtype)
  --MARKERS : Comma separated list which will be alternately inserted
      into megachunk ISS sequences (must be defined in config/markers)

Optional arguments:

  --ENZYME_SET : Which list of restriction enzymes to use (default nonpal)
  --MIN_CHUNK_SIZE : The minimum size of chunks to be designed (default 5000)
  --MAX_CHUNK_SIZE : The maximum size of chunks to be designed (default 10000)
  --STARTPOS : The first base for analysis
  --STOPPOS  : The last base for analysis
  --CHUNKNUM : The target number of chunks per megachunk (default 4)
  --CHUNKNUMMIN : The minimum number of chunks per megachunk (default 3)
  --CHUNKNUMMAX : The maximum number of chunks per megachunk (default 5)
  --CHUNKOLAP : The number of bases each chunk must overlap (default 40)
  --ISSMIN : Minimum size of the homologous intersite sequence (default 900)
  --ISSMAX : Maximum size of the homologous intersite sequence (default 1500)
  --FPUTRPADDING : No edit zone upstream of the five prime end of
       essential/fast growth genes when no UTR is annotated (default 500)
  --TPUTRPADDING : No edit zone downstream of the three prime end of
            essential/fast growth genes when no UTR is annotated (default 100)
  --LASTMARKER : Which marker should be the last marker inserted (must be
            defined in config/markers)
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