#!/usr/bin/perl -w

use lib qw(. ./ddc-perl ./DDC-perl);
use DDC::Concordance;
use Encode qw(encode decode);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename dirname);

use strict;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------
our ($help,$version);
our $prog = basename($0);
our $corpora = undef;
our $fmt_class = 'DDC::Format::Kwic';
our $fieldNamesStr = '';
our $qencoding = undef;
our $query_from_file = 0;
our $query_sleep = 0; ##-- pause inbetween multiple queries
our $query_verbose = 0; ##-- trace queries?
our $query_multi = 0; ##-- multi-query mode?

our $bench_iters = undef;
our $bench_seconds = undef;
our $bench_clear_cache = 1;
our $expandChain = undef;

our %fmt = (
	    columns => 80,
	    width   => 32,
	    level   => 1,
	    vars    => {}, ##-- for template formatting
	   );

our %client = (
	       connect=>{Domain=>'INET',PeerAddr=>"localhost",PeerPort=>50011},
	       start=>0,
	       limit=>10,
	       hint=>'',
	       timeout=>60,
	       mode=>'json',
	       encoding=>'UTF-8',
	       parseMeta=>1,
	       parseContext=>1,
	       keepRaw=>0,
	       fieldNames=>undef,
	       fieldSeparator=>"\x{1f}",
	       tokenSeparator=>"\x{1e}",
	       #nFields=>7,
	       dropFields => [],
	       expandFields => 1,
	      );

##------------------------------------------------------------------------------
## Command-line
##------------------------------------------------------------------------------
sub setFormatSub {
  my $base = shift;
  my $class = "DDC::Format::$base";
  my $file  = $class;
  $file =~ s/::/\//g;
  $file .= ".pm";
  return sub {
    require $file or die("$prog: could not load class '$class': $!");
    $fmt_class=$class;
  }
}

GetOptions(##-- General
	   'help|h' => \$help,
	   'version|V' => \$version,

	   ##-- Connection
	   'server|s=s' => \$client{connect}{PeerAddr},
	   'port|p=s'   => \$client{connect}{PeerPort},
	   'unix|u=s'   => sub { %{$client{connect}} = (Domain=>'UNIX',Peer=>$_[1]) },
	   'corpora|corpus|c=s' => \$corpora,
	   'opt-file|opt|O=s' => \$client{optFile},
	   'mode|m=s' => \$client{mode},
	   'query-encoding|qencoding|qe=s' => \$qencoding,

	   ##-- Benchmarking and testing
	   'benchmark-iterations|benchmark-iters|bench-iters|bibenchmark|bench|b|iters|i=i' => \$bench_iters,
	   'benchmark-seconds|bench-seconds|bs=i' => \$bench_seconds,
	   'bench-clear-cache|bench-clear|bc!' => \$bench_clear_cache,
	   'query-file|file|qf!' => \$query_from_file,
	   'query-sleep|sleep|qs=i' => \$query_sleep,
	   'query-verbose|qv|verbose|query-trace|qt|trace!' => \$query_verbose,

	   ##-- Hit selection
	   'start|S=i' => \$client{start},
	   'limit|l=i' => \$client{limit},
	   'timeout|t=i' => \$client{timeout},
	   'hint|H=s' => \$client{hint},
	   'expand-pipeline|xpipe|pipe|xp|expand-chain|chain|xc=s' => \$expandChain,

	   ##-- Hit Parsing
	   'parse-meta|meta|pm!' => \$client{parseMeta},
	   'parse-context|context|pc!' => \$client{parseContext},
	   'keep-raw|keep|k!' => \$client{keepRaw},
	   'field-names|fields|names|f=s' => \$fieldNamesStr,
	   'field-separator|fsep|fs=s' => \$client{fieldSeparator},
	   'token-separator|tsep|ts=s' => \$client{tokenSeparator},
	   'encoding|e=s' => \$client{encoding},
	   'expand-fields|expand|xf!' => \$client{expandFields},
	   'drop-field|drop|df=s' => $client{dropFields},

	   ##-- Formatting
	   'columns|cols|C=i' => \$fmt{columns},
	   'kwic-width|kw|width|w=i' => \$fmt{width},
	   'level|L=i' => \$fmt{level},
	   'pretty!' => sub { $fmt{level}=$_[1] ? 1 : 0; },
	   'compact|z|ugly' => sub { $fmt{level}=0; },
	   'text|txt' => setFormatSub('Text'),
	   'kwic|kwc' => setFormatSub('Kwic'),
	   'dumper|dump|d' => setFormatSub('Dumper'),
	   'json|JSON|j' => setFormatSub('JSON'),
	   'yaml|yml|YAML|y' => setFormatSub('YAML'),
	   'template|tmpl|tt|T=s' => sub { setFormatSub('Template')->(); $fmt{src}=$_[1]; },
	   #'raw|r' => sub { $fmt_class='DDC::Format::Raw'; },
	   'raw|r' => sub { $fmt_class='DATA'; },
	   'request|req|R' => sub { $client{mode}='request'; $fmt_class='DATA'; },
	   'multi|M!' => \$query_multi,
	   'variable|var|v=s%' => $fmt{vars},
	  );

