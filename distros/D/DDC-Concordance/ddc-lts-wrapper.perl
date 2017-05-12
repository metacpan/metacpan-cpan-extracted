#!/usr/bin/perl -w

use lib qw(.);
use Lingua::LTS::Gfsm;
use Encode qw(encode decode);
use DDC::Filter;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename);
use Pod::Usage;
use locale;

##------------------------------------------------------------------------------
## Constants & Globals
##------------------------------------------------------------------------------

##-- DDC: upstream server
our $userver  = "localhost";
our $uport    = 50011;

##-- DDC: wrapping server
our $wserver = "localhost";
our $wport   = 60000;

##-- DDC: server: other
our $pidfile = undef;
our $logfile = '&STDERR';
our $loglevel = 'default';


##-- analysis object
our $lts = Lingua::LTS::Gfsm->new(
				  check_symbols=>1,
				  tolower      =>1,
				  profile      =>0,
				 );

##-- analysis object: filenames
our $lts_labfile = undef;
our $lts_fstfile = undef;
our $lts_dictfile = undef;

##-- analysis options
our $queryenc = undef;

##-- program options
our $verbose = 1;
our $progname = basename($0);

##------------------------------------------------------------------------------
## Package: DDC::Filter::LTS
##------------------------------------------------------------------------------
package DDC::Filter::LTS;
use Encode qw(encode decode);
our @ISA = qw(DDC::Filter);

##-- regex-ify a string (hack)
sub regexify {
  my $str = shift;
  $str =~ s/([\[\]\+\*\.\^\$\(\)\:\?])/\\$1/g;
  return '/^'.$str.'$/';
}

sub logfh {
  my $filter = shift;
  return $main::lts->{errfh} = $filter->SUPER::logfh();
}
sub logclose {
  my $filter = shift;
  $main::lts->{errfh} = \*STDERR;
  return $filter->SUPER::logclose();
}

sub filterInput {
  my ($filter,$data) = @_;
  my ($cmd_mode,$query,@rest) = split(/\001/, $data);
  return $data if ($cmd_mode !~ /^run_query\s/);

  $query = decode($main::queryenc,$query) if ($main::queryenc);
  $query =~ s/\$(p|Phon)\~([^\s\"\(\)\&\|]+)/'$'.$1.'='.regexify($main::lts->analyze($2))/ge;
  $query = encode($main::queryenc,$query) if ($main::queryenc);

  return join("\001", $cmd_mode,$query,@rest);
}
#sub filterOutput { return $_[0]->SUPER::filterOutput(@_[1..$#_]); }

1;
package main;

##------------------------------------------------------------------------------
##Command-line
##------------------------------------------------------------------------------
GetOptions(##-- General
	   'help|h' => \$help,

	   ##-- DDC: Upstream Connection
	   'upstream-server|server|us=s' => \$userver,
	   'upstream-port|port|up=s'   => \$uport,

	   ##-- DDC: Downstream connection
	   'bind-server|bs=s' => \$wserver,
	   'bind-port|bp=s'   => \$wport,

	   ##-- DDC: logging, pidfile
	   'pidfile|pid=s' => \$pidfile,
	   'logfile|log=s' => \$logfile,
	   'loglevel|level=s' => \$loglevel,

	   ##-- LTS: Analysis Objects
	   'labels|labs|lab|l=s' => \$lts_labfile,
	   'fst|f=s'             => \$lts_fstfile,
	   'dictionary|dict|d=s' => \$lts_dictfile,

	   ##-- Analysis Options
	   'label-encoding|labencoding|labenc|le=s' => \$lts->{labenc},
	   'query-encoding|queryenc|qenc|qe=s'      => \$queryenc,
	   'check-symbols|check|c!'                 => \$lts->{check_symbols},
	   'tolower|lower|L!'                       => \$lts->{tolower},
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

##------------------------------------------------------------------------------
## MAIN
##------------------------------------------------------------------------------

##-- pidfile
if ($pidfile) {
  open(PID,">$pidfile") or die("$0: open failed for PID file '$pidfile': $!");
  print PID "$$\n";
  close(PID);
}

our $filter = DDC::Filter::LTS->new(
				    ##-- DDC: connections
				    connect=>{
					      PeerHost=>$userver,
					      PeerPort=>$uport,
					     },
				    bind=>{
					   hostname=>$wserver,
					   port=>$wport,
					   mode=>'select', ##-- debug
					  },

				    ##-- DDC: options
				    (defined($logfile)  ? (logfile=>$logfile)   : qw()),
				    (defined($loglevel) ? (loglevel=>$loglevel) : qw()),
				   );

##-- LTS: load: labels
$lts->loadLabels($lts_labfile)
  or die("$progname: load failed for labels '$lts_labfile': $!");

##-- LTS: load: fst
$lts->loadFst($lts_fstfile)
  or die("$progname: load failed for automaton '$lts_fstfile': $!");

##-- LTS: load: dict
if (defined($lts_dictfile)) {
  $lts->loadDict($lts_dictfile)
    or die("$progname: load failed for dictionary file '$lts_dictfile': $!");
}


$filter->logmsg('info', "server starting on port $filter->{bind}{port}");
$filter->logmsg('info', "LTS automaton  : $lts_fstfile");
$filter->logmsg('info', "LTS alphabet   : $lts_labfile");
$filter->logmsg('info', "LTS dictionary : ", (defined($lts_dictfile) ? $lts_dictfile : '(none)'));
$filter->run();

__END__

##------------------------------------------------------------------------------
## PODS
##------------------------------------------------------------------------------
=pod

=head1 NAME

ddc-lts-wrapper.perl - drop-in replacement DDC server supporting 'sounds-like' queries

=head1 SYNOPSIS

 ddc-lts-wrapper.perl [OPTIONS] [QUERY...]

 General Options:
  -help
  -columns COLS_PER_PAGE

 DDC Connection Options:
  -upstream-server  UPSTREAM_SERVER
  -upstream-port    UPSTREAM_PORT
  -bind-server      BIND_SERVER
  -bind-port        BIND_PORT

 Server Logging Options:
  -pidfile PIDFILE
  -logfile LOGFILE                    # default='&STDERR'
  -loglevel LEVEL                     # default='default' [=info]

 LTS Analysis Options:
  -labels LABFILE
  -fst    FSTFILE
  -dict   DICTFILE

 Encoding and String Options:
  -label-encoding ENCODING            # encoding of LABFILE
  -query-encoding ENCODING            # assumed encoding of incoming queries
  -check , -nocheck                   # do/don't check for bad symbols
  -lower , -nolower                   # do/don't auto-lowercase symbols

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

