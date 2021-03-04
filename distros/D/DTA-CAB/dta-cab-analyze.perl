#!/usr/bin/perl -w

use lib '.', 'MUDL';
use DTA::CAB;
use DTA::CAB::Utils ':all';
use DTA::CAB::Datum ':all';
use DTA::CAB::Queue::Server;
use DTA::CAB::Fork::Pool;
use File::Basename qw(basename dirname);
use File::Path qw(rmtree);
use File::Temp qw();
use File::Copy qw();
use IO::File;
use Getopt::Long qw(:config no_ignore_case);
use Time::HiRes qw(gettimeofday tv_interval);
use Pod::Usage;

#BEGIN { require "./CabOpt.pm"; }
use DTA::CAB::Chain::DTA;##-- DEBUG
#use DTA::CAB::Chain::DE_free;##-- DEBUG
#use DTA::CAB::Analyzer::MootSub; ##-- DEBUG
#use DTA::CAB::Format::TEIws; ##-- DEBUG

use strict;

##==============================================================================
## Constants & Globals
## ==============================================================================

##-- program identity
our $prog = basename($0);
our $VERSION = $DTA::CAB::VERSION;

##--------------------------------------------------------------
## Options: Main Process

##-- Options: Main: General
our ($help,$version,$verbose);
#$verbose = 'default';

##-- Options: eval
our @eval_begin = qw();
our @eval_onload = qw();
our @eval_end   = qw();

##-- Options: Main: forking options
our $njobs   = 0; ##-- default: 0 jobs (process everything in the main thread)
our $qpath   = tmpfsfile("dta_cab_q${$}_XXXX", UNLINK=>1);
our $keeptmp = 0;

##-- Options: Main: logging (see %DTA::CAB::Logger::defaultLogOpts)

##-- Options: Main: analysis
our $rcFile       = undef;
our $analyzeClass = 'DTA::CAB::Analyzer';

##-- Options: Main: I/O
our $inputList = 0;      ##-- inputs are command-line lists, not filenames (main thread only)

##-- Options: Main: block-wise
our $block_spec      = undef;     ##-- input block specification; see DTA::CAB::Format::blockOptions()
our %blockOpts       = qw();      ##-- parsed block options
our $logBlockInfo    = 'info';    ##-- log-level for block operations
our $logBlockTrace   = 'none';    ##-- log-level for block trace
our $logBlockProfile = 'none';    ##-- log-level for block profiling

##--------------------------------------------------------------
## Options: Subprocess Options

## %job : job-specific options
our %job =
  (
    ##-- Options: Child: Analysis
   analyzeOpts => {},
   doProfile   => 1,

   ##-- Options: Child: I/O
   inputClass  => undef,	##-- default parser class
   outputClass => undef,	##-- default format class
   inputWords  => 0,		##-- inputs are words, not filenames
   inputOpts   => {},
   outputOpts  => {level=>0},
   outfmt      => '-',		##-- output format

   ##-- Options: input (not here)
   input => undef,
  );

##==============================================================================
## Command-line

## %specs = globalOptionSpecs() : Getopt::Long specs only relevant for main thread
sub globalOptionSpecs {
  return
    (
     ##-- General
     'help|h'    => \$help,
     'version|V' => \$version,
     'module|M=s'  => sub {push(@eval_begin,"use $_[1];")},
     'eval-begin|begin|eb=s'  => \@eval_begin,
     'eval-onload|onload|el=s' => \@eval_onload,
     'eval-end|end|ee=s'      => \@eval_end,

     ##-- Parallelization
     'jobs|jn|j=i'                         => \$njobs,
     'job-queue|queue-path|qpath|jq|qp=s'  => \$qpath,
     'input-list|il|list|l!'               => \$inputList,
     'keeptmp|keeptemp|keep!'              => \$keeptmp,

     ##-- Block-wise processing
     'block|block-size|bs|b:s'             => sub {$block_spec=($_[1] || '')},
     'noblock|B'                           => sub { undef $block_spec; },
     'log-block-info|lbi|block-info|bi|log-block|lb=s' => \$logBlockInfo,
     'log-block-trace|block-trace|lbt|bt=s'            => \$logBlockTrace,
     'log-block-profile|lbp|block-profile|bp=s'        => \$logBlockProfile,
     'noblock-info|nobi'    => sub { $logBlockInfo='none'; },
     'noblock-trace|nobt'   => sub { $logBlockTrace='none'; },
     'noblock-profile|nobp' => sub { $logBlockProfile='none'; },


     ##-- Analysis
     'configuration|c=s'    => \$rcFile,
     'analyzer-class|analyze-class|analysis-class|ac|a=s' => \$analyzeClass,

     ##-- Log4perl stuff
     DTA::CAB::Logger->cabLogOptions('verbose'=>1),
    );
}

