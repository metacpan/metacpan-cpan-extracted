#!/usr/bin/env perl -w
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be] & Yves Van den Hove [yvdhove@users.sourceforge.net]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, GrinderCaptureConverter.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;
use Getopt::Long;
use vars qw($opt_i $opt_o $opt_f $opt_h $opt_v $PROGNAME);

my $PROGNAME = "GrinderCaptureConverter.pl";
my $prgtext  = "Grinder Capture Converter";
my $version  = "1.19";
my $debug    = 0;

my $infile;
my $outfile;
my $format;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub build_QS_fixed($);
sub output_webtransact();
sub output_list();
sub print_help();
sub print_usage();
sub print_revision();

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Getopt::Long::Configure('bundling');

GetOptions (
  "i=s" => \$opt_i, "input-file=s"  => \$opt_i, # required
  "o=s" => \$opt_o, "output-file=s" => \$opt_o, # required
  "f:s" => \$opt_f, "format:s"      => \$opt_f, # optioneel
  "v"   => \$opt_v, "version"       => \$opt_v, # required
  "h"   => \$opt_h, "help"          => \$opt_h, # required
);

if ($opt_v) { print_revision(); exit(0); }
if ($opt_h) { print_help();     exit(0); }

if ($opt_i) { $infile  = $opt_i; } else { print_revision(); print_usage(); print("$PROGNAME: No grinder input file specified!\n\n"); exit(0); }
if ($opt_o) { $outfile = $opt_o; } else { print_revision(); print_usage(); print("$PROGNAME: No output file specified!\n\n"); exit(0); }
if ($opt_f) { if ($opt_f eq "L" or $opt_f eq "W") { $format = $opt_f; } else { print_revision(); print_usage(); print("$PROGNAME: Wrong format specified!\n\n"); exit(0); } } else { $format = "W"; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Bepalen van de directory
$infile =~ /^((?:.*)\/)/;
my $directory = (defined $1) ? $1 : '';

# Openen van de inputfile
open (INFILE, "<$infile") || die ("Could not open grinder input file");

# Inlezen van de inputfile
my @inArray = <INFILE>;

# Sluiten van de file
close (INFILE);

# Variabelen nodig voor de verwerking
my @urlArray;
my @postArray;
my @dataArray;
my $url;
my $user;
my $password;
my $postType;
my $postData;
my $written = 1;

# De bruikbare lijnen uitfilteren
foreach my $l (@inArray){
  $l =~ s/\r//g;
  $l =~ s/\n//g;

  if ($l =~ /.parameter.url=/) {
    # De vorige url pushen
    if (! $written) {
      $url =~ s|^(http[s]*://)|$1$user\:$password\@| if(defined $user && defined $password);
      push (@postArray, $postType);
      push (@urlArray, $url);
      push (@dataArray, $postData);
      $user = undef;
      $password = undef;
      $written = 1;
    }

    # De nieuwe url bepalen
    my $pos = index($l, "=") + 1;
    $url = substr($l, $pos);
    $postType = 'GET';
    $postData = '<NIHIL>';
    $written  = 0;
  } elsif ($l =~ /.parameter.header.If-Modified-Since=/) {
    $postType = 'GET';
    $written  = 0;
  } elsif ($l =~ /.parameter.header.Content-Type=/) {
    $postType = 'POST';
    $written  = 0;
  } elsif ($l =~ /.parameter.post=/) {
    my $pos = index($l, "=") + 1;
    open (POSTFILE, $directory . substr($l, $pos)) || die ("Could not open post file");
    $postData = <POSTFILE>;
    close (POSTFILE);
  } elsif ($l =~ /.basicAuthenticationUser=/) {
    my $pos = index($l, "=") + 1;
    $user = substr($l, $pos);
    $written = 0;
  } elsif ($l =~ /.basicAuthenticationPassword=/) {
    my $pos = index($l, "=") + 1;
    $password = substr($l, $pos);
    $written = 0;
  }
}

if (! $written) {
  $url =~ s|^(http[s]*://)|$1$user\:$password\@| if(defined $user && defined $password);
  push (@urlArray, $url);
  push (@postArray, $postType);
  push (@dataArray, $postData);
  $user = undef;
  $password = undef;
  $written = 1;   
}

if ($format eq "W") {
  output_webtransact();
} else {
  output_list();
}

exit(0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_webtransact() {
  open (OUTFILE, ">$outfile") || die ("Could not open webtransact output file");
  print OUTFILE "\@URLS = (\n";

  for(my $c = 0, my $t = 1; $c < @urlArray; $c++) {
    if (! ($urlArray[$c] =~ /(\.(gif|jpg|png|css|ico|js|bmp)|(robots\.txt))$/i) ) {
	  my($tUrl, $tParams)   = split(/\?/, $urlArray[$c]);  
	  my(undef, $tFilename) = $tUrl =~ m/(.*\/)(.*)$/;
      my $Qs_fixed = '';

      if (defined $tParams && $tParams ne '') {
        my @tArray = split(/&/, $tParams);
        $Qs_fixed .= build_QS_fixed(\@tArray);
      }
		 
      if($postArray[$c] eq 'POST') {
        $Qs_fixed .= ", " if($Qs_fixed ne ''); 

        if ( defined $dataArray[$c] and  $dataArray[$c] ne '') {
		  my @tArray = split(/&/, $dataArray[$c]);
          $Qs_fixed .= build_QS_fixed(\@tArray);
        }
      }
		 
      print OUTFILE "  { Method => '" . $postArray[$c] . "', Url => \"" . URLDecode(PERLDecode($tUrl)) . "\", Qs_var => [], Qs_fixed => [$Qs_fixed], Exp => '<NIHIL>', Exp_Fault => EXP_FAULT, Msg => '$tFilename', Msg_Fault => MSG_FAULT, Perfdata_Label => '[". sprintf("%02d", $t++) ."] $tFilename' },\n";
    }
  }

  print OUTFILE ");\n\n";
  close (OUTFILE);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub build_QS_fixed($) {
  my $tArray   = shift;

  my $Qs_fixed = '';

  if ( defined @$tArray ) {
	foreach my $line (@$tArray) {
	  my ($name, $value) = split(/=/, $line);

      if (! defined $value) { $value = ''; }
      $Qs_fixed .= ", " if($Qs_fixed ne '');
      $Qs_fixed .= "'" . URLDecode($name) . "'" . " => " . "'" . URLDecode($value) . "'";
	}
  }  

  return $Qs_fixed;
}
  
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
sub URLDecode {
    my $theURL = $_[0];
    $theURL =~ tr/+/ /;
    $theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $theURL =~ s/<!--(.|\n)*-->//g;
    return $theURL;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub PERLDecode {
	my $theURL = $_[0];
	$theURL =~ s|\@|\\@|g;
	return $theURL;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub output_list() {
  open (OUTFILE, ">$outfile") || die ("Could not open list output file");

  for(my $c = 0; $c < @urlArray; $c++) {
    if (! ($urlArray[$c] =~ /(\.(gif|jpg|png|css|ico|js|bmp)|(robots\.txt))$/i) ) {
	  my $tUrl = URLDecode($urlArray[$c]);

      if($postArray[$c] eq "POST") {
	  	if ( defined $dataArray[$c] and  $dataArray[$c] ne '') {
	      print OUTFILE "$postArray[$c]" . " - " . $tUrl . ( ($tUrl =~ /\?/) ? '&' : '?' ) . URLDecode($dataArray[$c]) . "\n";
		} else {
		  print OUTFILE "$postArray[$c]" . " - " . $tUrl . "\n";
		}
      } else {
        print OUTFILE "$postArray[$c]" . "  - " . $tUrl . "\n";
      }
    }
  }

  close (OUTFILE);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage() {
  print "Usage: $PROGNAME \n        -i <input-file> \n        -o <output-file> \n       [-f L|W], W default \n       [-v version] \n       [-h help]\n\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_revision() {
  print "\nThis is $PROGNAME, v$version\n";
  print "Copyright (c) 2004-2007 Yves Van den Hove\n\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help() {
  print_revision();
  print_usage();
  print "Send an email to yvdhove\@users.sourceforge.net if you have any questions regarding the use of this software.\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
