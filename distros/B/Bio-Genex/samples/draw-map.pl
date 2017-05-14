#!/usr/local/bin/perl -w

use strict;
# use Carp;
use constant GENEX => '/home/jes/genex/';
use constant TMP => '/home/www/tmp/';
use GD;
use lib GENEX . 'dbscripts/modules/DBUtils';
use DBUtils qw(assert_table_defined lookup_orf_id lookup_species_id);
use CGI qw/:standard :html3 :Carp/; # LS's CGI thingie
use Getopt::Long;
#use Env qw(QUERY_STRING);

# get the parameters from the CGI script
#print STDERR "Query string: $QUERY_STRING\n";
# Query string: lut=sys32.lut&maxval=12986&datafile=/tmp/MPGG2628/data.FMT.2628&arrayname=SBS-HS_39_1
# my $MAX_EXPR_VALUE = 12986;
# my $lut = 'sys32.lut';
# my $data_file = '/tmp/MPGG314/data.FMT.314';
# my $array_name = 'SBS-HS_39_1';
# my $LOG_MAX = log($MAX_EXPR_VALUE);      

my $MAX_EXPR_VALUE = url_param('maxval');
my $lut = url_param('lut');
my $data_file = url_param('datafile');
my $array_name = url_param('arrayname');
my @orfs = split ',', url_param('orfs');
my $LOG_MAX = log($MAX_EXPR_VALUE);      

# ================= Get the chromosome data from GeneX  ===================
my $dbname = 'genex';
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname","","",{PrintError => 1});

die "Couldn't connect to $dbname" if $dbh->err;

# make sure we have the tables we need
assert_table_defined($dbh,'Chromosome');

my $species_name = 'Saccharomyces cerevisiae';
my $species_id = lookup_species_id($dbh,$species_name);


# # prepare the sql statements we need to run for each chromosome
my $sql = 'SELECT name,length FROM chromosome WHERE species_id = ';
$sql .= $species_id; 
my $sth = $dbh->prepare($sql) || die $dbh->errstr;;

my @CHROM;
$sth->execute() || die $dbh->errstr;
while (my $ref = $sth->fetchrow_hashref()) {
  push(@CHROM,$ref);
}

# the table is no longer static
# my @CHROM = ([I    => 233_581],
# 	     [II   => 824_843],
# 	     [III  => 319_928],
# 	     [IV   => 1_553_947],
# 	     [V    => 585_914],
# 	     [VI   => 274_089],
# 	     [VII  => 1_106_606],
# 	     [VIII => 570_762],
# 	     [IX   => 446_251],
# 	     [X    => 756_176],
# 	     [XI   => 676_054],
# 	     [XII  => 1_087_473],
# 	     [XIII => 937_724],
# 	     [XIV  => 795_574],
# 	     [XV   => 1_106_957],
# 	     [XVI  => 961_696],
# 	    );

# image constants
my $IM_HEIGHT = 400;
my $IM_WIDTH = 600;
my $Y_PAD = 10;
my $X_PAD = 10;
my $NUM_CHROM = scalar @CHROM;
my $X_MARGIN = 5;
my $Y_MARGIN = 5;
my $Y_OFF = 7;
my $Y_SPACE = $IM_HEIGHT / ($NUM_CHROM + 1);
my %CHROM;
my $CHROM_MAX_LEN = 0;

my $STR_LEN = 20;
my $NET_WIDTH = $IM_WIDTH - 2*$X_PAD - $STR_LEN;

# my $CHROM_NAME_IDX = 0;
# my $CHROM_LEN_IDX  = 1;
# my $CHROM_ORFS_IDX = 2;
# my $CHROM_YLOC_IDX = 3;
# my $CHROM_PXL_IDX  = 4;
foreach (@CHROM) {
  $CHROM_MAX_LEN = $_->{length}
    if $_->{length} > $CHROM_MAX_LEN;

  # we store @CHROM in %CHROM indexed by chromosome name
  $CHROM{$_->{name}} = $_;
}

# after we've calculated the max length, we go back through
# to figure out how many pixels each chromosome is given
foreach (values %CHROM) {
  $_->{pixels} = $NET_WIDTH * $_->{length}/$CHROM_MAX_LEN;
}

# ================= Grab the info from the orf file  =========================
open(ORF,$data_file) or die "Couldn't open $data_file";

my %orfs;
my ($time,$orf_name);
while (<ORF>) {
  # only parse the array we want
  next unless /^$array_name/o;

  my ($time,$orf_name,$value) 
      = /[^\t]+\t	# array name
	([^\t]+)\t	# ** time step **
	([^\t]+)\t	# ** orf name **
	 [^\t]+\t	# gene name
         [^\t]+\t	# ec number
	 [^\t]+\t	# chromosome number 
	 [^\t]+\t	# peptide length
	([^\t]+)\t	# ** spot value **
	 [^\t]+\t	# description
	 [^\t]+/x;      # start location 
  
  $orfs{$orf_name}->{'data'}->[$time] = $value;
}

