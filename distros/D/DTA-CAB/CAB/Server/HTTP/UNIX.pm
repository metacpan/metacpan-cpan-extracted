## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Server::HTTP::UNIX.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA::CAB standalone HTTP server using HTTP::Daemon::UNIX

package DTA::CAB::Server::HTTP::UNIX;
use DTA::CAB::Server::HTTP;
use HTTP::Daemon::UNIX;
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use POSIX ':sys_wait_h';
use Socket qw(SOMAXCONN);
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Server::HTTP);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: HASH ref
##    {
##     ##-- DTA::CAB::Server::HTTP::UNIX overrides
##     daemonArgs => \%daemonArgs,   ##-- overrides for HTTP::Daemon::UNIX->new(); default={Local=>'/tmp/dta-cab.sock'}
##     socketPerms => $mode,         ##-- socket permissions as an octal string (default='0666')
##     socketUser  => $user,         ##-- socket user or uid (root only; default=undef: current user)
##     socketGroup => $group,        ##-- socket group or gid (default=undef: current group)
##     _socketPath => $path,         ##-- bound socket path (for unlink() on destroy)
##     #_socketDirs => \@dirs,        ##-- auto-created socket directories (DISABLED)
##     relayCmd    => \@cmd,         ##-- TCP relay command-line for exec() (default=[qw(socat ...)], see prepareRelay())
##     relayAddr   => $addr,         ##-- TCP relay address to bind (default=$daemonArgs{LocalAddr}, see prepareRelay())
##     relayPort   => $port,         ##-- TCP relay address to bind (default=$daemonArgs{LocalPort}, see prepareRelay())
##     relayPid    => $pid,          ##-- child PID for TCP relay process (sockrelay.perl / socat; see prepareRelay())
##
##     ##-- (inherited from DTA::CAB::Server:HTTP): Underlying HTTP::Daemon server
##     daemonMode => $daemonMode,    ##-- one of 'serial' or 'fork' [default='serial']
##     #daemonArgs => \%daemonArgs,   ##-- args to HTTP::Daemon->new(); default={LocalAddr=>'0.0.0.0',LocalPort=>8088}
##     paths      => \%path2handler, ##-- maps local URL paths to configs
##     daemon     => $daemon,        ##-- underlying HTTP::Daemon::UNIX object
##     cxsrv      => $cxsrv,         ##-- associated DTA::CAB::Server::XmlRpc object for XML-RPC handlers
##     xopt       => \%xmlRpcOpts,   ##-- options for RPC::XML::Server sub-object (for XML-RPC handlers; default: {no_http=>1})
##     ##
##     ##-- (inherited from DTA::CAB::Server:HTTP): caching & status
##     cacheSize  => $nelts,         ##-- maximum number of responses to cache (default=1024; undef for no cache)
##     cacheLimit => $nbytes,        ##-- max number of content bytes for cached responses (default=undef: no limit)
##     cache      => $lruCache,      ##-- response cache: (key = $url, value = $response), a DTA::CAB::Cache::LRU object
##     nRequests  => $nRequests,     ##-- number of requests (after access control)
##     nCacheHits => $nCacheHits,    ##-- number of cache hits
##     nErrors    => $nErrors,       ##-- number of client errors
##     ##
##     ##-- (inherited from DTA::CAB::Server:HTTP): security
##     allowUserOptions => $bool,   ##-- allow user options? (default: true)
##     allow => \@allow_ip_regexes, ##-- allow queries from these clients (default=none)
##     deny  => \@deny_ip_regexes,  ##-- deny queries from these clients (default=none)
##     _allow => $allow_ip_regex,   ##-- single allow regex (compiled by 'prepare()')
##     _deny  => $deny_ip_regex,    ##-- single deny regex (compiled by 'prepare()')
##     maxRequestSize => $bytes,    ##-- maximum request content-length in bytes (default: undef//-1: no max)
##     bgConnectTimeout => $secs,   ##-- timeout for detecting chrome-style "background connections": connected sockets with no data on them (0:none; default=1)
##     ##
##     ##-- (inherited from DTA::CAB::Server:HTTP): forking
##     forkOnGet => $bool,	    ##-- fork() handler for HTTP GET requests? (default=0)
##     forkOnPost => $bool,	    ##-- fork() handler for HTTP POST requests? (default=1)
##     forkMax => $n,		    ##-- maximum number of subprocess to spwan (default=4; 0~no limit)
##     children => \%pids,	    ##-- child PIDs
##     pid => $pid,		    ##-- PID of parent server process
##     ##
##     ##-- (inherited from DTA::CAB::Server:HTTP): logging
##     logRegisterPath => $level,   ##-- log registration of path handlers at $level (default='info')
##     logAttempt => $level,        ##-- log connection attempts at $level (default=undef: none)
##     logConnect => $level,        ##-- log successful connections (client IP and requested path) at $level (default='debug')
##     logRquestData => $level,     ##-- log full client request data at $level (default=undef: none)
##     logResponse => $level,       ##-- log full client response at $level (default=undef: none)
##     logCache => $level,          ##-- log cache hit data at $level (default=undef: none)
##     logClientError => $level,    ##-- log errors to client at $level (default='debug')
##     logClose => $level,          ##-- log close client connections (default=undef: none)
##     logReap => $level,           ##-- log harvesting of child pids (default=undef: none)
##     logSpawn => $level,          ##-- log spawning of child pids (default=undef: none)
##     ##
##     ##-- (inherited from DTA::CAB::Server)
##     as  => \%analyzers,    ##-- ($name=>$cab_analyzer_obj, ...)
##     aos => \%anlOptions,   ##-- ($name=>\%analyzeOptions, ...) : %opts passed to $anl->analyzeXYZ($xyz,%opts)
##    }
##
## + path handlers are as for DTA::CAB::Server::HTTP
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- underlying server
			   daemonArgs => {
					  Local => "/tmp/dta-cab.sock",
					  #Listen => SOMAXCONN,
					 },
			   socketPerms => '0666',
			   socketUser  => undef,
			   socketGroup => undef,
			   _socketPath => undef,
			   #_socketDirs => undef,

			   ##-- user args
			   @_
			  );
}

