#!/usr/bin/perl -w
use BIE::App::PacBio;
use PDL;
use PDL::Graphics::PLplot;
use v5.10;

die "Usage: $0 PacBio_bas.h5\n"
  unless -e $ARGV[0];

# Define constants for the paths.
use constant PG => 'PulseData/';
use constant BG => PG . 'BaseCalls/';
use constant BZG => BG . 'ZMW/';
use constant BZMG => BG . 'ZMWMetrics/';
use constant CBG => PG . 'ConsensusBaseCalls/';
use constant CBZG => CBG . 'ZMW/';
use constant CBPG => CBG . 'Passes/';
# Define a function to create hash for datasets.
# It accepts a string array to return a path hash.
our %Bases = map {$_ => BG . $_} qw(
				     Basecall
				     DeletionQV
				     DeletionTag
				     InsertionQV
				     PreBaseFrames
				     PulseIndex
				     QualityValue
				     SubstitutionQV
				     SubstitutionTag
				     WidthInFrames
				  );

our %ZMWs = map {$_ => BZG . $_} qw(
				     HoleNumber
				     HoleStatus
				     HoleXY
				     NumEvent
				  );

our %ZMWMetrics = map {$_ => BZMG . $_} qw(
					    BaseFraction
					    BaseIpd
					    BaseRate
					    BaseWidth
					    CmBasQv
					    CmDelQv
					    CmInsQv
					    CmSubQv
					    DarkBaseRate
					    HQRegionEndTime
					    HQRegionSNR
					    HQRegionStartTime
					    LocalBaseRate
					    Productivity
					    ReadScore
					    RmBasQv
					    RmDelQv
					    RmInsQv
					    RmSubQv
					 );

our %CCSBases = map {$_ => CBG . $_} qw(
Basecall
DeletionQV
DeletionTag
InsertionQV
QualityValue
SubstitutionQV
SubstitutionTag
);

our %CCSPasses = map {$_ => CBPG . $_} qw(
AdapterHitAfter
AdapterHitBefore
NumPasses
PassDirection
PassNumBases
PassStartBase
);

our %CCSZMWs = map {$_ => CBZG . $_} qw(
HoleNumber
HoleStatus
HoleXY
NumEvent
);

my $pb = BIE::App::PacBio->new(file => $ARGV[0]);
(my $output = $ARGV[0]) =~ s/\..+$//;

##################################################
#kinds of QC
##################################################
&ccsQC();
#&clrQC();

sub clrQC {
  $pb->lens($pb->read($ZMWs{NumEvent}));
  my $prefix = 'CLR';
  my $qv = &preSplit($Bases{QualityValue});
  my $meanQV = &preStat(\&getAve, $qv);
  &plotQVbyPos($prefix, $qv);

##################################################
#plot quality value correlation
  for (qw(DeletionQV InsertionQV SubstitutionQV)) {
      (my $tag = $_) =~ s/QV//;
      &plotQV($prefix.$tag, $Bases{$_}, $meanQV);
  }
#plot base tags --- bargraph
  for (qw(Basecall DeletionTag SubstitutionTag)) {
    &plotBarGraph($prefix.$_, $Bases{$_}, {A=>65,C=>67,G=>71,T=>84});
  }
#plot length distribution  
  &plotLenDist($prefix, $pb);
}

sub ccsQC {
  open my $outFH, '>', $output . '.CCSQC';
  my @master;
  $pb->lens($pb->read($CCSZMWs{NumEvent}));
  my $prefix = 'CCS';  
  my $qv = &preSplit($CCSBases{QualityValue});
  my $meanQV = &preStat(\&getAve, $qv);
  push @master, $meanQV, $pb->lens, &plotQVLenCycle($pb, $meanQV);
  &plotQVbyPos($prefix, $qv);

##################################################
#plot quality value correlation
  for (qw(DeletionQV InsertionQV SubstitutionQV)) {
      (my $tag = $_) =~ s/QV//;
      push @master, &plotQV($prefix.$tag, $CCSBases{$_}, $meanQV);
  }
#plot base tags --- bargraph
  for (qw(Basecall DeletionTag SubstitutionTag)) {
    &plotBarGraph($prefix.$_, $CCSBases{$_}, {A=>65,C=>67,G=>71,T=>84});
  }

#plot length distribution  
  &plotLenDist($prefix, $pb);
  
  for (qw(PassNumBases PassStartBase)) {
    &plotHist($prefix.$_, $CCSPasses{$_});
  }
  
  &plotBarGraph('CCSPassDirection', $CCSPasses{PassDirection}, 
			      {
			       Pos=>1, Neg=>0});

  say $outFH join "\t", qw(idx avgQV Length Cycles avgDelQV avgInsQV avgSubQV);
  for (0..$#{$master[0]}) {
    my $idx = $_;
    say $outFH join "\t", $idx, map {$_->[$idx]} @master;
  }
}

##################################################
#functions for QC
##################################################

