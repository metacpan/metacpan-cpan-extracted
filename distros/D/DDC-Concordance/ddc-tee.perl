#!/usr/bin/perl -w

use threads;

use DDC::Client;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename dirname);
use Pod::Usage;
use Sys::Syslog qw(:standard :macros);
use Socket;
use strict;

##======================================================================
## globals
our $VERSION = '0.01';

our $prog = basename($0);
our (@b_clients);

##======================================================================
## command-line
our ($help,$version);
our $log_stderr = 1;
our $log_syslog = 0;
our $do_fork = 0;
our $verbose = 'info';
our $pidfile = undef;

GetOptions(##-- General
	   'h|help' => \$help,
	   'V|version' => \$version,
	   'v|verbose=s' => \$verbose,

	   ##-- daemon-ification
	   'f|fork!' => \$do_fork,
	   'p|pf|pid-file|L=s' => \$pidfile,

	   ##-- logging
	   'lp|log-prefix|log-program=s' => \$prog,
	   'le|log-stderr!' => \$log_stderr,
	   'ly|log-syslog!' => \$log_syslog,
	  );

if ($version) {
  print "$prog (DDC::Concordance version $DDC::Concordance::VERSION) by Bryan Jurish <jurish\@bbaw.de>\n";
  exit 0;
}
pod2usage({-exitval=>0, -verbose=>0}) if ($help);
pod2usage({-msg=>"No LISTEN address specified!", -exitval=>1, -verbose=>0}) if (!@ARGV);

##======================================================================
## utils: logging

our %verbose = (
		silent=>0,
		error=>1,
		(map {($_=>2)} qw(warn warning)),
		info=>3,
		debug=>4,
		trace=>5,
	       );

sub vlevel {
  my $level = shift // 0;
  return $verbose{lc($level)} if (exists($verbose{lc($level)}));
  return $level;
}

## $prio = vprio($level)
sub vprio {
  my $level = vlevel(shift);
  return LOG_ERR     if ($level <= $verbose{error});
  return LOG_WARNING if ($level <= $verbose{warning});
  return LOG_NOTICE  if ($level <= $verbose{info});
  return LOG_INFO    if ($level <= $verbose{debug});
  return LOG_DEBUG;  #if ($level <= $verbose{trace});
}

## undef = logmsg($level, @msg)
sub logmsg {
  my $level = vlevel(shift) // 0;
  syslog( vprio($level), join('',@_) ) if ($log_syslog);
  print STDERR "$prog\[$$]: ", @_, "\n" if ($log_stderr);
}
sub error { logmsg('error',@_) }
sub warning { logmsg('warning',@_) }
sub info { logmsg('info',@_) }
sub debug { logmsg('debug',@_) }
sub trace { logmsg('trace',@_) }

$SIG{__DIE__} = sub {
  die(@_) if ($^S);
  error(@_);
  die(@_);
};

$SIG{$_} = \&die_gracefully
  foreach (qw(INT TERM KILL HUP));
sub die_gracefully {
  my $sig = shift;
  die("terminating on signal $sig");
}

##======================================================================
## utils

our %default_host = (peer=>'127.0.0.1', 'local'=>'0.0.0.0');