## %specs = childOptionSpecs() : Getopt::Long specs overridable by child threads
sub childOptionSpecs {
  return
    (
     ##-- Analysis
     'analyzer-option|analyze-option|analysis-option|ao|aO|O=s' => $job{analyzeOpts},
     'profile|p!' => \$job{doProfile},

     ##.. I/O: generic
     'format-class|fc=s' => sub {$job{inputClass}=$job{outputClass}=$_[1]},
     'format-option|fo=s%' => sub {$job{inputOpts}{$_[1]}=$job{outputOpts}{$_[1]}=$_[2]},

     ##-- I/O: input
     'input-format-class|iformat|ifmt|ifc|input-class|ic|parser-class|pc=s' => \$job{inputClass},
     'input-format-option|ifoption|ifo|input-option|io|parser-option|po=s'  =>  $job{inputOpts},
     'tokens|t|words|w!'                       => \$job{inputWords},

     ##-- I/O: output
     'output-format-class|oformat|ofmt|ofc|output-class|oc=s' => \$job{outputClass},
     'output-format-option|ofoption|ofo|output-option|oo=s'   =>  $job{outputOpts},
     'output-level|ol|format-level|fl=s'       => \$job{outputOpts}{level},
     'output-format|output-file|output|o=s'    => \$job{outfmt},
    );
}

GetOptions(globalOptionSpecs(), childOptionSpecs());
if ($version) {
  print cab_version;
  exit(0);
}

#pod2usage({-exitval=>0, -verbose=>1}) if ($man);
pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##==============================================================================
## MAIN: Initialize (main thread only)
##==============================================================================

##-- main: init: globals
our ($ifmt,$ofmt, $fp);

##-- save per-job overridable options
our $job0 = Storable::dclone(\%job);

##-- for cabeval stuff
our %analyzeOpts = %{$job0->{analyzeOpts}};

##-- main: init: log4perl
DTA::CAB::Logger->logInit();

##-- main: init: hack: set utf8 mode on stdio
binmode(STDOUT,':utf8');
binmode(STDERR,':utf8');

##------------------------------------------------------
## main: init: signals
sub cleandie {
  cleanup();
  exit(1);
}
$SIG{$_}=\&cleandie foreach (qw(TERM KILL HUP INT QUIT ABRT));

##------------------------------------------------------
## main: init: user code
foreach (@eval_begin) {
  eval "$_;";
  die("$prog: error evaluating user BEGIN code ($_): $@") if ($@);
}

##------------------------------------------------------
## main: init: analyzer
$analyzeClass = "DTA::CAB::Analyzer::$analyzeClass" if ($analyzeClass !~ /\:\:/);
eval "use $analyzeClass;";
if ($@ && !UNIVERSAL::can($analyzeClass,'new')) {
  $analyzeClass = "DTA::CAB::Analyzer::$analyzeClass";
  eval "use $analyzeClass;";
}
die("$prog: could not load analyzer class '$analyzeClass': $@") if ($@);
our ($cab);
if (defined($rcFile)) {
  DTA::CAB->debug("${analyzeClass}->loadFile($rcFile)");
  $cab = $analyzeClass->loadFile($rcFile)
    or die("$0: load failed for analyzer from '$rcFile': $!");
} else {
  DTA::CAB->debug("${analyzeClass}->new()");
  $cab = $analyzeClass->new(%{$job{analyzeOpts}})
    or die("$0: $analyzeClass->new() failed: $!");
}

