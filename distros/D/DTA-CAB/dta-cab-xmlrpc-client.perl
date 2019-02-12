#!/usr/bin/perl -w

use lib qw(.);
use DTA::CAB;
use DTA::CAB::Client::XmlRpc;
use DTA::CAB::Utils ':all';
use Encode qw(encode decode);
use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use Time::HiRes qw(gettimeofday tv_interval);
use IO::File;
use Pod::Usage;

##==============================================================================
## DEBUG
##==============================================================================
#do "storable-debug.pl" if (-f "storable-debug.pl");

##==============================================================================
## Constants & Globals
##==============================================================================

##-- program identity
our $prog = basename($0);
our $VERSION = $DTA::CAB::VERSION;

##-- General Options
our ($help,$man,$version,$verbose);
#$verbose = 'default';

##-- Log options
our %logOpts = (rootLevel=>'WARN', level=>'INFO'); ##-- options for DTA::CAB::Logger::ensureLog()

##-- Client Options
our $serverURL  = 'http://localhost:8088/xmlrpc';
#our $serverEncoding = 'UTF-8';
#our $localEncoding  = 'UTF-8';
our $timeout = 65535;   ##-- wait for a *long* time (65535 = 2**16-1 ~ 18.2 hours)
our $test_connect = 1;

##-- Analysis & Action Options
our $analyzer = 'dta.cab.default';
our $action = 'list';
our %analyzeOpts = qw();    ##-- currently unused
our $doProfile = undef;

##-- I/O Options
our $inputClass  = undef;  ##-- default parser class
our $outputClass = undef;  ##-- default format class
our %inputOpts   = ();
our %outputOpts  = (level=>0);
our $outfile     = '-';

our $bench_iters = 1; ##-- number of benchmark iterations for -bench mode
our $trace_request_file = undef; ##-- trace request to file?

##==============================================================================
## Command-line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'man|m'     => \$man,
	   'version|V' => \$version,

	   ##-- Client Options
	   'server-url|serverURL|server|url|s|u=s' => \$serverURL,
	   #'local-encoding|le=s'  => \$localEncoding,
	   #'server-encoding|se=s' => \$serverEncoding,
	   'timeout|T=i' => \$timeout,
	   'test-connect|tc!' => \$test_connect,

	   ##-- Analysis Options
	   'analyzer|a=s' => \$analyzer,
	   'analysis-option|analyze-option|ao|O=s' => \%analyzeOpts,
	   'profile|p!' => \$doProfile,
	   'list|l'   => sub { $action='list'; },
	   'token|t|word|w' => sub { $action='token'; },
	   'sentence|S' => sub { $action='sentence'; },
	   'document|d' => sub { $action='document'; },
	   'data|D' => sub { $action='data'; }, ##-- server-side parsing
	   #'raw|r' => sub { $action='raw'; },
	   'bench|b:i' => sub { $action='bench'; $bench_iters=$_[1]; },

	   ##-- I/O: input
	   'input-class|ic|parser-class|pc=s'        => \$inputClass,
	   'input-option|io|parser-option|po=s'     => \%inputOpts,

	   ##-- I/O: output
	   'output-class|oc|format-class|fc=s'        => \$outputClass,
	   #'output-encoding|oe|format-encoding|fe=s'  => \$outputOpts{encoding},
	   'output-option|oo=s'                       => \%outputOpts,
	   'output-level|ol|format-level|fl=s'      => \$outputOpts{level},
	   'output-file|output|o=s' => \$outfile,

	   ##-- debugging
	   'trace-request|trace|request|tr=s' => \$trace_request_file,

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