## \%connect = parseAddr($addr, $PEER_OR_LOCAL, %opts)
sub parseAddr {
  my $addr = shift;
  my $type = shift || "Peer";
  my %connect = (Domain=>'INET', UserAddr=>$addr, @_);
  if ($addr =~ m{^/} || $addr =~ s{^unix:(?://)?}{}) {
    $connect{Domain}  = 'UNIX';
    $connect{$type} = $addr;
  } else {
    $addr =~ s{^(?:inet|tcp):(?://)?}{};
    my ($host,$port) = split(':',$addr,2);
    ($port,$host) = ($host,$port) if (!$port);
    $host ||= $default_host{lc($type)};
    @connect{"${type}Addr","${type}Port"} = ($host,$port);
  }
  return \%connect;
}


## $str = addrstr($addr, $PEER_OR_LOCAL)
## $str = addrstr(\%addr,$PEER_OR_LOCAL)
## $str = addrstr($dcli, $PEER_OR_LOCAL)
## $str = addrstr($sock, $PEER_OR_LOCAL)
sub addrstr {
  my ($addr,$prefix) = @_;
  $prefix ||= 'Peer';
  return (UNIVERSAL::isa($addr,'DDC::Client')
          ? $addr->addrStr(undef,$prefix)
          : DDC::Client->addrStr($addr,$prefix));
}

## $bool = write_pidfile($pid => $pidfile)
sub write_pidfile {
  my ($pid,$pidfile) = @_;
  return if (!defined($pidfile));
  open(my $fh, ">$pidfile")
    or die("$prog: open failed for $pidfile: $!");
  print $fh $pid, "\n";
  close($fh)
    or die("$prog: close failed for $pidfile: $!");
}

##======================================================================
## callbacks


## undef = cb_client($cli_sock)
sub cb_client {
  my $csock = shift;
  my $cli   = DDC::Client->new( sock=>$csock, encoding=>undef );
  my $req   = $cli->readData();

  ##-- spawn clients
  for (my $bi=1; $bi <= $#b_clients; ++$bi) {
    threads->new(\&cb_client_channel, undef, $req, $b_clients[$bi])->detach();
  }
  cb_client_channel($cli, $req, $b_clients[0]) if (@b_clients);
}

## undef = cb_client_channel($cli_or_undef, $req, $backend_cli)
sub cb_client_channel {
  my ($cli,$req,$bcli) = @_;
  #$prog .= "#".threads->tid();

  if ($cli) {
    ##-- primary back-end: 2-way communications REQUEST<->BCLI
    trace("wrap ", addrstr($cli->{sock}), " <-> ", addrstr($bcli), "\n");
    my $rsp = $bcli->requestNC($req);
    while (defined($rsp) && $cli->{sock}->connected) {
      $cli->send($rsp);
      $req = $rsp = undef;
      eval { $req = $cli->readData(); };
      $@ = '';
      last if (!defined($req));
      $rsp = $bcli->requestNC($req);
    }
    $cli->close();
  }
  if (!$cli) {
    ##-- secondary back-end: 1-way communications REQUEST->BCLI
    trace("forward -> ", addrstr($bcli), "\n");
    $bcli->requestNC($req);
  }
  $bcli->close();
}

##======================================================================
## MAIN

##-- setup logging
if ($verbose !~ /^[0-9]+$/) {
  if (exists($verbose{lc($verbose)})) {
    $verbose = $verbose{lc($verbose)};
  } else {
    warn("$prog: unknown verbosity level '$verbose' - using 'info'");
    $verbose = $verbose{info};
  }
}
if ($log_syslog) {
  openlog($prog, "pid", LOG_DAEMON)
    or die("$prog: failed to open connection to syslog: $!");
  setlogmask( LOG_UPTO(vprio($verbose)) );
}

##-- get addresses
my ($l_addr,@b_addrs) = @ARGV;
info("starting ddc-tee daemon on ", addrstr($l_addr), " with ", scalar(@b_addrs), " back-end(s)");

##-- parse back-end addresses
foreach my $baddr (@b_addrs) {
  my $b = parseAddr($baddr,'Peer');
  push(@b_clients, DDC::Client->new(connect=>{%$b}))
    or die("$prog: failed to create client for back-end address '$baddr': $!");
  if (@b_clients==1) {
    info("added back-end ", addrstr($baddr), " (read+write)");
  } else {
    info("added back-end ", addrstr($baddr), " (write-only)");
  }
}

##-- setup server
my $lh =  parseAddr($l_addr,'Local',Listen=>SOMAXCONN, ReuseAddr=>1);
my $lc = "IO::Socket::".uc($lh->{Domain});
my $l  = $lc->new( %$lh )
  or die("$prog: failed to create listen socket on $l_addr: $!");

##-- maybe fork
my $pid = $$;
if ($do_fork && ($pid=fork)) {
  info("spawned daemon subprocess on PID=$pid");
  write_pidfile($pid => $pidfile);
  exit 0;
}
elsif (!$do_fork) {
  write_pidfile($pid => $pidfile);
}

##-- child / main
info("listening on socket $l_addr");

my ($csock);
while (defined($csock=$l->accept())) {
  debug("connect from ", addrstr($csock));
  threads->new(\&cb_client, $csock)->detach;
}


__END__

##------------------------------------------------------------------------------
## PODS
##------------------------------------------------------------------------------
=pod

=head1 NAME

ddc-tee.perl - pass incoming DDC requests to multiple downstream DDC servers

=head1 SYNOPSIS

 ddc-tee.perl [OPTIONS] LISTEN_ADDR DOWNSTREAM_ADDR(s)...

 General Options:
  -h, -help                # this help message
  -V, -version             # show version and exit
  -v, -verbose LEVEL       # set verbosity (0-5 or silent|error|warning|info|debug|trace)

 Daemon Options:
  -f, -[no]fork            # do/don't run in background (default=don't)
  -p, -pidfile PIDFILE     # write PID of background daemon to PIDFILE (default: none)

 Logging Options:
  -lp, -log-prefix PREFIX  # set log-prefix (default=ddc-tee.perl)
  -le, -[no]log-stderr     # do/don't log to stderr (default=do)
  -ly, -[no]log-syslog     # do/don't log to syslog (default=don't)

 Arguments:
  Addresses to bind, accepted formats:

    inet://HOST:PORT
    HOST:PORT
    :PORT
    PORT

    /PATH
    unix:PATH
    unix://PATH

  The first DOWNSTREAM_ADDR will be used for bidrectional communications
  (responses passed back to clients connecting to LISTEN_ADDR). Other
  DOWNSTREAM_ADDRs will have the first request from each client
  connecting to LISTEN_ADDR forwarded to them, but their responses will
  be discarded.

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