if ($version) {
  print "$prog (DDC::Concordance version $DDC::Concordance::VERSION) by Bryan Jurish <jurish\@bbaw.de>\n";
  exit 0;
}
pod2usage({-exitval=>0, -verbose=>0}) if ($help);
pod2usage({-msg=>"No query specified!", -exitval=>1, -verbose=>0}) if (!@ARGV);


##------------------------------------------------------------------------------
## subs

sub qtrace {
  return if (!$query_verbose);
  print STDERR "$prog: ", @_, "\n";
}

sub quotenp {
  my $s = shift;
  $s =~ s{([^[:print:]])}{sprintf("\\x{%0.2x}",ord($1))}ge;
  return $s;
}

##------------------------------------------------------------------------------
## MAIN
##------------------------------------------------------------------------------

##-- field names
our $fieldNames = undef;
if ($fieldNamesStr ne '') {
  $fieldNames = [grep {defined($_) && $_ ne ''} split(/[\,\s]+/,$fieldNamesStr)];
}

##-- port
$client{connect}{PeerPort} = $1 if ($client{connect}{Domain} eq 'INET' && $client{connect}{PeerAddr} =~ s/\:([0-9]+)$//);

##-- client
our $dclient = DDC::Client::Distributed->new(%client,
					     keepRaw=>($fmt_class =~ /Raw/ || $client{mode} =~ /^(?:raw|req)/i ? 1 : 0),
					     fieldNames=>$fieldNames,
					    );
my $srv_addr = ($client{connect}{Domain} eq 'INET'
		? join(':', map {$_//'?'} @{$client{connect}}{qw(PeerAddr PeerPort)})
		: join(':', 'UNIX', map {$_//'?'} @{$client{connect}}{qw(Peer)}));
$dclient->open()
  or die("$prog: could not connect to DDC server on $srv_addr: $!");

if ($expandChain) {
  ##-- term expansion mode
  my $terms = [@ARGV];
  my $chain = $expandChain;
  qtrace("EXPAND [$chain]: $terms");
  my $buf = $dclient->expand_terms($chain,$terms);
  $buf = encode($client{encoding},$buf) if ($client{encoding} && utf8::is_utf8($buf));
  print $buf, "\n";
  exit 0;
}

##-- query from command-line or file
##   + file format: QUERY "\n"
##   + optional pseudo-flags "#start START" "#limit LIMIT"
##   + @queries = ({query=>$str, start=>$start, limit=>$limit}, ...)
our (@queries);
if ($query_from_file) {
  foreach my $qfile (@ARGV) {
    open(my $qfh,"<$qfile") or die("$prog: failed to open query file '$qfile': $!");
    my ($q,$start,$limit);
    while (<$qfh>) {
      chomp;
      next if (/^\s*$/ || /^\s*\/\//);
      $q = $_;
      $start = ($q =~ s/\s*\#start[=\s\[]+(\d+)\]?//gi ? $1 : $dclient->{start});
      $limit = ($q =~ s/\s*\#limit[=\s\[]+(\d+)\]?//gi ? $1 : $dclient->{limit});
      push(@queries,{start=>$start,limit=>$limit,query=>$q});
    }
    close($qfh);
  }
}
elsif ($query_multi) {
  @queries = map { {start=>$dclient->{start},limit=>$dclient->{limit},query=>$_} } @ARGV;
}
else {
  @queries = ( {start=>$dclient->{start},limit=>$dclient->{limit},query=>join(' ',@ARGV)} );
}

##-- decode and tweak control-character escapes in queries
foreach (@queries) {
  $_->{query} .= " :${corpora}" if (defined($corpora));
  $_->{query} = decode($qencoding,$_->{query}) if (defined($qencoding) && !utf8::is_utf8($_->{query}));

  my $q0 = $_->{query};
  if ($client{mode} =~ /^(?:raw|req)/i) {
    my $q = $_->{query};
    $q =~ s/\\x\{([0-9a-f]+)\}/chr(hex($1))/egi;
    $q =~ s/\\x([0-9a-f]{1,2})/chr(hex($1))/egi;
    $_->{query} = $q;
  }
}

##-- benchmark?
if ($bench_iters || $bench_seconds) {
  require Time::HiRes;

  my $mode = $dclient->{mode};
  print
    ("$prog: benchmarking "
     .join(", ",
	   ($bench_seconds ? "up to $bench_seconds second(s)" : qw()),
	   ($bench_iters ? "$bench_iters iteration(s)" : qw()))
     ." of ",
     (@queries==1 ? "query ($queries[0]{query})" : (scalar(@queries)." queries")),
     " with query mode $mode...\n"
    );
  $bench_iters ||= 'inf';
  $bench_seconds ||= 'inf';

  my ($t0,$i);
  my $elapsed = 0;
  my $n = 0;
  for ($i=0; $i < $bench_iters; ++$i) {
    $dclient->queryRaw(['clear_cache -1']) if ($bench_clear_cache);
    if (!$query_multi) {
      ##-- atomic query mode (default)
      foreach (@queries) {
	@$dclient{qw(start limit)} = @$_{qw(start limit)};
	$t0 = [Time::HiRes::gettimeofday()];
	$dclient->queryRaw($_->{query});
	$elapsed += Time::HiRes::tv_interval($t0, [Time::HiRes::gettimeofday()]);
	++$n;
	last if ($elapsed >= $bench_seconds);
      }
    }
    else {
      ##-- multi-query mode (e.g. get_first_hits + get_hit_strings; no handling of @$_{qw(start limit)})
      $t0 = [Time::HiRes::gettimeofday()];
      $dclient->queryMulti(@queries);
      $elapsed += Time::HiRes::tv_interval($t0, [Time::HiRes::gettimeofday()]);
      $n += scalar(@queries);
    }
    $dclient->queryRaw(['clear_cache -1']) if ($bench_clear_cache);
    last if ($elapsed >= $bench_seconds);
  }
  my $rate = sprintf("%7.2f", ($elapsed ? ($n/$elapsed) : "nan"));
  print "\t", sprintf("%.5f", $elapsed), " wallclock secs @ $rate q/s (n=$n)\n";
  exit 0;
}

##-- query handling guts
sub showQueryResponse {
  my ($query,$buf) = @_;

  if ($fmt_class eq 'DATA') {
    print $buf, ($buf =~ /\n\z/s ? qw() : "\n");
    return;
  }

  ##-- parse query buffer
  my $hits = $dclient->parseData($buf)
    or die("$prog: could not parse query data: $!");
  if ($hits->{error_}) {
    print STDERR "$prog: server error ($hits->{istatus_} $hits->{nstatus_}): $hits->{error_}\n";
    return;
  }
  if (!@{$hits->{hits_}//[]} && !@{$hits->{counts_}//[]}) {
    print STDERR "$prog: no hits found.\n";
    return;
  }

  ##-- format data
  $fmt{vars}{totalResults} = $hits->{nhits_};
  $fmt{vars}{client}       = $dclient;
  $fmt{vars}{query}        = $query;
  my $fmt = $fmt_class->new(%fmt,encoding=>$client{encoding})
    or die("$prog: could not create $fmt_class formatting object");

  my $outstr = $fmt->toString($hits);
  $outstr = encode($client{encoding},$outstr) if ($client{encoding} && utf8::is_utf8($outstr));
  print $outstr;
}

##-- query guts
if (!$query_multi) {
  ##-- atomic query mode (default)
  foreach (@queries) {
    sleep($query_sleep) if ($query_sleep > 0); ##-- sleep

    my $query = $_->{query};
    @$dclient{qw(start limit)} = @$_{qw(start limit)};

    print "#\n# QUERY: $query -start=$dclient->{start} -limit=$dclient->{limit}\n" if (@queries > 1);
    qtrace("QUERY [start=$dclient->{start},limit=$dclient->{limit}] $_->{query}");
    my $buf = $dclient->queryRaw($query)
      or die("$prog: query ($query) failed: $!");

    showQueryResponse($query,$buf);
  }
}
else {
  ##-- multi-query mode (e.g. get_first_hits + get_hit_strings)

  print "#\n# MULTI:\n", map {"#  + ".quotenp($_->{query})."\n"} @queries;
  my @bufs = $dclient->queryMulti(map {$_->{query}} @queries);
  for (my $i=0; $i <= $#queries; ++$i) {
    print "#\n# QUERY: ".quotenp($queries[$i]{query})."\n";
    showQueryResponse($queries[$i]{query},$bufs[$i]);
  }
}


__END__

##------------------------------------------------------------------------------
## PODS
##------------------------------------------------------------------------------
=pod

=head1 NAME

ddc-query.perl - distributed DDC query tool in perl

=head1 SYNOPSIS

 ddc-query.perl [OPTIONS] [QUERY...]

 General Options:
  -help
  -version

 Connection Options:
  -server  SERVER                   ##-- TCP server host address (default=localhost)
  -port    PORT                     ##-- TCP server port (default=50011)
  -unix    PATH                     ##-- UNIX server socket path (overrides TCP settings)
  -timeout DDC_TIMEOUT              ##-- default=60
  -mode    QMODE                    ##-- query mode: 'json', 'table', 'text', 'request' (default='json')
  -qenc    QENCODING                ##-- query encoding (default=raw bytes)
  -file			            ##-- arguments are query-list filenames, not queries
  -request			    ##-- alias for -mode=request -raw (for protocol debugging)
  -multi                            ##-- send multiple requests on same connection (default=no)

 Benchmarking and Batch Options:
  -bench-iters ITERS                ##-- benchmark: time ITERS query iterations
  -bench-seconds SECONDS            ##-- benchmark: abort after SECONDS query-processing time (default=inf)
  -[no]bench-clear		    ##-- do/don't clear server cache between benchmark iterations (default=do)
  -query-file                       ##-- batch-execute queries from command-line argument file(s)
  -query-sleep SECONDS              ##-- sleep for SECONDS between multiple queries (default=0)
  -query-verbose                    ##-- trace query execution to stderr

 Hit Selection Options:
  -corpora DDC_CORPORA              ##-- comma-separated list; default=none
  -start FIRST_HIT                  ##-- offset of 1st hit to retrieve (default=0)
  -limit MAX_HITS                   ##-- maximum number of hits to retrieve (default=10)
  -hint HINT                        ##-- set optional navigation hint (default: empty string)
  -expand-chain PIPELINE            ##-- perform term expansion via PIPELINE rather than a retrieval query

 Hit Parsing Options
  -parse-meta   , -no-meta          ##-- do/don't parse hit metadata (default=do)
  -parse-context, -no-context       ##-- do/don't parse hit context  (default=do)
  -keep-raw     , -nokeep-raw       ##-- do/don't keep raw hit context (default=don't)
  -opt-file OPTFILE                 ##-- load DDC .opt file?
  -field-names FIELDS               ##-- parse into named FIELDS (space-separated list; default=none)
  -word-separator REGEX             ##-- word separator regex for context parsing (default=' ')
  -field-separator REGEX            ##-- field separator regex for context parsing (default='\x{1f}' : ASCII unit separator)
  -token-separator REGEX            ##-- token separator regex for context parsing (default='\x{1e}' : ASCII record separator)
  -encoding ENCODING                ##-- server encoding (default='UTF-8')

 Formatting Options:
  -columns COLS                     ##-- output columns for text formatter (default=80)
  -width   COLS                     ##-- number of context characters for KWIC formatter (default=32)
  -pretty , -ugly                   ##-- do/don't pretty-print (default=don't)
  -raw                              ##-- dump raw query response buffer
  -dumper                           ##-- use Data::Dumper formatter
  -kwic                             ##-- use KWIC formatter
  -text                             ##-- use old text formatter
  -json                             ##-- use JSON formatter
  -yaml                             ##-- use YAML formatter
  -template TTKFILE                 ##-- use Template-Toolkit formatter with TTKFILE

=cut

##------------------------------------------------------------------------------
## Options and Arguments
##------------------------------------------------------------------------------
=pod

=head1 OPTIONS AND ARGUMENTS

not yet written

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

not yet written

=cut


##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=cut