foreach (@eval_onload) {
  eval "$_;";
  die("$prog: error evaluating user ONLOAD code ($_): $@") if ($@);
}

##------------------------------------------------------
## main: init: prepare (load data)
$cab->debug("prepare()");
$cab->prepare($job{analyzeOpts})
  or die("$0: could not prepare analyzer: $!");

##------------------------------------------------------
## main: init: formats (just report)
DTA::CAB->debug("using default input format class ", ref(new_ifmt()));
DTA::CAB->debug("using default output format class ", ref(new_ofmt()));

##------------------------------------------------------
## main: init: profiling
our $tv_started = [gettimeofday] if ($job{doProfile});

##======================================================================
## Subs: I/O

## $ext = file_extension($filename)
##  + returns file extension, including leading '.'
##  + returns empty string if no dot in filename
sub file_extension {
  my $file = shift;
  chomp($file);
  return $1 if (File::Basename::basename($file) =~ m/(\.[^\.]*)$/);
  return '';
}

## $outfile = outfilename($infile,$outfmt)
sub outfilename {
  my ($infile,$outfmt) = @_;
  return $outfmt if (!defined($infile));
  my $d = File::Basename::dirname($infile);
  my $b = File::Basename::basename($infile);
  my $x = '';
  if ($b =~ /^(.*)(\.[^\.\/]*)$/) {
    ($b,$x) = ($1,$2);
  }
  my $outfile = $outfmt;
  $outfile =~ s|%F|%d/%b|g;
  $outfile =~ s|%f|$infile|g;
  $outfile =~ s|%d|$d|g;
  $outfile =~ s|%b|$b|g;
  $outfile =~ s|%x|$x|g;
  return $outfile;
}

## $ifmt = new_ifmt()
## $ifmt = new_ifmt(%_job)
##   + %_job is a subprocess option hash like global %job (default)
sub new_ifmt {
  my %_job = (%job,@_);
  return ($ifmt = DTA::CAB::Format->newReader(class=>$_job{inputClass},file=>($_job{input}||$ARGV[0]),%{$_job{inputOpts}||{}}))
    || die("$0: could not create input parser of class $_job{inputClass}: $!");
}

## $ofmt = new_ofmt()
## $ofmt = new_ofmt(%_job)
##   + %_job is a subprocess option hash like global %job (default)
##   + uses %_job{outfile} to guess format from output filename
sub new_ofmt {
  my %_job = (%job,@_);
  my $outfile = outfilename(($_job{input}||$ARGV[0]), $_job{outfmt});
  return ($ofmt = DTA::CAB::Format->newWriter(class=>$_job{outputClass},file=>$outfile,%{$_job{outputOpts}||{}}))
    || die("$0: could not create output formatter of class $_job{outputClass}: $!");
}

##======================================================================
## Subs: child process callback(s)

## undef = resetOptions()
##  + resets global %job to a deep copy of %$job0
sub resetOptions {
  %job = %{Storable::dclone($job0)};
}

## undef = cb_init()
##  + child process initialization
sub cb_init {
  $fp->{fh}->close() if ($fp->{fh}->opened);
  @{$fp->{queue}} = @{$fp->{pids}} = %{$fp->{blocks}} = qw();
}

