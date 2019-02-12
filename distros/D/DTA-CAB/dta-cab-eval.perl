#!/usr/bin/perl -w

use lib qw(.);
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
our %outputOpts  = (level=>0);
our $doProfile   = 1;

our $outfile = '-';

our @eval_code = qw();
our @begin_code = qw();
our @end_code = qw();


##==============================================================================
## Command-line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'man|m'     => \$man,
	   'version|V' => \$version,
	   'profile|prof!' => \$doProfile,

	   ##-- I/O: input
	   'input-class|ic|parser-class|pc=s'        => \$inputClass,
	   #'input-encoding|ie|parser-encoding|pe=s'  => \$inputOpts{encoding},
	   'input-option|io|parser-option|po=s'      => \%inputOpts,

	   ##-- I/O: output
	   'output-class|oc|format-class|fc=s'        => \$outputClass,
	   #'output-encoding|oe|format-encoding|fe=s'  => \$outputOpts{encoding},
	   'output-option|oo=s'                       => \%outputOpts,
	   'output-level|ol|format-level|fl=s'        => \$outputOpts{level},
	   'output-file|output|o=s' => \$outfile,

	   ##-- behavior
	   'eval|e=s' => \@eval_code,
	   'begin|B=s' => \@begin_code,
	   'end|E=s' => \@end_code,
	   'module|M=s' => sub { push(@begin_code,"use $_[1];"); },

	   ##-- Log4perl
	   DTA::CAB::Logger->cabLogOptions('verbose'=>1),
	  );

if ($version) {
  print cab_version;
  exit(0);
}

pod2usage({-exitval=>0, -verbose=>1}) if ($man);
pod2usage({-exitval=>0, -verbose=>0}) if ($help);
pod2usage({-exitval=>1, -verbose=>1, -msg=>'-eval (-e) option is required!'}) if (!@eval_code);


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

##-- begin code
if (@begin_code) {
  my $code = join("; ", @begin_code);
  eval $code;
  die("$prog: error evaluating BEGIN_CODE=\`$code': $@") if ($@);
}
$eval_str = join("; ", @eval_code);

our ($file,$doc);
our ($ntoks,$nchrs) = (0,0);
foreach $file (@ARGV) {

  ##-- read
  $t0 = [gettimeofday];
  $doc = $ifmt->parseFile($file)
    or die("$0: parse failed for input file '$file': $!");
  $ifmt->close();

  ##-- munge
  eval $eval_str;
  die("$prog: error evaluating EVAL_CODE=\`$eval_str' for '$file': $@") if ($@);

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

##-- end code
if (@end_code) {
  my $code = join("; ", @end_code);
  eval $code;
  die("$prog: error evaluating END_CODE=\`$code': $@") if ($@);
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

dta-cab-eval.perl - munge DTA::CAB documents

=head1 SYNOPSIS

 dta-cab-eval.perl [OPTIONS...] DOCUMENT_FILE(s)...

 General Options:
  -help                           ##-- show short usage summary
  -man                            ##-- show longer help message
  -version                        ##-- show version & exit
  -verbose LEVEL                  ##-- set default log level
  -profile , -noprofile           ##-- do/don't profile I/O classes (default=do)

 Code Options:
  -eval CODE			  ##-- evaluate CODE for each document $doc (required)
  -begin CODE			  ##-- intialization CODE
  -end CODE			  ##-- finalization CODE
  -module MODULE		  ##-- alias for -begin 'use MODULE;'

 I/O Options
  -input-class CLASS              ##-- select input parser class (default: Text)
  -input-option OPT=VALUE         ##-- set input parser option

  -output-class CLASS             ##-- select output formatter class (default: Text)
  -output-option OPT=VALUE        ##-- set output formatter option
  -output-level LEVEL             ##-- override output formatter level (default: 1)
  -output-file FILE               ##-- set output file (default: STDOUT)

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

dta-cab-convert.perl provides a command-line interface for tweaking, munging,
frobbing, and/or squelching documents supported by the L<DTA::CAB|DTA::CAB> analysis suite.

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

=item -eval CODE

Evaluate CODe for each document C<$doc>.  Required.

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
