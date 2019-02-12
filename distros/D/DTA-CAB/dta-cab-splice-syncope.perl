#!/usr/bin/perl -w

use lib qw(.);
use DTA::CAB;
use DTA::CAB::Utils ':all';
use DTA::CAB::Format;
use DTA::CAB::Analyzer::SynCoPe;
use Encode qw(encode decode);
use File::Basename qw(basename);
use IO::File;
use Getopt::Long qw(:config no_ignore_case);
use Time::HiRes qw(gettimeofday tv_interval);
use Pod::Usage;

##==============================================================================
## Constants & Globals
##==============================================================================

##-- program identity
our $prog = basename($0);
our $VERSION = $DTA::CAB::VERSION;

##-- General Options
our ($help,$man,$version,$verbose);
#$verbose = 'default';
our $doprofile = 0; ##-- compatibility only; has no other effect

#BEGIN {
#  binmode($DB::OUT,':utf8') if (defined($DB::OUT));
#  binmode(STDIN, ':utf8');
#  binmode(STDOUT,':utf8');
#  binmode(STDERR,':utf8');
#}

##-- Formats
our $inputClass  = undef;  ##-- default input format class
our $outputClass = undef;  ##-- default output format class
our %inputOpts   = ();
our %outputOpts  = (level=>0, output_ner=>1);
our $doProfile   = 1;

our $outfile = '-';
our $splice_label = 'syncope';

##==============================================================================
## Command-line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'man|m'     => \$man,
	   'version|V' => \$version,
	   
           ##-- I/O: common
           'format-class|fc=s' => sub { $inputClass=$outputClass=$_[1]; },
           'format-option|fo=s%' => sub { $inputOpts{$_[1]} = $outputOpts{$_[1]} = $_[2]; },
           
	   ##-- I/O: input
	   'input-class|ifc|ic=s'       => \$inputClass,
	   'input-option|ifo|io=s'      => \%inputOpts,

	   ##-- I/O: output
	   'output-class|ofc|oc=s'        => \$outputClass,
	   'output-option|oo=s'                       => \%outputOpts,
	   'output-level|ol|format-level|fl=s'        => \$outputOpts{level},
	   'output-file|output|o=s' => \$outfile,

	   ##-- splice options
	   'splice-label|sl|label|l=s' => \$splice_label,

	   ##-- Log4perl
	   DTA::CAB::Logger->cabLogOptions('verbose'=>1),
	  );

if ($version) {
  print cab_version;
  exit(0);
}

pod2usage({-exitval=>0, -verbose=>1}) if ($man);
pod2usage({-exitval=>0, -verbose=>0}) if ($help);

push(@ARGV,'-') if (!@ARGV);
our $sxmlfile = shift(@ARGV); ##-- syncope xml file

##==============================================================================
## MAIN
##==============================================================================

##-- log4perl initialization
DTA::CAB::Logger->logInit();


##======================================================
## Input & Output Formats

$ifmt = DTA::CAB::Format->newReader(class=>$inputClass,file=>$ARGV[0],%inputOpts)
  or die("$0: could not create input parser of class $inputClass: $!");

$ofmt = DTA::CAB::Format->newWriter(class=>$outputClass,file=>$outfile,%outputOpts)
  or die("$0: could not create output formatter of class $outputClass: $!");

#DTA::CAB->debug("using input format class ", ref($ifmt));
#DTA::CAB->debug("using output format class ", ref($ofmt));

##======================================================
## Churn data

##-- profiling
our $ielapsed = 0;
our $oelapsed = 0;

push(@ARGV,'-') if (!@ARGV);
$ofmt->toFile($outfile);

##-- slurp xmlfile
my $sxmlbuf='';
{
  open(SXML,"<$sxmlfile")
    or DTA::CAB->logconfess("open failed for SynCoPe XML file '$sxmlfile': $!");
  local $/ = undef;
  $sxmlbuf = <SXML>;
  close SXML;
}

our ($file,$doc);
our ($ntoks,$nchrs) = (0,0);

##-- read
$file = shift(@ARGV),
$t0 = [gettimeofday];
$doc = $ifmt->parseFile($file)
  or die("$0: parse failed for input file '$file': $!");
$ifmt->close();

##-- splice
my $anl = DTA::CAB::Analyzer::SynCoPe->new(label=>$splice_label);
$doc = $anl->spliceback($doc, \$sxmlbuf)
  or die("$prog: ERROR splicing parse-data from $sxmlfile to CAB-doc from $file");

##-- write
$t1 = [gettimeofday];
$ofmt->putDocumentRaw($doc);

if ($doProfile) {
  $ielapsed += tv_interval($t0,$t1);
  $oelapsed += tv_interval($t1,[gettimeofday]);

  $ntoks += $doc->nTokens;
  $nchrs += (-s $file) if ($file ne '-' && -e $file);
}

##-- final output
$t1 = [gettimeofday];
$ofmt->flush->close();
$oelapsed  += tv_interval($t1,[gettimeofday]);

##-- profiling
if ($doProfile) {
  $ifmt->info("Profile: input:");
  $ifmt->logProfile('info', $ielapsed, $ntoks, $nchrs);

  $ofmt->info("Profile: output:");
  $ofmt->logProfile('info', $oelapsed, $ntoks, $nchrs);
}

__END__
=pod

=head1 NAME

dta-cab-splice-syncope.perl - splice syncope xml analyses back into CAB documents

=head1 SYNOPSIS

 dta-cab-splice-syncope.perl [OPTIONS...]   SYNCOPE_XML_FILE   CAB_DOCUMENT_FILE

 General Options:
  -help                           ##-- show short usage summary
  -man                            ##-- show longer help message
  -version                        ##-- show version & exit
  -verbose LEVEL                  ##-- set default log level
  -profile , -noprofile           ##-- do/don't profile I/O classes (default=do)

 I/O Options
  -input-class CLASS              ##-- select input parser class (default: Text)
  -input-option OPT=VALUE         ##-- set input parser option

  -output-class CLASS             ##-- select output formatter class (default: Text)
  -output-option OPT=VALUE        ##-- set output formatter option
  -output-level LEVEL             ##-- override output formatter level (default: 1)
  -output-file FILE               ##-- set output file (default: STDOUT)

  -label LABEL                    ##-- analyzer label for splice (default: 'syncope')

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

not yet written.

=cut

##==============================================================================
## Options and Arguments
##==============================================================================
=pod

=head1 OPTIONS AND ARGUMENTS

not yet written.

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2019 by Bryan Jurish. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<dta-cab-cachegen.perl(1)|dta-cab-cachegen.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