## undef = cb_work(\%qjob)
##  + worker callback for child threads
##  + queue dispatches jobs as HASH-refs \%qjob
##  + each \%qjob has a key (opts=>\%job) analagous to global %job
##  + additionally \%qjob has one of the following keys:
##    (
##     block => \%block,       ##-- (block-mode only): block specification as returned by $ifmt->blockScan(),
##     input => $input,        ##-- (file-mode only): job-specific input source (filename)
##     indoc => $indoc,        ##-- (words-mode only): input document
##    )
sub cb_work {
  my ($fp,$qjob) = @_;

  ##----------------------------------------------------
  ## parse job options
  %job = %{ $qjob->{opts} || $job0 };

  ##----------------------------------------------------
  ## Global (re-)initialization
  my $outfile = outfilename(($qjob->{input}||'out'),$job{outfmt}); ##-- may be overridden
  my $ntok=0;
  my $nchr=0;
  my $tv_jstarted = [gettimeofday];
  #DTA::CAB->logdie("dying to debug") if (!@{$fp->{pids}}); ##-- DEBUG

  ##----------------------------------------------------
  ## Input & Output Formats
  new_ifmt();
  new_ofmt();

  if ($qjob->{block}) {
    ##--------------------------------------------------
    ## Analyze: Block-wise
    my $blk   = $qjob->{block};
    $blk->{ofile} = $outfile if (!defined($blk->{ofile}));
    my $blkid = $blk->{blkid} || "$blk->{ifile} -> $blk->{ofile} [$blk->{id}[0]/$blk->{id}[1]]";
    $fp->vlog($logBlockInfo,"BLOCK $blkid");

    ##-- slurp & parse block input buffer
    $ifmt->vlog($logBlockTrace, "BLOCK $blkid: parseBlock()");
    my $doc = $ifmt->parseBlock($blk);
    #$ifmt->vlog($logBlockInfo, "BLOCK $blkid: parsed ", $doc->nTokens, " tok(s), ", scalar(@{$doc->{body}}), " sent(s)");

    ##-- analyze
    $cab->vlog($logBlockTrace, "BLOCK $blkid: analyzeDocument()");
    $doc = $cab->analyzeDocument($doc,$job{analyzeOpts});
    #$cab->vlog($logBlockInfo, "BLOCK $blkid: analyzed ", $doc->nTokens, " tok(s), ", scalar(@{$doc->{body}}), " sent(s)");

    ##-- output
    $ofmt->vlog($logBlockTrace, "BLOCK $blkid: putDocumentBlock()");
    $ofmt->putDocumentBlock($doc,$blk);

    ##-- DEBUG
    #$ofmt->vlog($logBlockInfo, "BLOCK $blkid: wrote ", $doc->nTokens, " tok(s), ", scalar(@{$doc->{body}}), " sent(s)");
    #$ofmt->toFile("blk_$blk->{id}[0]")->putDocumentRaw($doc)->flush();

    ##-- report: statistics
    if ($job{doProfile}) {
      $ntok = $doc->nTokens();
      $nchr = $blk->{ilen};
      $fp->qaddcounts($ntok,$nchr);
      DTA::CAB::Logger->logProfile($logBlockProfile, tv_interval($tv_jstarted,[gettimeofday]), $ntok,$nchr);
    }
    undef $doc; ##-- we can free up the analyzed document now

    ##-- dump block output back to server for append
    $fp->qaddblock($blk);
  }
  elsif ($qjob->{indoc}) {
    ##--------------------------------------------------
    ## Analyze: Document: pre-parsed
    my $doc = $qjob->{indoc};
    my $docid = '"'.($doc->{body}[0]{tokens}[0] || '(nil)').' ..."';

    ##-- analyze
    $cab->trace("analyzeDocument($docid)");
    $doc = $cab->analyzeDocument($doc,$job{analyzeOpts});

    ##-- output
    $ofmt->trace("putDocumentRaw($docid)");
    $ofmt->toFile($outfile);
    $ofmt->putDocumentRaw($doc)->flush;

    ##-- report: statistics
    if ($job{doProfile}) {
      use bytes;
      $ntok  = $doc->nTokens();
      $nchr += length($_->{text}) foreach (map {@{$_->{tokens}}} @{$doc->{body}}); ##-- hack
      $fp->qaddcounts($ntok,$nchr);
    }
  }
  else {
    ##--------------------------------------------------
    ## Analyze: Document: file
    my $infile = $qjob->{input};
    $fp->info("processing file $infile");

    ##-- parse
    $ifmt->trace("parseFile($infile)");
    my $doc = $ifmt->parseFile($infile)
      or die("$prog: parse failed for input file '$infile': $!");
    $ifmt->close; ##-- ... we can free any format-local input buffers now

    ##-- analyze
    $cab->trace("analyzeDocument($infile)");
    $doc = $cab->analyzeDocument($doc,$job{analyzeOpts});

    ##-- output
    $ofmt->trace("putDocumentRaw($infile -> $outfile)");
    $ofmt->toFile($outfile)
      or die("$prog: open failed for output file '$outfile': $!");
    $ofmt->putDocumentRaw($doc)->flush;

    ##-- report: statistics
    if ($job{doProfile}) {
      $ntok = $doc->nTokens;
      $nchr = (-s $infile) if ($infile ne '-');
      $fp->qaddcounts($ntok,$nchr);
    }
  }

  return 0;
}
##--/cb_work


