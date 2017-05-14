#!/usr/local/bin/perl -w
# cvs id: $Id: make_classes.pl,v 1.17 2001/02/06 19:05:13 jes Exp $

use File::Basename;
use File::stat;
use strict;
use Getopt::Long;
use Cwd;

my $make_pm = 0;
my $make_pod = 0;
my $CONTROL_ONLY = 0;
my $LINKING_ONLY = 0;
my $ROOT = cwd();

GetOptions('make_pm' => \$make_pm,
	   'make_pod' => \$make_pod,
	   'control_only' => \$CONTROL_ONLY,
	   'linking_only' => \$LINKING_ONLY,
	   'root=s' => \$ROOT,
	  );

my $DEBUG = 0;
my @PM;
@PM = (
       # complex classes with supporting tables, 
       # i.e. MANY_TO_ONE, LOOKUP_TABLE, or LINKING_TABLE fkeys
       {target=>'ArrayLayout',
	support=>['AL_Spots']},
       {target=>'Species',
	support=>['UserSequenceFeature',
		  'Chromosome']},
       {target=>'ExperimentSet',
	support=>['ArrayMeasurement',
		  'HotSpots',
		  'TreatmentLevel',
		  'ExperimentFactors']},
       {target=>'ArrayMeasurement',
	support=>['AM_Spots',
		  'AM_FactorValues',
		  'Treatment_AMs']},
       {target=>'TreatmentLevel',
	support=>['TL_FactorValues',
		  'Treatment_AMs']},
       {target=>'ExperimentFactors',
	support=>['TL_FactorValues',
		  'AM_FactorValues']},
       {target=>'UserSequenceFeature',
	support=>['HotSpots',
		  'BlastHits',
		  'USF_ExternalDBLink']},
       {target=>'Sample',
	support=>['SampleProtocols']},
       {target=>'Protocol',
	support=>['SampleProtocols']},
       {target=>'GroupSec',
	support=>['GroupLink']},
       {target=>'UserSec',
	support=>['GroupLink']},
       {target=>'AM_Spots',
	support=>['SpotLink']},
       {target=>'AL_Spots',
	support=>['SpotLink']},

       # simple classes with no supporting tables
       {target=>'Chromosome'},
       {target=>'GenexAdmin'},
       {target=>'Contact'},
       {target=>'Citation'},
       {target=>'Software'},
       {target=>'Scanner'},
       {target=>'Spotter'},
       {target=>'ExternalDatabase'}, 
       {target=>'BlastHits'},
       
       # linking table classes
       {target=>'AM_FactorValues',linking=>1},
       {target=>'AM_SuspectSpots',linking=>1},
       {target=>'HotSpots',linking=>1},
       {target=>'SpotLink',linking=>1},
       {target=>'Treatment_AMs',linking=>1},
       {target=>'SampleProtocols',linking=>1},
       {target=>'USF_ExternalDBLink',linking=>1},
       {target=>'TL_FactorValues',linking=>1},
       {target=>'GroupLink',linking=>1},
       
       # controlled vocabular classes
       {target=>'ControlledVocab',
	pkey=>'term_string',
	controlled=>['AL_Coating',
		     'AL_DefaultSpotConcUnits',
		     'AL_TechnologyType',
		     'AL_Medium',
		     'AL_IdentifierCode',
		     'ALS_SpotType',
		     'AM_EquationType',
		     'AM_SpotMeasurementUnits',
		     'AM_Type',
		     'ContactType',
		     'EF_MajorCategory',
		     'EF_MinorCategory',
		     'ES_QuantitySeriesType',
		     'ES_TreatmentType',
		     'HS_ThresholdType',
		     'PRT_Type',
		     'SCN_ModelDescription',
		     'SMP_AgeUnits',
		     'SMP_DevelopmentStageName',
		     'SMP_DevelopmentStageUnits',
		     'SMP_GeneticStatus',
		     'SMP_OrganismIntactness',
		     'SMP_OrganType',
		     'SMP_PrimaryCellType',
		     'SMP_SexMatingType',
		     'SMP_TissueType',
		     'SPC_GeneralClassification',
		     'SPC_CellStructure',
		     'SPT_ModelDescription',
		     'SW_Name',
		     'SW_Type',
		     'USF_Type']}
      );