sub plotQVbyPos {
  my ($tag, $qv) = @_;
  my $vmeanQV = &preStat(\&getVave, $qv);    
  &pbview(
	  'qv'.$tag.'ByPos',
	  [[1..($#$vmeanQV+1)],
	  $vmeanQV],
	  'QV by Position on Read',
	  'Read Position',
	  'Mean QV'
	 );
}

sub plotQVLenCycle {
  my ($pb, $meanQV) = @_;
  my $pass =  &preSel($CCSPasses{NumPasses});
  &pbview(
	  'qvLenCycle',
	  [$pb->lens,
	  $meanQV,
	  $pass],
	  'QV by Length and Cycle Number',
	  'Read Length',
	  'Mean QV by Read',
	  'Cycles',
	 );
  say "Quality vs. Length colored by Cycle Number: Done";
  return $pass;
}

sub plotBarGraph {
  # $lbs is a hash ref of label info.
  my ($tag, $path, $lbs) = @_;
  my $data = $pb->read($path);
  &pbview(
	  'qv'.$tag.'Bar',
	  [],
#	  [$data, {A=>65,C=>67,G=>71,T=>84}],
	  [$data, $lbs],
	  $tag . ' Bar',
	  $tag,
	 );
  say $tag . " Distribution: Done";
  return $data;
}

sub plotLenDist {
  my ($tag, $pb) = @_;
  &pbview(
	  'qv'.$tag.'LenDist',
	  [$pb->lens],
	  100, #bin number
	  'Distribution of Read Length',
	  'Read Length'
	 );
  say $tag . ' Read Length Distribution: Done';
}

sub plotHist {
  my ($tag, $path) = @_;
  my $d = $pb->read($path);
  &pbview(
	  'qv'. $tag,
	  [$d],
	  100, #bin number
	  'Distribution of '.$tag,
	  $tag,
	 );
  say $tag . " Distribution: Done";
}

sub plotQV {
  my ($tag, $path, $meanQV) = @_;
  my $d = &preSplit($path);
  my $meanD = &preStat(\&getAve, $d);
  &pbview(
	  'qv'.$tag.'Corr',
	  [$meanQV,
	   $meanD
	  ],
	  'Correlation between QV and '.$tag.'QV',
	  'Quality Value by Read',
	  $tag . ' Quality by Read',
	 );
  say 'Correlation between ' . $tag . 'QV and quality value: Done';
  return $meanD;
}


##################################################
#functions for plotting                          #
##################################################

#functions to preprocess data
#disgard nan data
sub preSel {
  my $data = $pb->read(shift);
  my $hit = [@{$data}[@{$pb->hitIdx}]];
}
#split by read
sub preSplit {
  my $data = $pb->split(shift);
}
sub preStat {
  my $func = shift;
  my $data = shift;
  &{$func}($data);
}
#params: ArrRef of data
#	 plot dimensions: 2d or 3d?
sub pbview {
  my $chart = PDL::Graphics::PLplot->new(
					 DEV => 'png',
					 FILE => shift . '.png',
					);
  my ($xyz, @plotParams) = @_;

  &{'pbplot'.($#$xyz+1).'d'}($chart, @$xyz, @plotParams);
  $chart->close;
}
#one param: ArrRef[ArrRef]
sub getAve {
  $PDL::undefval=-999;
  my $data =  pdl shift;
  $data->inplace->setvaltobad($PDL::undefval);
  return [
	  list $data->average
	 ];
}
sub getVave {
  $PDL::undefval=-999;
  my $data =  pdl shift;
  $data->inplace->setvaltobad($PDL::undefval);
  return [
	  list $data->transpose->average
	 ];
}

#need params: title, x label, and x data.
sub pbplot0d {
  my $chart = shift;
  my ($data, $title, $xlab) = @_;
  my $d = pdl $data->[0];
  my $lbl = $data->[1];
  my @labels = sort keys %$lbl;
  my @vals;
  for (0..$#labels) {
    $vals[$_] = $d->where($d==$lbl->{$labels[$_]})->nelem;
  }
  my $v = pdl @vals;
  $chart->bargraph(
		   \@labels,
		   $v,
		   XLAB => $xlab,
		   TITLE => $title,
		   BOX => [0, scalar(@labels), 0, $v->max * 1.1],
		   COLOR => 'BLUE',
		  );
}
#need params: title, x label, and x data.
sub pbplot1d {
  my $chart = shift;
  my $x = pdl $_[0];
  my (undef, $binNumber, $title, $xlab) = @_;
  my ($hx, $hy) = hist($x, $x->minmax, ($x->max - $x->min)/$binNumber);
  $chart->histogram(
		 $x,$binNumber,
		 XLAB => $xlab,
		 TITLE => $title,
		 BOX => [$x->minmax, 0, $hy->max * 1.1],
		);
}
#need params: title, x label, ylabel and x y data.
sub pbplot2d {
  my $chart = shift;
  my ($x, $y) = map {pdl $_} @_[0,1];
  my (undef, undef, $title, $xlab, $ylab) = @_;  
  $chart->xyplot(
		 $x, $y,
		 PLOTTYPE=>'POINTS',
		 XLAB => $xlab,
		 YLAB => $ylab,
		 TITLE => $title,
		);
}
#need params: title, x label, y label, z label and x y z data.
#z would be denoted by color key.
sub pbplot3d {
  my $chart = shift;
  my ($x, $y, $z) = map {pdl $_} @_[0..2];
  my (undef, undef, undef, $title, $xlab, $ylab, $zlab) = @_;
  $chart->xyplot(
		 $x, $y,
		 PLOTTYPE=>'POINTS',
		 XLAB => $xlab,
		 YLAB => $ylab,
		 TITLE => $title,
		 PALETTE => 'REVERSERAINBOW',
		 COLORMAP => $z,
		);
  $chart->setparm(CHARSIZE=>0.5);
  $chart->colorkey($z, 'v',
		   VIEWPORT => [0.93, 0.96, 0.13, 0.85],
		   TITLE => '',
		   XLAB => $zlab,
		   YLAB => '',
		  );
}