##======================================================================
## MAIN: guts

##------------------------------------------------------
## main: init: queue

$fp = DTA::CAB::Fork::Pool->new(njobs=>$njobs, local=>$qpath, init=>\&cb_init, work=>\&cb_work, installReaper=>1, logBlock=>$logBlockTrace)
  or die("$0: could not create fork-pool with socket '$qpath': $!");
#DTA::CAB->info("created job queue on UNIX socket '$qpath'");

##------------------------------------------------------
## main: parse specified inputs into a job-queue
my @jobs = qw();
push(@ARGV,'-') if (!@ARGV);
if ($inputList) {
  ##-- list-input mode: push each list item as an individual job
  die("$0: cannot combine -list and -words options (use TT, TJ, or TXT format to process flat word lists)") if ($job{inputWords});
  while (<>) {
    chomp;
    next if (m/^\s*$/ || m/^\s*\#/ || m/^\s*\%\%/);
    %job = %{Storable::dclone($job0)};
    my ($rc,$argv) = Getopt::Long::GetOptionsFromString($_, childOptionSpecs());
    die("$prog: could not parse options-string '$_' at $ARGV line $.") if (!$rc);
    my $jopts = Storable::dclone(\%job);
    push(@jobs, {opts=>$jopts, input=>$_}) foreach (@$argv);
  }
}
elsif ($job{inputWords}) {
  ##-- word-input mode: pass document on the queue
  my @words = map { utf8::decode($_) if (!utf8::is_utf8($_)); $_ } @ARGV;
  my $doc = toDocument([ toSentence([ map {toToken($_)} @words ]) ]);
  @jobs = ( {opts=>\%job, indoc=>$doc} );
}
else {
  ##-- file-input mode: push arguments as individual jobs
  @jobs = map { {opts=>\%job, input=>$_} } @ARGV;
}

##------------------------------------------------------
## main: block-scan if requested
if (!defined($block_spec)) {
  ##-- document-wise processing: just enqueue the parsed jobs
  $fp->enq($_) foreach (@jobs);
}
else {
  ##-- block-wise processing: scan for block boundaries and enqueue each block separately
  %blockOpts = $ifmt->blockOptions($block_spec);
  DTA::CAB->info("using block-wise I/O with eob=$blockOpts{eob}, size>=$blockOpts{bsize}");

  foreach my $job (@jobs) {
    if ($job->{input} eq '-') {
      ##-- stdin hack: spool it to the filesystem for blocking
      my ($tmpfh,$tmpfile) = tmpfsfile("dta_cab_stdin${$}_XXXX", UNLINK=>1);
      File::Copy::copy(\*STDIN,$tmpfh)
	  or die("$prog: could not spool stdin to $tmpfile: $!");
      $tmpfh->close();
      $job->{input} = $tmpfile;
    }

    ##-- block-scan
    new_ifmt(%$job);
    #$ifmt->trace("blockScan($job->{input})");
    my $ofile  = outfilename($job->{input}, $job->{opts}{outfmt});
    my $blocks = $ifmt->blockScan($job->{input}, %blockOpts);
    my $nblks  = scalar(@$blocks);
    my $idfmt  = "%s -> %s [%".length($nblks)."d/%d]";
    my $blki   = 0;
    foreach (@$blocks) {
      $_->{ofile} = $ofile;
      $_->{blkid} = sprintf($idfmt, $_->{ifile}, $_->{ofile}, ++$blki, $nblks);
      $fp->enq({%$job,block=>$_});
    }
  }
}
$fp->info("populated job-queue with ", $fp->size, " item(s)");
#print Data::Dumper->Dump([$fp->{queue}],['QUEUE']), "\n";
#exit 0; ##-- DEBUG


##------------------------------------------------------
## main: guts: process queue

$fp->serverMain();

#$fp->debug("waiting for subprocess(es) to terminate...");
$SIG{CHLD} = undef; ##-- remove installed reaper-sub, if any
$fp->waitall();

##-- check for any remaining unflushed data blocks
my $flushok=1;
my ($bkey,$bt);
while (($bkey,$bt)=each(%{$fp->{blocks}||{}})) {
  next if (!$bt || !$bt->{pending} || !@{$bt->{pending}});
  $fp->logcarp("found ", scalar(@{$bt->{pending}}), " unflushed data block(s) for '$bkey'");
  $flushok = 0;
}
$fp->logcroak("some data blocks were not flushed to disk") if (!$flushok);


##------------------------------------------------------
## main: guts: profiling

if ($job{doProfile}) {
  DTA::CAB::Logger->logProfile('info', tv_interval($tv_started,[gettimeofday]), @$fp{qw(ntok nchr)});
}

##======================================================================
## MAIN: cleanup

##------------------------------------------------------
## main: cleanup: user code
foreach (@eval_end) {
  eval "$_;";
  die("$prog: error evaluating user END code ($_): $@") if ($@);
}

##-- be nice & say goodbyte
DTA::CAB::Logger->info("program exiting normally.");

if (0) {
  ##-- DEBUG memory usage
  my $memusg = `ps -p $$ -o rss=,vsz=`;
  chomp($memusg);
  my ($rss,$vsz) = split(' ',$memusg,2);
  DTA::CAB->info("Memory usage via ps: RSS=$rss, VSZ=$vsz");
  #$_=<STDIN>;

  ##-- dummy debug
  our $cyclic = bless({},'DTA::CAB');
  $cyclic->{self} = $cyclic;
}

##-- main: cleanup: queues & temporary files
sub cleanup {
  if (!$fp || !$fp->is_child) {
    #print STDERR "$0: END block running\n"; ##-- DEBUG
    $fp->abort()  if ($fp);
    $fp->unlink() if ($fp && !$keeptmp);
    #$statq->unlink() if ($statq && !$keeptmp);
    #File::Path::rmtree($blockdir) if ($blockdir && !$keeptmp);
  }
}

END {
  cleanup();
}

__END__
=pod

=head1 NAME

dta-cab-analyze.perl - Command-line analysis interface for DTA::CAB

=head1 SYNOPSIS

 dta-cab-analyze.perl [OPTIONS...] DOCUMENT_FILE(s)...

 General Options
  -help                           ##-- show short usage summary
  -version                        ##-- show version & exit
  -verbose LEVEL                  ##-- alias for -log-level=LEVEL
  -begin CODE                     ##-- evaluate CODE early in script
  -onload CODE                    ##-- evaluate CODE after loading analyzer(s)
  -module MODULE                  ##-- alias for -begin="use MODULE;"
  -end CODE                       ##-- evaluade CODE late in script

 Parallelization Options
  -jobs NJOBS                     ##-- fork() off up to NJOBS parallel jobs (default=0: don't fork() at all)
  -job-queue QPATH                ##-- use QPATH as job-queue socket (default: temporary)
  -keep , -nokeep                 ##-- do/don't keep temporary queue files (default: don't)

 Analysis Options
  -config PLFILE                  ##-- load analyzer config file PLFILE
  -analysis-class  CLASS          ##-- set analyzer class (if -config is not specified)
  -analysis-option OPT=VALUE      ##-- set analysis option
  -profile , -noprofile           ##-- do/don't report profiling information (default: do)

 I/O Options
  -list                           ##-- arguments are list-files, not filenames
  -words                          ##-- arguments are word text, not filenames
  -input-class CLASS              ##-- select input parser class (default: Text)
  -input-option OPT=VALUE         ##-- set input parser option

  -output-class CLASS             ##-- select output formatter class (default: Text)
  -output-option OPT=VALUE        ##-- set output formatter option
  -output-level LEVEL             ##-- override output formatter level (default: 1)
  -output-format TEMPLATE         ##-- set output format (default=STDOUT)

  -format-class CLASS             ##-- alias for -input-class=CLASS -output-class=CLASS
  -format-option OPT=VALUE        ##-- alias for -input-option OPT=VALUE -output-option OPT=VALUE

 Block-wise Processing Options
  -block SIZE[{k,M,G,T}][@EOB]    ##-- pseudo-streaming block-wise analysis (not for all formats)
  -noblock                        ##-- disable block-wise processing
  -log-block-info LEVEL		  ##-- log block-info at LEVEL (default=INFO)
  -log-block-trace LEVEL          ##-- log block-trace at LEVEL (default=none)
  -log-block-profile LEVEL        ##-- log block-profile at LEVEL (default=none)

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

dta-cab-analyze.perl is a command-line utility for analyzing
documents with the L<DTA::CAB|DTA::CAB> analysis suite, without the need
to set up and/or connect to an independent server.

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
## Options: Parallelization Options
=pod

=head2 Parallelization Options

=over 4

=item -jobs NJOBS

Fork() off up to NJOBS parallel jobs.
If NJOBS=0 (default), doesn't fork() at all.

=item -job-queue QPATH

Use QPATH as job-queue socket.  Default is to use a temporary file.

=item -keep , -nokeep

Do/don't keep temporary queue files after program termination (default: don't)

