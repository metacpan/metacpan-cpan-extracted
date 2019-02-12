#!/usr/bin/perl -w

use lib qw(.);
use DTA::CAB::Format::TEIws; ##-- DEBUG

use DTA::CAB;
use DTA::CAB::Utils ':all';
use DTA::CAB::Format;
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
our %outputOpts  = (level=>undef); ##-- use class default
our $doProfile   = 1;
our $listOnly    = 0; ##-- only list formats?

our $outfile = '-';

##==============================================================================
## Command-line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'man|m'     => \$man,
	   'version|V' => \$version,
	   'profile|prof!' => \$doProfile,
	   'list|l!' => \$listOnly,

	   ##-- I/O: input
	   'input-class|ic|input-format-class|ifc=s'        => \$inputClass,
	   'input-option|io|input-format-option|ifo=s'      => \%inputOpts,

	   ##-- I/O: output
	   'output-class|oc|output-format-class|ofc=s'        		      => \$outputClass,
	   'output-option|oo|output-format-option|ofo=s'                      => \%outputOpts,
	   'output-level|ol|format-level|fl|output-format-level|ofl=s'        => \$outputOpts{level},
	   'output-file|of|output|o=s' => \$outfile,

	   ##-- I/O: generic
	   'format-class|fc=s'   => sub { $inputClass=$outputClass=$_[1]; },
	   'format-option|fo=s%' => sub { $inputOpts{$_[1]}=$outputOpts{$_[1]}=$_[2]; },

	   ##-- Log4perl
	   DTA::CAB::Logger->cabLogOptions('verbose'=>1),
	  );

if ($version) {
  print cab_version;
  exit(0);
}

pod2usage({-exitval=>0, -verbose=>1}) if ($man);
pod2usage({-exitval=>0, -verbose=>0}) if ($help);


##==============================================================================
## MAIN
##==============================================================================

##-- log4perl initialization
DTA::CAB::Logger->logInit();

##======================================================
## List ?
sub maxlen {
  my $max=0;
  foreach (grep {defined($_)} @_) { $max=length($_) if (length($_)>$max); }
  return $max;
}
if ($listOnly) {
  my $reg = $DTA::CAB::Format::REG->{reg};
  my $lshort = maxlen("#CLASS", map {$_->{name}} @$reg)+1;
  my $llong  = maxlen("#ALIAS", map {$_->{short}} @$reg)+1;
  #my $lre    = maxlen("#REGEX", map {"$_->{filenameRegex}"} @$reg)+1;
  my $lfmt   = "%-${lshort}s  %-${llong}s  %s\n";
  printf $lfmt, '#CLASS','#ALIAS','#REGEX';
  foreach (@$reg) {
    printf $lfmt, map {defined($_) ? $_ : '-'} @$_{qw(name short filenameRegex)};
  }
  exit 0;
}


##======================================================
## Input & Output Formats

$ifmt = DTA::CAB::Format->newReader(class=>$inputClass,file=>$ARGV[0],%inputOpts)
  or die("$0: could not create input parser of class $inputClass: $!");

delete($outputOpts{level}) if (!defined($outputOpts{level}));
$ofmt = DTA::CAB::Format->newWriter(class=>$outputClass,file=>$outfile,%outputOpts)
  or die("$0: could not create output formatter of class $outputClass: $!");

DTA::CAB->debug("using input format class ", ref($ifmt));
DTA::CAB->debug("using output format class ", ref($ofmt));

##======================================================
## Churn data

##-- profiling
our $ielapsed = 0;
our $oelapsed = 0;

our ($file,$doc);
our ($ntoks,$nchrs) = (0,0);
push(@ARGV,'-') if (!@ARGV);
$ofmt->toFile($outfile);

foreach $file (@ARGV) {

  ##-- read
  $t0 = [gettimeofday];
  $doc = $ifmt->parseFile($file)
    or die("$0: parse failed for input file '$file': $!");
  $ifmt->close();

  ##-- write
  $t1 = [gettimeofday];
  $ofmt->putDocumentRaw($doc);

  if ($doProfile) {
    $ielapsed += tv_interval($t0,$t1);
    $oelapsed += tv_interval($t1,[gettimeofday]);

    $ntoks += $doc->nTokens;
    $nchrs += (-s $file) if ($file ne '-' && -e $file);
  }
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

dta-cab-convert.perl - Format conversion for DTA::CAB documents

=head1 SYNOPSIS

 dta-cab-convert.perl [OPTIONS...] DOCUMENT_FILE(s)...

 General Options:
  -help                           ##-- show short usage summary
  -man                            ##-- show longer help message
  -version                        ##-- show version & exit
  -list                           ##-- list all registered output formats and exit
  -verbose LEVEL                  ##-- set default log level
  -profile , -noprofile           ##-- do/don't profile I/O classes (default=do)

 I/O Options
  -input-class CLASS              ##-- select input parser class (default: Text)
  -input-option OPT=VALUE         ##-- set input parser option

  -output-class CLASS             ##-- select output formatter class (default: Text)
  -output-option OPT=VALUE        ##-- set output formatter option
  -output-level LEVEL             ##-- override output formatter level (default: 1)
  -output-file FILE               ##-- set output file (default: STDOUT)

  -format-class CLASS	          ##-- alias for -input-class=CLASS -output-class=CLASS
  -format-option OPT=VALUE        ##-- alias for -input-option=OPT=VALUE -output-option=OPT=VALUE

 Logging Options                  ##-- see Log::Log4perl(3pm)
  -log-level LEVEL                ##-- set minimum log level (default=TRACE)
  -log-stderr , -nolog-stderr     ##-- do/don't log to stderr (default=true)
  -log-syslog , -nolog-syslog     ##-- do/don't log to syslog (default=false)
  -log-file LOGFILE               ##-- log directly to FILE (default=none)
  -log-rotate , -nolog-rotate     ##-- do/don't auto-rotate log files (default=true)
  -log-config L4PFILE             ##-- log4perl config file (overrides -log-stderr, etc.)
  -log-watch  , -nowatch          ##-- do/don't watch log4perl config file (default=false)
  -log-option OPT=VALUE           ##-- set any logging option (e.g. -log-option twlevel=trace)

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

dta-cab-convert.perl provides a command-line interface for conversion
between various formats supported by the L<DTA::CAB|DTA::CAB> analysis suite.

=cut

##==============================================================================
## Options and Arguments
##==============================================================================
=pod

=head1 OPTIONS AND ARGUMENTS

=cut

##==============================================================================
## Options: General Options
=pod

=head2 General Options

=over 4

=item -help

Display a short help message and exit.

=item -man

Display a longer help message and exit.

=item -version

Display program and module version information and exit.

=item -verbose

Set default log level (trace|debug|info|warn|error|fatal).

=back

=cut

##==============================================================================
## Options: I/O Options
=pod

=head2 I/O Options

=over 4

=item -input-class CLASS

Select input parser class (default: Text)

=item -input-option OPT=VALUE

Set arbitrary input parser option C<OPT> to C<VALUE>.
May be multiply specified.

=item -output-class CLASS

Select output formatter class (default: Text).

=item -output-option OPT=VALUE

Set output formatter option C<OPT> to C<VALUE>.
May be multiply specified.

=item -output-level LEVEL

Override output formatter level (default: 1).

=item -output-file FILE

Set output file (default: STDOUT)

=back

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

Copyright (C) 2009-2019 by Bryan Jurish. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
