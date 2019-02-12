#!/usr/bin/perl -w

use lib qw(.);
use DTA::CAB;
use DTA::CAB::Utils ':all';
use DTA::CAB::Format;
use JSON::XS;
use File::Basename qw(basename);
use IO::File;
use Getopt::Long qw(:config no_ignore_case);
use Time::HiRes qw(gettimeofday tv_interval);
use Pod::Usage;

use strict;

##==============================================================================
## Constants & Globals
##==============================================================================

##-- program identity
our $prog = basename($0);
our $VERSION = $DTA::CAB::VERSION;

##-- General Options
our ($help,$man,$version,$verbose);

##-- Formats
our $inputClass  = undef;  ##-- default input format class
our %inputOpts   = ();
our $block       = undef;  ##-- block specification; default: format-dependent
our $outfile     = '-';

##==============================================================================
## Command-line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'version|V' => \$version,

	   ##-- I/O: input
	   'input-class|ic|parser-class|pc=s'   => \$inputClass,
	   'input-option|io|parser-option|po=s' => \%inputOpts,
	   'block|block-size|bs|b=s'            => \$block,

	   ##-- I/O: output
	   'output-file|output|o=s' => \$outfile,

	   ##-- Log4perl
	   DTA::CAB::Logger->cabLogOptions('verbose'=>1),
	  );

if ($version) {
  print cab_version;
  exit(0);
}

pod2usage({-exitval=>0, -verbose=>0}) if ($help);


##==============================================================================
## MAIN
##==============================================================================

##-- log4perl initialization
DTA::CAB::Logger->logInit();

##======================================================
## Formats

our $ifmt = DTA::CAB::Format->newReader(class=>$inputClass,file=>$ARGV[0],%inputOpts)
  or die("$0: could not create input format of class $inputClass: $!");

##======================================================
## Main

##-- output
our $jxs = JSON::XS->new->utf8->indent(0)->space_before(0)->space_after(1)->canonical(1);
open(OUT,">$outfile") or die("$prog: open failed for output file '$outfile': $!");

##-- main loop
push(@ARGV,'-') if (!@ARGV);
my %blockOpts = $ifmt->blockOptions($block);
my ($file,$blocks);
foreach $file (@ARGV) {
  $blocks = $ifmt->blockScan($file, %blockOpts);

  ##-- write in pseudo-tj format
  foreach (@$blocks) {
    delete($_->{file});
    print OUT $file, "\t", $jxs->encode($_), "\n";
  }
  print OUT "\n";
}
close OUT;

__END__
=pod

=head1 NAME

dta-cab-blockscan.perl - scan for block boundaries in DTA::CAB documents

=head1 SYNOPSIS

 dta-cab-blockscan.perl [OPTIONS...] DOCUMENT_FILE(s)...

 General Options:
  -help                           ##-- show short usage summary
  -version                        ##-- show version & exit
  -verbose LEVEL                  ##-- set default log level

 I/O Options:
  -input-class CLASS              ##-- select input parse class (default: TT)
  -input-option OPT=VALUE         ##-- set input parser option
  -block SIZE[{k,M,G,T}][@EOB]    ##-- select block boundary specification (default: format-dependent)
  -output-file FILE               ##-- set output file (default: STDOUT)

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

dta-cab-blockscan.perl is a command-line utility for testing the
DTA::CAB block-wise I/O API.

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

=item -output-file FILE

Set output file (default: STDOUT).
Output is written in L<DTA::CAB::Format::TJ|DTA::CAB::Format::TJ> format,
where each "sentence" represents a single input file, and each "token"
represents a single I/O block.  Token "text" is the filename, and block
attributes are returned as JSON in the token attribute field.

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

Copyright (C) 2011-2019  by Bryan Jurish. All rights reserved.
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