if ($make_pm) {
  my $CREATE = $ROOT . '/scripts/create_genex_class.pl';
  
  die "$CREATE is not executable" unless -x $CREATE;
  
  TARGET: foreach my $target (@PM) {
    # we only want to make a new pod file if the infile has been modified 
    # since we last ran created the pod file
    my %args = %{$target};
    next TARGET  if $CONTROL_ONLY && ! exists $args{controlled};
    next TARGET  if $LINKING_ONLY && ! exists $args{linking};

    my $base = $args{target};
    my $dir = "$ROOT/$base";
    my $file = "$dir/$base.pm";
    die "Couldn't find $file" unless -d $dir;
    if (-e $file) {

      # if the create script is newer than the .pm file redo the class
      my $st_out = stat("$file");
      my $st_in = stat("$CREATE");

      # otherwise check each class's files 
      if ($st_in->mtime < $st_out->mtime) {
	my @files;
	# check the master column2name file
	if (exists $args{controlled}) {
	  push(@files,"$ROOT/ControlledVocab/column2name");	  
	} else {
	  push(@files,"$ROOT/$base/column2name");	  
	}
	# check any supporting column2name files
	if (exists $args{support}) {
	  foreach (@{$args{support}}) {
	    push(@files,"$ROOT/$_/column2name");	  
	  }      
	}
	# go through the files and see if any are more recent
	foreach (@files) {
	  die "Couldn't find $_" unless -e $_;
	  $st_in = stat($_);
	  last if $st_in->mtime > $st_out->mtime;
	}

	# skip this target if none of the files are more recent
	if ($st_in->mtime < $st_out->mtime) {
	  print STDERR "Skipping $file (no change)\n" if $DEBUG; 
	  next TARGET;
	}
      }
    }

    my $cmd = "$CREATE --dir=$ROOT --target=$base";
    foreach (@{$args{support}}) {
      $cmd .= " --support=$_";
    }
    if (exists $args{pkey}) {
      $cmd .= " --pkey=$args{pkey}";
    }
    if (exists $args{controlled}) {
      foreach my $arg (@{$args{controlled}}) {
	$cmd .= " --controlled=$arg";
      }
    }
    print STDERR "$cmd\n";
    system("$cmd");
    die $? if $?;
  }
}

my @HELPER = ({target=>'Genex'},
	      {target=>'DBUtils'},
	      {target=>'scripts/db2xml.pl'},
	      {target=>'samples/control-bundle.pl'},
	      {target=>'XMLUtils'},
	      {target=>'HTMLUtils'});
if ($make_pod) {
  my $PODROOT = $ROOT . '/pod';
  my $HTMLROOT = $ROOT . '/html';
  
  chdir($PODROOT);
  
  #  my $libpods = join(':', keys %PM);
  my $libpods = '';
  my $p2h_args = "  --htmlroot=$HTMLROOT --podroot=$PODROOT --podpath=. --libpods=$PODROOT";
  
  # we include the helper modules here as well
  for my $target (@PM,@HELPER) {
    my %args = %{$target};
    next if $CONTROL_ONLY && ! exists $args{controlled};
    next if $LINKING_ONLY && ! exists $args{linking};

    my $file = "$ROOT/$args{target}/$args{target}.pm";
    $file = "$ROOT/$args{target}.pm" if $args{target} eq 'Genex';
    $file = "$ROOT/$args{target}" if $args{target} =~ /\.pl$/;
    die "Couldn't find $file" unless -e $file;
    my $base = $args{target};
    $base =~ s|samples/||;
    $base =~ s|scripts/||;
    my $pod  = $base . '.pod';
    
    # we only want to make a new pod file if the infile has been modified 
    # since we last ran created the pod file
    if (-f "$PODROOT/$pod") {
      my $st_out = stat("$PODROOT/$pod");
      my $st_in = stat("$file");
      
      if ($st_in->mtime < $st_out->mtime) {
	print STDERR "Skipping $file (no change)\n" if $DEBUG; 
	next;
      }
    }
    
    my $cmd = "podselect $file  > $pod";
    print STDERR "$cmd\n";
    system("$cmd");
    die $? if $?;
    
  }
  
  # we include the helper modules here as well
  for my $target (@PM,@HELPER) {
    my %args = %{$target};
    my $file = "$args{target}/$args{target}.pm";
    $file = "$args{target}.pm" if $args{target} eq 'Genex';
    $file = "$ROOT/$args{target}" if $args{target} =~ /^samples/;
    my $base = $args{target};
    $base =~ s|samples/||;
    $base =~ s|scripts/||;
    my $pod  = $base . '.pod';
    my $html = $base . '.html';
    
    # we only want to make a new html file if the pod file has been changed
    # since we last ran created the html file
    if (-f "$HTMLROOT/$html") {
      my $st_out = stat("$HTMLROOT/$html");
      my $st_in = stat("$PODROOT/$pod");
      
      if ($st_in->mtime < $st_out->mtime) {
	print STDERR "Skipping $HTMLROOT/$html (no change)\n" if $DEBUG;
	next;
      }
    }
    
    my $cmd = "pod2html $p2h_args --infile=$pod  --outfile=$HTMLROOT/$html";
    print STDERR "$cmd\n";
    system("$cmd");
    die $? if $?;
  }
}

__END__