##-- sanity checks
$serverURL = "http://$serverURL" if ($serverURL !~ m|[^:]+://|);
if ($serverURL =~ m|([^:]+://[^/:]*)(/[^:]*)$|) {
  $serverURL = "$1:8088$2";
}

##-- trace request file?
our $tracefh = undef;
if (defined($trace_request_file)) {
  $tracefh = IO::File->new(">$trace_request_file")
    or die("$0: open failed for trace file '$trace_request_file': $!");
}

##-- create client object
our $cli = DTA::CAB::Client::XmlRpc->new(
					 serverURL=>$serverURL,
					 serverEncoding=>'UTF-8',
					 timeout=>$timeout,
					 tracefh=>$tracefh,
					 testConnect => $test_connect,
					);
$cli->connect() or die("$0: connect() failed: $!");


##======================================================
## Input & Output Formats

$ifmt = DTA::CAB::Format->newReader(class=>$inputClass,($action =~ m(raw|doc) ? (file=>$ARGV[0]) : qw()),%inputOpts)
  or die("$0: could not create input parser of class $inputClass: $!");

$ofmt = DTA::CAB::Format->newWriter(class=>$outputClass,($action !~ m(list) ? (file=>$outfile) : qw()),%outputOpts)
  or die("$0: could not create output formatter of class $outputClass: $!");

DTA::CAB->debug("using input format class ", ref($ifmt));
DTA::CAB->debug("using output format class ", ref($ofmt));

##-- output file
our $outfh = IO::File->new(">$outfile")
  or die("$0: open failed for output file '$outfile': $!");

##======================================================
## Profiling

our $ntoks = 0;
our $nchrs = 0;

our @tv_values = qw();
sub profile_start {
  return if (scalar(@tv_values) % 2 != 0); ##-- timer already running
  push(@tv_values,[gettimeofday]);
}
sub profile_stop {
  return if (scalar(@tv_values) % 2 == 0); ##-- timer already stopped
  push(@tv_values,[gettimeofday]);
}
sub profile_elapsed {
  my ($started,$stopped);
  my @values = @tv_values;
  my $elapsed = 0;
  while (@values) {
    ($started,$stopped) = splice(@values,0,2);
    $stopped  = [gettimeofday] if (!defined($stopped));
    $elapsed += tv_interval($started,$stopped);
  }
  return $elapsed;
}

profile_start() if ($doProfile);

##======================================================
## Actions
$ofmt->toFh($outfh);

if ($action eq 'list') {
  ##-- action: list
  my @anames = $cli->analyzers;
  $outfh->print("$0: analyzer list for $serverURL\n", map { "$_\n" } @anames);
}
elsif ($action eq 'token') {
  ##-- action: 'tokens'
  $doProfile = 0;
  foreach $tokin (map {DTA::CAB::Utils::deep_decode('UTF-8',$_)} @ARGV) {
    $tokout = $cli->analyzeToken($analyzer, $tokin, \%analyzeOpts);
    $ofmt->putTokenRaw($tokout);
  }
}
elsif ($action eq 'sentence') {
  ##-- action: 'sentence'
  $doProfile = 0;
  our $s_in  = DTA::CAB::Utils::deep_decode('UTF-8',[@ARGV]);
  our $s_out = $cli->analyzeSentence($analyzer, $s_in, \%analyzeOpts);
  $ofmt->putSentenceRaw($s_out);
}
elsif ($action eq 'document') {
  ##-- action: 'document': interpret args as filenames & parse 'em!
  our ($d_in,$d_out,$s_out);
  foreach $doc_filename (@ARGV) {
    $d_in = $ifmt->parseFile($doc_filename)
      or die("$0: parse failed for input file '$doc_filename': $!");
    $d_out = $cli->analyzeDocument($analyzer, $d_in, \%analyzeOpts);
    $ofmt->putDocumentRaw($d_out);
    if ($doProfile) {
      $ntoks += $d_out->nTokens();
      $nchrs += (-s $doc_filename);
    }
  }
}
elsif ($action eq 'data') {
  ##-- action: 'data': do server-side parsing
  our ($s_in,$s_out);
  %analyzeOpts = (
		  %analyzeOpts,
		  reader => {%inputOpts, class=>$inputClass},
		  writer => {%outputOpts,class=>$outputClass},
		 );

  foreach $doc_filename (@ARGV) {
    open(DOC,"<$doc_filename") or die("$0: open failed for input file '$doc_filename': $!");
    {
      local $/=undef;
      $s_in = <DOC>;
    }
    close(DOC);
    $s_out = $cli->analyzeData($analyzer, $s_in, {%analyzeOpts, inputClass=>$inputClass, outputClass=>$outputClass});
    $outfh->print( $s_out );
    if ($doProfile) {
      $nchrs += length($s_in);
      ##-- count tokens, pausing profile timer
      profile_stop();
      $ntoks += $ofmt->parseString($s_out)->nTokens;
      profile_start();
    }
  }
}
#elsif ($action eq 'raw') {
#  ##-- action: 'raw': use raw request
#  die("$0: -raw option not yet implemented!");
#}
elsif ($action eq 'bench') {
  $doProfile=1;
  our ($bench_i);
  our ($d_in,$w_in,$w_out);
  $bench_iters = 1 if (!$bench_iters);
  foreach $doc_filename (@ARGV) {
    $d_in = $ifmt->parseFile($doc_filename)
      or die("$0: parse failed for input file '$doc_filename': $!");
      foreach $bench_i (1..$bench_iters) {
	profile_start();
	foreach $w_in (map {@{$_->{tokens}}} @{$d_in->{body}}) {
	  $w_out = $cli->analyzeToken($analyzer, $w_in, \%analyzeOpts);
	}
	profile_stop();
      }
    #$ofmt->putDocumentRaw($d_out);
    if ($doProfile) {
      $ntoks += $bench_iters * $d_in->nTokens();
      $nchrs += $bench_iters * (-s $doc_filename);
    }
  }
}
else {
  die("$0: unknown action '$action'");
}
$cli->disconnect();

##-- profiling
DTA::CAB::Logger->logProfile('info', profile_elapsed, $ntoks, $nchrs) if ($doProfile);
DTA::CAB::Logger->trace("client exiting normally.");

__END__
=pod

=head1 NAME

dta-cab-xmlrpc-client.perl - XML-RPC client for DTA::CAB server queries

=head1 SYNOPSIS

 dta-cab-xmlrpc-client.perl [OPTIONS...] ARGUMENTS

 General Options:
  -help                           ##-- show short usage summary
  -man                            ##-- show longer help message
  -version                        ##-- show version & exit
  -verbose LEVEL                  ##-- set default log level

 Client Options:
  -server URL                     ##-- set server URL (default: http://localhost:8088/xmlrpc)
  -timeout SECONDS                ##-- set server timeout in seconds (default: lots)
  -test-connect , -notest-connect ##-- do/don't send a test query to the server (default: do)

 Analysis Options:
  -list                           ##-- just list registered analyzers (default)
  -analyzer NAME                  ##-- set analyzer name (default: 'dta.cab.default')
  -analyze-option OPT=VALUE       ##-- set analysis option (default: none)
  -profile , -noprofile           ##-- do/don't report profiling information (default: do)
  -token                          ##-- ARGUMENTS are token text
  -sentence                       ##-- ARGUMENTS are analyzed as a sentence
  -document                       ##-- ARGUMENTS are filenames, analyzed as documents
  -data                           ##-- ARGUMENTS are filenames, server-side parsing & formatting

 I/O Options:
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

dta-cab-xmlrpc-client.perl is a command-line client for L<DTA::CAB|DTA::CAB>
analysis of token(s), sentence(s), and/or document(s) by
querying a running L<DTA::CAB::Server::XmlRpc|DTA::CAB::Server::XmlRpc> server
with the L<DTA::CAB::Client::XmlRpc|DTA::CAB::Client::XmlRpc> module.

See L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl> for a
corresponding server.

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
## Options: Server Options
=pod

=head2 Server Options

=over 4

=item -server URL

Set server URL (default: localhost:8000).

=item -timeout SECONDS

Set server timeout in seconds (default: lots).

=back

=cut

##==============================================================================
## Options: Analysis Options
=pod

=head2 Analysis Options

=over 4

=item -list

Don't actually perform any analysis;
rather,
just print a list of analyzers registered with the server.
This is the default action.

=item -analyzer NAME

Request analysis by the analyzer registered under name NAME (default: 'dta.cab.default').

=item -analyze-option OPT=VALUE

Set an arbitrary analysis option C<OPT> to C<VALUE>.
May be multiply specified.

Available options depend on the analyzer class to be called.

=item -profile , -noprofile

Do/don't report profiling information (default: do).

=item -token

Interpret ARGUMENTS as token text.

=item -sentence

Interpret ARGUMENTS as a sentence (list of tokens).

=item -document

Interpret ARGUMENTS as filenames, to be analyzed as documents.

=item -data

Interpret ARGUMENTS as filenames (as for L</-document>),
but file contents are passed as raw strings to the server,
which then becomes responsible for parsing and formatting.

This is the recommended way to analyze large documents,
because of the large overhead
involved when the L</-document> option is used
(slow translations to and from complex XML-RPC structures).

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

Set an arbitrary input parser option.
May be multiply specified.

=item -output-class CLASS

Select output formatter class (default: Text)
May be multiply specified.

=item -output-option OPT=VALUE

Set an arbitrary output formatter option.
May be multiply specified.

=item -output-level LEVEL

Override output formatter level (default: 1).

=item -output-file FILE

Set output file (default: STDOUT).

=back

=cut


##======================================================================
## Footer
##======================================================================
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

RPC::XML by Randy J. Ray.

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
L<dta-cab-cachegen.perl(1)|dta-cab-cachegen.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<RPC::XML(3pm)|RPC::XML>,
L<perl(1)|perl>,
...

=cut