# grab the orf info from the DB
$sql = 'SELECT start_position,chromosome FROM orf WHERE serial_orf_name = ?';
$sth = $dbh->prepare($sql);
foreach my $orf_name (@orfs) {
  $sth->execute($orf_name);
  my ($start,$chrom_num)= ($sth->fetchrow_array())[0,1];

  # convert the base pair start to a pixel location
  $start *= $CHROM{$chrom_num}->{pixels} / $CHROM{$chrom_num}->{length};

  # store the info in lookup tables
  $orfs{$orf_name}->{'chrom'} = $chrom_num;
  $orfs{$orf_name}->{'start'} = $start;
  $CHROM{$chrom_num}->{orfs}->{$orf_name} = $start;
}
  
# We want to look at each chromosome one at a time
# and rearrange the orfs slightly so that they don't overlap
foreach my $chr (values %CHROM) {
  next unless defined $chr->{orfs};
  my $prev_start;
  my %tmp_orfs = %{$chr->{orfs}};
  if (scalar keys %tmp_orfs > 1) {
    my @tmp_orfs = sort {$a->[1] <=> $b->[1]} map {[$_,$orfs{$_}->{'start'}]} keys %orfs;
    foreach (@tmp_orfs) {
      my $start = $_->[1];
      my $orf = $_->[0];
      if (defined $prev_start) {
	my $diff = $start - $prev_start - 3;
	# we want at least a 3 pixel separation
	if ($diff < 0) {
	  $orfs{$orf}->{'start'} -= $diff;
	}
	print STDERR "Chrom: $chr->{name}, orf: $orf, start: $start\n";
      }
      $prev_start = $start;
    }
  }
}

# ================= load the color look up table  ===========================
open(LUT, "$lut") or die "Can't open the LUT file: $lut !\n";
my $i = 0;
my @CLUT;
while (<LUT>) {
  my ($tmp,@rgb) = split;
  $CLUT[$i] = \@rgb;
  $i++;
}

# create the image
my $im = new GD::Image($IM_WIDTH,$IM_HEIGHT);
my $white = $im->colorAllocate(255,255,255);
my $black = $im->colorAllocate(110,110,110);    #grey actually   
$im->transparent($white);


# Draw the chomosomes
my $y_loc = 0;
my $chrom_start = $X_MARGIN + $STR_LEN + $X_PAD;
foreach (@CHROM) {
  $y_loc += $Y_SPACE;
  
  # store the image location in the @CHROM array for later use
  $_->{yloc} = $y_loc;
  $im->string(gdSmallFont,$X_MARGIN,$y_loc-$Y_OFF,$_->{name},$black);
  my $len = ($_->{length}/$CHROM_MAX_LEN) * $NET_WIDTH;
  $im->line($chrom_start,$y_loc,$chrom_start+$len,$y_loc,$black);
}

# Go through the orfs one at a time
my ($value,$x_loc,$chrom,@colors,$begin,$chrom_num,@rgb,$index);
foreach my $orf (keys %orfs) {
  # Go throught the time steps one at a time
  my $step_num = scalar @{$orfs{$orf}->{'data'}};
  my $y_incr = $Y_SPACE * 4/$step_num;
  my $y2 = $Y_SPACE*0.4;
  my $y1 = 0;
  $chrom_num = $orfs{$orf}->{'chrom'};
  $begin     = $orfs{$orf}->{'start'};
  foreach $value (@{$orfs{$orf}->{'data'}}) {
    # we have blanks in the array
    next unless defined $value;
    $y1 = $y2;
    $y2 = $y1 - $y_incr;
    my $color;
    if ($value > $MAX_EXPR_VALUE) {
      $color =  $im->colorAllocate(255, 255, 255);
    } else {
      $value = 0.01 if $value <= 0; # Just in case
      $index = int((log($value)*255)/$LOG_MAX);
      @rgb = @{$CLUT[$index]};
      $color = $im->colorAllocate(@rgb);
    }
    
    # print out the orf on the image
    $x_loc = $chrom_start + $begin;
    $chrom = $CHROM{$chrom_num};
    $im->line($x_loc,$chrom->{yloc} + $y1,
	      $x_loc,$chrom->{yloc} + $y2,$color);    
    # make it two pixels thick
    $im->line($x_loc-1,$chrom->{yloc} + $y1,
	      $x_loc-1,$chrom->{yloc} + $y2,$color);    
  }
}

# print out the image
my $file_name = "test-$$.gif";
my $gif_file = TMP . $file_name;
# my $gif_file = "/home/jes/tmp/test.gif";
open(GIF, ">$gif_file") or die "Can't open $gif_file";
binmode GIF;
print(GIF $im->gif);
close GIF;

print header,
      start_html("Chromosome Map for $array_name"),
      img({src => "http://localhost/tmp/$file_name"});

print end_html();