=back

=cut

##==============================================================================
## Options: Other Options
=pod

=head2 Analysis Options

=over 4

=item -config PLFILE

B<Required>.

Load analyzer configuration from PLFILE,
which should be a perl source file parseable
by L<DTA::CAB::Persistent::loadFile()|DTA::CAB::Persistent/item_loadFile>
as a L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> object.
Prototypically, this file will just look like:

 our $obj = DTA::CAB->new( opt1=>$val1, ... );

=item -analysis-option OPT=VALUE

Set an arbitrary analysis option C<OPT> to C<VALUE>.
May be multiply specified.

=item -profile , -noprofile

Do/don't report profiling information (default: do)

=back

=cut

##==============================================================================
## Options: I/O Options
=pod

=head2 I/O Options

=over 4

=item -list

Arguments are list files (1 input per line), not filenames.
List-file arguments can actually contain a subset of command-line options
in addition to input filenames.
Not compatible with the L<-words> option.

=item -words

Arguments are word text, not filenames.
Not compatible with the L<-list> option.

=item -block SIZE[{k,M,G,T}][@EOB]

Do pseudo-streaming block-wise analysis.
Currently only supported for 'TT' and 'TJ' formats.
SIZE is the minimum size in bytes for non-final analysis blocks,
and may have an optional SI suffix 'k', 'M', 'G', or 'T'.
EOB indicates the desired block-boundary type; either 's' to
force all block-boundaries to be sentence boundaries,
or 't' ('w') for token (word) boundaries.  Default=128k@w.

=item -input-class CLASS

Select input parser class (default: Text).

=item -input-option OPT=VALUE

Set arbitrary input parser options.
May be multiply specified.



=item -output-class CLASS

Select output formatter class (default: Text)

=item -output-option OPT=VALUE

Set arbitrary output formatter option.
May be multiply specified.

=item -output-level LEVEL

Override output formatter level (default: 1)

=item -output-format FORMAT

Set output format (default='-' (STDOUT)), a printf-style format which may contain the following %-escapes:

 %f  : INFILE           : current input file
 %b  : basename(INFILE) : basename of current input file
 %d  : dirname(INFILE)  : directory of current input file
 %x  : extension(INFILE): extension of current input file
 %F  :                  : alias for %d/%b

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
L<dta-cab-cachegen.perl(1)|dta-cab-cachegen.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...

=cut