## undef = $obj->initialize()
##  + called to initialize new objects after new()

## undef = $obj->DESTROY()
##  + override unlinks any bound UNIX socket
sub DESTROY {
  my $srv = shift;

  ##-- only run this for the "real" parent server process
  if ($$ == ($srv->{pid}//0)) {
    ##-- terminate tcp-relay subprocess
    kill('TERM'=>$srv->{relayPid}) if ($srv->{relayPid});

    ##-- destroy daemon (force-close socket)
    delete($srv->{daemon}) if ($srv->{daemon});

    ##-- unlink socket if we got it
    if ($srv->{_socketPath} && -e $srv->{_socketPath}) {
      unlink($srv->{_socketPath})
	or warn("failed to unlink server socket $srv->{_socketPath}: $!");
      delete $srv->{_socketPath};
    }

    ##-- remove auto-created directories (only if empty)
    #foreach (reverse @{$srv->{_socketDirs}||[]}) {
    #  last if (!rmdir($_));
    #}
  }

  ##-- superclass destruction if available
  $srv->SUPER::DESTROY() if ($srv->can('SUPER::DESTROY'));
}

##==============================================================================
## Methods: HTTP server API (abstractions for HTTP::UNIX)

##--------------------------------------------------------------
## $str = $srv->socketLabel()
##  + returns symbolic label for bound socket address
sub socketLabel {
  my $srv = shift;
  return $srv->{daemonArgs}{Local};
}

##--------------------------------------------------------------
## $str = $srv->daemonLabel()
##  + returns symbolic label for running daemon
sub daemonLabel {
  my $srv = shift;
  return $srv->{daemon}->hostpath;
}

##--------------------------------------------------------------
## $bool = $srv->canBindSocket()
##  + returns true iff socket can be bound; should set $! on error
sub canBindSocket {
  my $srv   = shift;
  my $dargs = $srv->{daemonArgs} || {};
  my $sockpath = $dargs->{Local}
    or $srv->logconfess("canBindSocket(): no socket path defined");
  $srv->ensureSocketDir($sockpath)
    or $srv->logconfess("canBindSocket(): failed to create socket directory for $sockpath: $!");
  my $sock  = IO::Socket::UNIX->new(%$dargs,Listen=>1);

  if (!$sock) {
    ##-- first bind attempt failed: check whether there's a process behind it by trying to connect
    $srv->logwarn("WARNING: socket path $sockpath already exists; trying to recover");
    if (-w $sockpath && !IO::Socket::UNIX->new(Peer=>$sockpath)) {
      $srv->logwarn("WARNING: client connection to $sockpath failed; force-removing");
      if (!unlink($sockpath)) {
	$srv->logwarn("WARNING: failed to unlink existing socket path $sockpath");
	return 0;
      }
      $sock  = IO::Socket::UNIX->new(%$dargs,Listen=>1);
    }
    if (!$sock) {
      ##-- recovery failed
      $srv->logwarn("WARNING: cannot recycle socket path $sockpath (is another process listening on it?)");
      return 0;
    }
  }

  ##-- cleanup
  undef $sock;
  unlink($sockpath);

  return 1;
}

##--------------------------------------------------------------
## $class = $srv->daemonClass()
##  + get HTTP::Daemon class
sub daemonClass {
  return 'HTTP::Daemon::UNIX';
}

##--------------------------------------------------------------
## $class_or_undef = $srv->clientClass()
##  + get class for client connections
sub clientClass {
  return 'DTA::CAB::Server::HTTP::UNIX::ClientConn';
}

##--------------------------------------------------------------
## $addr_or_false = $srv->relayAddr()
##  + new in Server::HTTP::UNIX
sub relayAddr { return $_[0]{relayAddr} || $_[0]{daemonArgs}{LocalAddr}; }

##--------------------------------------------------------------
## $port_or_false = $srv->relayPort()
##  + new in Server::HTTP::UNIX
sub relayPort { return $_[0]{relayPort} || $_[0]{daemonArgs}{LocalPort}; }

##--------------------------------------------------------------
## $label_or_false = $srv->relayLabel()
##  + new in Server::HTTP::UNIX
sub relayLabel {
  my ($addr,$port) = ($_[0]->relayAddr,$_[0]->relayPort);
  return undef if (!$addr && !$port); ##-- no relay required
  return ($addr||'0.0.0.0').":".$port;
}

##==============================================================================
## Methods: Generic Server API: mostly inherited
##==============================================================================

##--------------------------------------------------------------
## $bool = $srv->ensureSocketDir()
## $bool = $srv->ensureSocketDir($socketPath)
##  + ensures that directory of $socketPath exists
##  + sets $srv->{_socketDirs} if any directories are created
sub ensureSocketDir {
  my ($srv,$sockpath) = @_;
  $sockpath ||= ($srv->{_socketPath}
		 || ($srv->{daemon} ? $srv->{daemon}->hostpath : undef)
		 || $srv->{daemonArgs}{Local});
  $srv->logconfess("ensureSocketDir(): no socket path defined")
    if (!$sockpath);

  my $sockdir = dirname($sockpath);
  if (!-d $sockdir) {
    my @created = make_path($sockdir)
      or $srv->logconfess("ensureSocketDir(): failed to create socket directory '$sockdir': $!");
    $srv->{_socketDirs} = \@created;
  }

  return 1;
}

##--------------------------------------------------------------
## $rc = $srv->prepareLocal()
##  + subclass-local initialization
sub prepareLocal {
  my $srv = shift;

  ##-- ensure socket path directory
  my $sockpath = $srv->{daemonArgs}{Local}
    or $srv->logconfess("prepareLocal(): no socket path defined in {daemonArgs}{Local}");
  $srv->ensureSocketDir($sockpath)
    or $srv->logconfess("prepareLocal(): failed to create directory for socket $sockpath: $!");

  ##-- Server::HTTP initialization
  my $rc  = $srv->SUPER::prepareLocal(@_);
  return $rc if (!$rc);
  $srv->{daemon}->listen( $srv->{daemonArgs}{Listen}||SOMAXCONN ); ##-- workaround for missing option pass-through HTTP::Daemon::UNIX v0.06

  ##-- get socket path
  $sockpath = $srv->{_socketPath} = $srv->{daemon}->hostpath()
    or $srv->logconfess("prepareLocal(): daemon returned bad socket path");

  ##-- setup socket ownership
  my $sockuid = (($srv->{socketUser}//'') =~ /^[0-9]+$/
		 ? $srv->{socketUser}
		 : getpwnam($srv->{socketUser}//''));
  my $sockgid = (($srv->{socketGroup}//'') =~ /^[0-9]+$/
		 ? $srv->{socketGroup}
		 : getgrnam($srv->{socketGroup}//''));
  if (defined($sockuid) || defined($sockgid)) {
    $sockuid //= $>;
    $sockgid //= $);
    $srv->vlog('info', "setting socket ownership (".scalar(getpwuid $sockuid).".".scalar(getgrgid $sockgid).") on $sockpath");
    chown($sockuid, $sockgid, $sockpath)
      or $srv->logconfess("prepareLocal(): failed to set ownership for socket '$sockpath': $!");

    foreach my $dir (reverse @{$srv->{_socketDirs}||[]}) {
      $srv->vlog('info', "setting directory ownership (".scalar(getpwuid $sockuid).".".scalar(getgrgid $sockgid).") on $dir");
      chown($sockuid, $sockgid, $dir)
	or $srv->logconfess("prepareLocal(): failed to set ownership for directory '$dir': $!");
    }
  }

  ##-- setup socket permissions
  if ( ($srv->{socketPerms}//'') ne '' ) {
    my $sockperms = oct($srv->{socketPerms});
    $srv->vlog('info', sprintf("setting socket permissions (0%03o) on %s", $sockperms, $sockpath));
    chmod($sockperms, $sockpath)
      or $srv->logconfess("prepareLocal(): failed to set permissions for socket '$sockpath': $!");
    foreach my $dir (reverse @{$srv->{_socketDirs}||[]}) {
      $srv->vlog('info', sprintf("setting directory permissions (0%03o) on %s", ($sockperms|0111), $dir));
      chmod(($sockperms|0111), $dir)
	or $srv->logconfess("prepareLocal(): failed to set permissions for directory '$dir': $!");
    }
  }

  ##-- setup TCP relay subprocess
  $rc &&= $srv->prepareRelay(@_);

  ##-- ok
  return $rc;
}

##--------------------------------------------------------------
## $bool = $srv->prepareRelay()
##  + sets up TCP relay subprocess
##  + returns -1 if relay process couldn't be started
sub prepareRelay {
  my $srv = shift;
  my $addr = $srv->relayAddr;
  my $port = $srv->relayPort;
  return 1 if (!$addr && !$port); ##-- no relay required

  my $sockpath = $srv->{_socketPath};
  $addr ||= '0.0.0.0';
  @$srv{qw(relayAddr relayPort)} = ($addr,$port);

  ##-- check whether relay address is already bound
  if (!$srv->SUPER::canBindSocket({LocalAddr=>($srv->relayAddr||'0.0.0.0'), LocalPort=>$srv->relayPort})) {
    $srv->logwarn("WARNING: cannot bind TCP socket relay on ${addr}:${port} (is there a stale relay still running?): $!");
    return -1;
  }

  $srv->vlog('trace',"starting TCP socket relay on ${addr}:${port}");
  $SIG{CHLD} ||= $srv->reaper();

  ##-- set main server process as group leader (kill whole process group with `pkill -g $SERVER_PID`)
  POSIX::setpgid(0,0);
  my $pgid = POSIX::getpgrp();

  if ( ($srv->{relayPid}=fork()) ) {
    ##-- parent
    $srv->vlog('info', "started TCP socket relay process for ${addr}:${port} on pid=$srv->{relayPid}");
  } else {
    ##-- child (relay)

    ##-- cleanup: close file desriptors
    POSIX::close($_) foreach (3..1024);

    ##-- join main server's process group
    POSIX::setpgid($$, $pgid);

    ##-- cleanup: environment
    #delete @ENV{grep {$_ !~ /^(?:PATH|PERL|LANG|L[CD]_)/} keys %ENV};

    ##-- get relay command
    my $cmd = ($srv->{relayCmd}
	       || [
		   #qw(env -i), ##-- be paranoid
		   #qw(sockrelay.perl -syslog), "-label=dta-cab-relay/$port",
		   qw(socat -d -ly),
		   ##
		   #"-lpdta-cab-relay/$port", ##-- doesn't set environment varaibles
		   "-lpdta_cab_relay",        ##-- environment variable prefix: DTA_CAB_RELAY_PEERADDR, ...
		   ##
		   "TCP-LISTEN:${port},bind=${addr},backlog=".IO::Socket->SOMAXCONN.",reuseaddr,fork",
		   ##
		   #"UNIX-CLIENT:$sockpath",
		   qq{EXEC:socat -d -ly - 'UNIX-CLIENT:$sockpath'}, ##-- use EXEC:socat idiom to populate socat environment variables (SOCAT_PEERADDR,SOCAT_PEERPORT)
		  ]);

    $srv->vlog('trace', "RELAY: ", join(' ', @$cmd));
    exec(@$cmd)
      or $srv->logconfess("prepareLocal(): failed to start TCP socket relay: $!");
  }

  return 1; ##-- never reached
}


##==============================================================================
## Methods: Local: spawn and reap

## \&reaper = $srv->reaper()
##  + zombie-harvesting code; installed to local %SIG
sub reaper {
  my $srv = shift;
  return sub {
    my ($child);
    while (($child = waitpid(-1,WNOHANG)) > 0) {

      ##-- check whether required subprocess bailed on us
      if ($srv->{relayPid} && $child == $srv->{relayPid}) {
	delete $srv->{relayPid};
	$srv->logdie("TCP relay process ($child) exited with status ".($?>>8));
      }

      ##-- normal case: handle client-level forks (e.g. for POST)
      $srv->vlog($srv->{logReap},"reaped subprocess pid=$child, status=".($?>>8));
      delete $srv->{children}{$child};
    }

    #$SIG{CHLD}=$srv->reaper() if ($srv->{installReaper}); ##-- re-install reaper for SysV
  };
}



##==============================================================================
## Methods: Local: Path Handlers: inherited

##==============================================================================
## Methods: Local: Access Control: inherited

##======================================================================
## Methods: Local: error handling: inherited

##==============================================================================
## PACKAGE: DTA::CAB::Server::HTTP::UNIX::ClientConn
package DTA::CAB::Server::HTTP::UNIX::ClientConn;
use File::Basename qw(basename);
use DTA::CAB::Utils qw(:proc);
our @ISA = qw(HTTP::Daemon::ClientConn);

## ($pid,$uid,$gid) = $sock->peercred()
##  + gets peer credentials; returns (-1,-1,-1) on failure
sub peercred {
  my $sock = shift;
  if ($sock->can('SO_PEERCRED')) {
    my $buf = $sock->sockopt($sock->SO_PEERCRED);
    return unpack('lll',$buf);
  }
  return (-1,-1,-1);
}

## \%env = $sock->peerenv()
## \%env = $sock->peerenv($pid)
##  + gets environment variables for peer process, if possible
##  + uses cached value in ${*sock}{peerenv} if present
##  + returns undef on failure
sub peerenv {
  my ($sock,$pid) = @_;
  return ${*$sock}{'peerenv'} if (${*$sock}{'peerenv'});
  ($pid) = $sock->peercred if (!$pid);
  my ($fh,%env);
  if (open($fh,"</proc/$pid/environ")) {
    local $/ = "\0";
    my ($key,$val);
    while (defined($_=<$fh>)) {
      chomp($_);
      ($key,$val) = split(/=/,$_,2);
      $env{$key} = $val;
    }
    close($fh);
  }

  ##-- debug
  #print STDERR "PEERENV($sock): $_=$env{$_}\n" foreach (sort keys %env);

  ${*$sock}{'peerenv'} = \%env;
}

## $str = $sock->peerstr()
## $str = $sock->peerstr($uid,$gid,$pid)
##  + returns stringified unix peer credentials: "${USER}.${GROUP}[${PID}]"
sub peerstr {
  my ($sock,$pid,$uid,$gid) = @_;
  ($pid,$uid,$gid) = $sock->peercred() if (@_ < 4);
  return (
	  (defined($uid) ? (getpwuid($uid)//'?') : '?')
	  .'.'
	  .(defined($gid) ? (getgrgid($gid)//'?') : '?')
	  .':'
	  .(defined($pid) ? (basename(pid_cmd($pid)//'?')."[$pid]") : '?[?]')
	 );
}

## $host = peerhost()
##  + for relayed connections, gets underlying TCP peer via socat environment
##  + for unix connections, returns UNIX credentials as as for peerstr()
sub peerhost {
  my $sock = shift;

  ##-- get UNIX socket credentials
  my ($pid,$uid,$gid) = $sock->peercred();
  if (defined($pid) && basename(pid_cmd($pid)//'?') eq 'socat') {
    ##-- get socat environment variable if applicable
    my $env = $sock->peerenv();
    return $env->{DTA_CAB_RELAY_PEERADDR} if ($env && $env->{DTA_CAB_RELAY_PEERADDR});
  }

  ##-- return UNIX socket credentials
  return $sock->peerstr($pid,$uid,$gid);
}

## $port = peerport()
##  + for relayed connections, gets underlying TCP port via socat environment
##  + for unix connections, returns socket path
sub peerport {
  my $sock = shift;

  ##-- get UNIX socket credentials
  my ($pid,$uid,$gid) = $sock->peercred();
  if (defined($pid) && basename(pid_cmd($pid)//'?') eq 'socat') {
    ##-- get socat environment variable if applicable
    my $env = $sock->peerenv();
    return $env->{DTA_CAB_RELAY_PEERPORT} if ($env && $env->{DTA_CAB_RELAY_PEERPORT});
  }

  ##-- return UNIX socket path
  return $sock->peerpath();
}



1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Server::HTTP::UNIX - DTA::CAB standalone HTTP server using HTTP::Daemon::UNIX

=cut

##========================================================================
## PACKAGES
=pod

=head1 PACKAGES

=over 4

=item DTA::CAB::Server::HTTP::UNIX

=item DTA::CAB::Server::HTTP::UNIX::ClientConn

=back

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Server::HTTP::UNIX;
 

=cut

##------------------------------------------------------------------------
## SYNOPSIS: DTA::CAB::Server::HTTP::UNIX
=pod

=head2 DTA::CAB::Server::HTTP::UNIX Synopsis

 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 undef = $obj->DESTROY();
 
 ##========================================================================
 ## Methods: HTTP server API
 
 $str = $srv->socketLabel();
 $str = $srv->daemonLabel();
 $bool = $srv->canBindSocket();
 $class = $srv->daemonClass();
 $class_or_undef = $srv->clientClass();
 
 ##========================================================================
 ## Methods: Generic Server API
 
 ## $rc = $srv->prepareLocal();
 ## $bool = $srv->prepareRelay();
 
 ##========================================================================
 ## Methods: Local: spawn and reap
 
 \&reaper = $srv->reaper();
 

=cut

##------------------------------------------------------------------------
## SYNOPSIS: DTA::CAB::Server::HTTP::UNIX::ClientConn
=pod

=head2 DTA::CAB::Server::HTTP::UNIX::ClientConn Synopsis

 
 ($pid,$uid,$gid) = $sock->peercred();
 \%env = $sock->peerenv();
 $str = $sock->peerstr();
 $host = peerhost();
 $port = peerport();
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##------------------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::UNIX
=pod

=head2 DTA::CAB::Server::HTTP::UNIX Description

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::UNIX: Globals
=pod

=head3 Globals

=over 4

=item Variable: @ISA

L<DTA::CAB::Server::HTTP::UNIX|DTA::CAB::Server::HTTP::UNIX>
inherits from
L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP>,
and supports the
L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP>
and L<DTA::CAB::Server|DTA::CAB::Server>
APIs.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::UNIX: Constructors etc.
=pod

=head3 Constructors etc.

=over 4

=item new

 $srv = CLASS_OR_OBJ->new(%args);

Arguments and object structure are mostly inherited from L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP>.
Local overrides and extensions:

 (
  ##-- DTA::CAB::Server::HTTP overrides
  daemonArgs => \%daemonArgs,   ##-- overrides for HTTP::Daemon::UNIX->new(); default={Local=>'/tmp/dta-cab.sock'}
  ##
  ##-- DTA::CAB::Server::HTTP::UNIX extensions
  socketPerms => $mode,         ##-- socket permissions as an octal string (default='0666')
  socketUser  => $user,         ##-- socket user or uid (root only; default=undef: current user)
  socketGroup => $group,        ##-- socket group or gid (default=undef: current group)
  _socketPath => $path,         ##-- bound socket path (for unlink() on destroy)
  relayCmd    => \@cmd,         ##-- TCP relay command-line for exec() (default=[qw(socat ...)], see prepareRelay())
  relayAddr   => $addr,         ##-- TCP relay address to bind (default=$daemonArgs{LocalAddr}, see prepareRelay())
  relayPort   => $port,         ##-- TCP relay address to bind (default=$daemonArgs{LocalPort}, see prepareRelay())
  relayPid    => $pid,          ##-- child PID for TCP relay process (sockrelay.perl / socat; see prepareRelay())


=item DESTROY

 undef = $srv->DESTROY();

override unlinks any UNIX socket C<$srv-E<gt>{_socketPath}> if defined.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::UNIX: Methods: HTTP server API
=pod

=head3 Methods: HTTP server API

=over 4

=item socketLabel

 $str = $srv->socketLabel();

returns symbolic label for bound socket address;
override returns socket path $srv-E<gt>{daemonArgs}{Local}.

=item daemonLabel

 $str = $srv->daemonLabel();

returns symbolic label for running daemon,
override returns socket path $srv-E<gt>{daemon}-E<gt>hostpath().

=item canBindSocket

 $bool = $srv->canBindSocket();

returns true iff socket can be bound; should set $! on error;
override just tries to bind the UNIX socket specified by
$srv-E<gt>{daemonArgs}{Local}.

=item daemonClass

 $class = $srv->daemonClass();

get HTTP::Daemon class,
override returns 'HTTP::Daemon::UNIX'.

=item clientClass

 $class_or_undef = $srv->clientClass();

get class for client connections,
override returns 'DTA::CAB::Server::HTTP::UNIX::ClientConn'.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::UNIX: Methods: Generic Server API
=pod

=head3 Methods: Generic Server API

=over 4

=item prepareLocal

 $rc = $srv->prepareLocal();

subclass-local initialization;
override calls superclass L<prepareLocal()|DTA::CAB::Server::HTTP/prepareLocal>,
sets up UNIX socket ownership and permissions,
and calls the L<prepareRelay()|/prepareRelay> method to optionally set up a
TCP relay subprocess.

=item prepareRelay

 $bool = $srv->prepareRelay();

Starts a TCP listener subprocess to relay incoming
TCP messages to the server's UNIX socket if requested.
A TCP listener process will be started on ADDR:PORT
if a TCP address+port pair (ADDR,PORT) is specified
in $srv-E<gt>{daemonArgs} (keys "LocalAddr","LocalPort")
or $srv itself (keys "relayAddr","relayPort").  You must
have the L<socat(1)|socat> program installed on your system
for this to work.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::UNIX: Methods: Local: spawn and reap
=pod

=head3 Methods: Local: spawn and reap

=over 4

=item reaper

 \&reaper = $srv->reaper();

Zombie-harvesting code; installed to local %SIG.
Override returns a reaper sub which die()s if it harvests
the TCP relay subprocess started by the L<prepareRelay()|/prepareRelay>
method.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP::UNIX: PACKAGE: DTA::CAB::Server::HTTP::UNIX::ClientConn
=pod

=head3 PACKAGE: DTA::CAB::Server::HTTP::UNIX::ClientConn

=over 4

=item Variable: @ISA

L<DTA::CAB::Server::HTTP::UNIX|DTA::CAB::Server::HTTP::UNIX::ClientConn>
inherits from
L<HTTP::Daemon::ClientConn|HTTP::Daemon>
and should support most HTTP::Daemon::ClientConn methods.

=item peercred

 ($pid,$uid,$gid) = $sock->peercred();

Gets UNIX socket peer credentials; returns (-1,-1,-1) on failure.

=item peerenv

 \%env = $sock->peerenv();
 \%env = $sock->peerenv($pid);

Attempts to retrieve environment variables for peer process, if possible.
Uses cached value in ${*sock}{peerenv} if present,
otherwise attempts to open and parse F</proc/$pid/environ>.
Returns undef on failure.

=item peerstr

 $str = $sock->peerstr();
 $str = $sock->peerstr($uid,$gid,$pid);

Returns stringified unix peer credentials, "${USER}.${GROUP}[${PID}]".

=item peerhost

 $host = peerhost();

For relayed connections, gets underlying TCP peer via socat environment (INET emulation);
for unix connections, returns UNIX credentials as as for peerstr().

=item peerport

 $port = peerport();

For relayed connections, gets underlying TCP port via socat environment (INET emulation);
for unix connections, returns socket path:

=back

=cut

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<dta-cab-http-server.perl(1)|dta-cab-http-server.perl>,
L<dta-cab-http-client.perl(1)|dta-cab-http-client.perl>,
L<dta-cab-xmlrpc-server.perl(1)|dta-cab-xmlrpc-server.perl>,
L<dta-cab-xmlrpc-client.perl(1)|dta-cab-xmlrpc-client.perl>,
L<DTA::CAB::Server(3pm)|DTA::CAB::Server>,
L<DTA::CAB::Server::UNIX(3pm)|DTA::CAB::Server::UNIX>,
L<DTA::CAB::Client(3pm)|DTA::CAB::Client>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut
