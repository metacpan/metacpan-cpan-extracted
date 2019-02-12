## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Server::HTTP.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DTA::CAB standalone HTTP server using HTTP::Daemon

package DTA::CAB::Server::HTTP;
use DTA::CAB::Server;
use DTA::CAB::Server::HTTP::Handler::Builtin;
use DTA::CAB::Cache::LRU;
use DTA::CAB::Utils qw(:xml);
use HTTP::Daemon;
use HTTP::Status;
use POSIX ':sys_wait_h';
use Socket qw(SOMAXCONN);
use Time::HiRes qw(gettimeofday tv_interval);
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Server);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure: HASH ref
##    {
##     ##-- Underlying HTTP::Daemon server
##     daemonMode => $daemonMode,    ##-- one of 'serial' or 'fork' [default='serial']
##     daemonArgs => \%daemonArgs,   ##-- args to HTTP::Daemon->new(); default={LocalAddr=>'0.0.0.0',LocalPort=>8088}
##     paths      => \%path2handler, ##-- maps local URL paths to configs
##     daemon     => $daemon,        ##-- underlying HTTP::Daemon object
##     cxsrv      => $cxsrv,         ##-- associated DTA::CAB::Server::XmlRpc object for XML-RPC handlers
##     xopt       => \%xmlRpcOpts,   ##-- options for RPC::XML::Server sub-object (for XML-RPC handlers; default: {no_http=>1})
##     ##
##     ##-- caching & status
##     cacheSize  => $nelts,         ##-- maximum number of responses to cache (default=1024; undef for no cache)
##     cacheLimit => $nbytes,        ##-- max number of content bytes for cached responses (default=undef: no limit)
##     cache      => $lruCache,      ##-- response cache: (key = $url, value = $response), a DTA::CAB::Cache::LRU object
##     nRequests  => $nRequests,     ##-- number of requests (after access control)
##     nCacheHits => $nCacheHits,    ##-- number of cache hits
##     nErrors    => $nErrors,       ##-- number of client errors
##     qtAvg      => $qtAvg,         ##-- query time load average (exponential moving average for 1m,5m,15m, a la linux cpuload), sample values in seconds
##     qt0        => \@time,         ##-- time we started processing most recent query (Time::HiRes::gettimeofday)
##     ##
##     ##-- security
##     allowUserOptions => $bool,   ##-- allow user options? (default: true)
##     allow => \@allow_ip_regexes, ##-- allow queries from these clients (default=none)
##     deny  => \@deny_ip_regexes,  ##-- deny queries from these clients (default=none)
##     _allow => $allow_ip_regex,   ##-- single allow regex (compiled by 'prepare()')
##     _deny  => $deny_ip_regex,    ##-- single deny regex (compiled by 'prepare()')
##     maxRequestSize => $bytes,    ##-- maximum request content-length in bytes (default: undef//-1: no max)
##     bgConnectTimeout => $secs,   ##-- timeout for detecting chrome-style "background connections": connected sockets with no data on them (0:none; default=1)
##     ##
##     ##-- forking
##     forkOnGet => $bool,	    ##-- fork() handler for HTTP GET requests? (default=0)
##     forkOnPost => $bool,	    ##-- fork() handler for HTTP POST requests? (default=1)
##     forkMax => $n,		    ##-- maximum number of subprocess to spwan (default=4; 0~no limit)
##     children => \%pids,	    ##-- child PIDs
##     pid => $pid,		    ##-- PID of parent server process
##     ##
##     ##-- logging
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
## + path handlers:
##   - object descended from DTA::CAB::Server::HTTP::Handler
##   - or HASH ref  { class=>$subclass, %classNewArgs }
##   - or ARRAY ref [        $subclass, @classNewArgs ]
##
sub new {
  my $that = shift;
  return $that->SUPER::new(
			   ##-- underlying server
			   daemonArgs => {
					  LocalAddr=>'0.0.0.0', ##-- all
					  LocalPort=>8088,
					  ReuseAddr=>1,
                                          #ReusePort=>1, ##-- don't set this; it causes errors "Your vendor has not defined Socket macro SO_REUSEPORT"
					 },
			   #cxsrv => undef,
			   xopt => {no_http=>1},

			   ##-- path config
			   paths => {},

			   ##-- caching & status
			   cacheSize  => 1024,
			   cacheLimit => undef,
			   cache      => undef,
			   nRequests  => 0,
			   nCacheHits => 0,
			   nErrors => 0,
			   qtAvg   => DTA::CAB::Utils::EMA->new(decay=>[60,(5*60),(15*60)]),
			   qt0     => undef,

			   ##-- security
			   allowUserOptions => 1,
			   allow => [],
			   deny  => [],
			   _allow => undef,
			   _deny  => undef,
			   maxRequestSize => undef,
			   bgConnectTimeout => 1,

			   ##-- forking
			   children => {},
			   forkOnGet => 0,
			   forkOnPost => 1,
			   forkMax => 4,

			   ##-- logging
			   logRegisterPath => 'info',
			   logAttempt => 'off',
			   logConnect => 'debug',
			   logRequestData => undef,
                           logResponse => undef,
			   logCache => 'debug',
			   logClose => 'off',
			   logClientError => 'trace',

			   ##-- logging, XML-RPC sub-objects
			   logRegisterProc => 'off',
			   logCallData => 'off',
			   logCall => 'off',

			   ##-- logging, fork-related
			   logSpawn => 'off',
			   logReap => 'off',

			   ##-- user args
			   @_
			  );
}

## undef = $obj->initialize()
##  + called to initialize new objects after new()

##==============================================================================
## Methods: subclass API (abstractions for HTTP::UNIX)

## $str = $srv->socketLabel()
##  + returns symbolic label for bound socket address
sub socketLabel {
  my $srv = shift;
  return ($srv->{daemonArgs}{LocalAddr}||'0.0.0.0').':'.($srv->{daemonArgs}{LocalPort});
}

## $str = $srv->daemonLabel()
##  + returns symbolic label for running daemon
sub daemonLabel {
  my $srv = shift;
  return ($srv->{daemon}->sockhost.":".$srv->{daemon}->sockport);
}

## $bool = $srv->canBindSocket()
## $bool = $srv->canBindSocket(\%daemonArgs)
##  + returns true iff socket can be bound; should set $! on error
sub canBindSocket {
  my $srv = shift;
  my $dargs = (@_ ? shift : $srv->{daemonArgs}) || {};
  $dargs->{LocalAddr} ||= '0.0.0.0';
  my $sock  = IO::Socket::INET->new(%$dargs, Listen=>1) or return 0;
  undef $sock;
  return 1;
}

## $class = $srv->daemonClass()
##  + get HTTP::Daemon class
sub daemonClass {
  return 'HTTP::Daemon';
}

## $class_or_undef = $srv->clientClass()
##  + get class for client connections
sub clientClass {
  return undef;
}

##==============================================================================
## Methods: Generic Server API
##==============================================================================

## $rc = $srv->prepareLocal()
##  + subclass-local initialization
sub prepareLocal {
  my $srv = shift;

  ##-- setup HTTP::Daemon object
  $srv->{daemonArgs}{Listen} ||= SOMAXCONN;
  if (!($srv->{daemon}=$srv->daemonClass->new(%{$srv->{daemonArgs}}))) {
    $srv->logconfess("could not create ", $srv->daemonClass, " daemon object: $!");
  }
  my $daemon = $srv->{daemon};

  ##-- register path handlers
  my ($path,$ph);
  while (($path,$ph)=each %{$srv->{paths}}) {
    $ph = $srv->registerPathHandler($path,$ph)
      or $srv->logconfess("registerPathHandler() failed for path '$path': $!");
    $srv->vlog($srv->{logRegisterPath}, "registered path handler: '$path' => ".(ref($ph)||$ph));
  }

  ##-- compile allow/deny regexes
  foreach my $policy (qw(allow deny)) {
    my $re = $srv->{$policy} && @{$srv->{$policy}} ? join('|', map {"(?:$_)"} @{$srv->{$policy}}) : '^$';
    $srv->{"_".$policy} = qr/$re/;
  }

  ##-- setup cache
  $srv->{cache} = DTA::CAB::Cache::LRU->new(max_size=>$srv->{cacheSize}) if (!$srv->{cache} && $srv->{cacheSize}>0);

  ##-- setup mode-specific options
  $srv->{daemonMode} //= 'serial';
  $srv->{pid}        //= $$;
  if ($srv->{daemonMode} eq 'fork') {
    $srv->{children} //= {};
    $SIG{CHLD} = $srv->reaper();
  }

  return 1;
}

## $rc = $srv->run()
##  + run the server
sub run {
  my $srv = shift;
  $srv->prepare() if (!$srv->{daemon}); ##-- sanity check
  $srv->logcroak("run(): no underlying daemon object!") if (!$srv->{daemon});

  my $daemon = $srv->{daemon};
  my $mode   = $srv->{daemonMode} || 'serial';
  my $cclass = $srv->clientClass;
  my $bgConnectTimeout = $srv->{bgConnectTimeout} || 0;
  $srv->info("server starting in $mode mode on ", $srv->daemonLabel, "\n");

  ##-- setup SIGPIPE handler (avoid heinous death)
  ##  + following suggestion on http://www.perlmonks.org/?node_id=580411
  $SIG{PIPE} = sub { ++$srv->{nErrors}; $srv->vlog('warn',"got SIGPIPE (ignoring)"); };

  ##-- HACK: set HTTP::Daemon protocol to HTTP 1.0 (avoid keepalive)
  $HTTP::Daemon::PROTO = "HTTP/1.0";

  my ($csock,$chost,$hreq,$urikey,$forkable,$cacheable,$handler,$localPath,$pid,$rsp);
  my ($fdset);
  while (1) {
    ##-- track total processing time for *last* query
    $srv->qtfinish();

    ##-- call accept() within the loop to avoid breaking out in fork mode
    if (!defined($csock=$daemon->accept())) {
      #sleep(1);
      next;
    }

    ##-- query processing starts
    $srv->{qt0} = [gettimeofday];

    ##-- re-bless client socket (for UNIX-domain server)
    bless($csock,$cclass) if ($cclass);

    ##-- got client $csock (HTTP::Daemon::ClientConn object; see HTTP::Daemon(3pm))
    $chost = $csock->peerhost();

    ##-- avoid blocking on weird EOF sockets sent e.g. by chromium: no joy
    if ($bgConnectTimeout > 0) {
      vec(($fdset=""), $csock->fileno, 1) = 1;
      if (!select($fdset,undef,undef,$bgConnectTimeout)) {
	$srv->vlog($srv->{logAttempt}, "ignoring background connection from client $chost");
	#++$srv->{nErrors};
	next;
      }
    }

    ##-- access control
    $srv->vlog($srv->{logAttempt}, "attempted connect from client $chost");
    if (!$srv->clientAllowed($csock,$chost)) {
      $srv->denyClient($csock);
      next;
    }

    ##-- track number of requests
    ++$srv->{nRequests};

    ##-- serve client: parse HTTP request
    ##
    ## Strangeness Fri, 17 May 2013 14:14:56 +0200
    ## + returning true from demo.js cabUpload() causes weird 'Client closed' errors on post-upload 'Back' clicks from chromium
    ## + problem maybe related to bizarre closed-client crashes for HTTP::Daemon::ClientConn observed elsewhere: persists even within eval BLOCK
    ## + symptom(s):
    ##   - get_request() fails after ca. 10sec
    ##   - HTTP::Daemon::DEBUG output shows "Need more data for complete header\nsysread()\n"
    ##   - no data is actually read into $csock buffer (checked with debugger)
    ##   - $csock invalidates with $csock->reason='Client closed', but $csock->opened()==1
    ##   - attempting to write to $csock in this state (e.g. by clientError()) causes immediate termination of the running server!
    ##
    ##DEBUG
    #$srv->vlog($srv->{logAttempt}, "get_request() for client $chost");
    #$HTTP::Daemon::DEBUG=1;
    ${*$csock}{'io_socket_timeout'} = 5;
    ${*$csock}{'httpd_client_proto'} = HTTP::Daemon::ClientConn::_http_version("HTTP/1.0"); ##-- HACK: force status line on send_error() from $csock->get_request()
    ##/DEBUG
    $hreq = $csock->get_request();
    if (!$hreq) {
      $srv->clientError($csock, RC_BAD_REQUEST, "could not parse HTTP request: ", xml_escape($csock->reason || 'get_request() failed'));
      ++$srv->{nErrors};
      next;
    }

    ##-- log basic request, and possibly request data
    $urikey = $hreq->uri->as_string;
    $srv->vlog($srv->{logConnect}, "client $chost: ", $hreq->method, ' ', $urikey);
    $srv->vlog($srv->{logRequestData}, "client $chost: HTTP::Request={\n", $hreq->as_string, "}");

    ##-- check global content-length limit
    if (($srv->{maxRequestSize}//-1) >= 0 && ($hreq->content_length//0) > $srv->{maxRequestSize}) {
      $srv->clientError($csock, RC_REQUEST_ENTITY_TOO_LARGE, "request exceeds server limit (max=$srv->{maxRequestSize} bytes)");
      ++$srv->{nErrors};
      next;
    }

    ##-- map request to handler
    ($handler,$localPath) = $srv->getPathHandler($hreq->uri);
    if (!defined($handler)) {
      $srv->clientError($csock, RC_NOT_FOUND, "cannot resolve URI ", xml_escape($hreq->uri));
      ++$srv->{nErrors};
      next;
    }

    ##-- check whether we can fork for this request (by default only for POST)
    $forkable = ($mode eq 'fork'
		 && $srv->{"forkOn".ucfirst(lc($hreq->method))}
		 && (!$srv->{forkMax} || scalar(keys %{$srv->{children}}) < $srv->{forkMax}));

    ##-- check cache (GET requests only)
    $cacheable = ($srv->{cache}
		  && (!defined($handler->{cacheable}) || $handler->{cacheable})
		  && $hreq->method eq 'GET'
		  && ($hreq->header('Pragma')||'') !~ /\bno-cache\b/);
    if ($cacheable
	&& ($hreq->header('Cache-Control')||'') !~ /\bno-cache\b/
	&& defined($rsp = $srv->{cache}->get($urikey)))
      {
	++$srv->{nCacheHits};
	$srv->vlog($srv->{logCache}, "using cached response");
	$rsp->header('X-Cached' => 1);
	$srv->vlog($srv->{logResponse}, "cached response: ", $rsp->as_string) if ($srv->{logResponse});
	$csock->send_response($rsp);
	next;
      }

    ##-- maybe fork
    $pid = $forkable ? fork() : undef;
    if ($pid) {
      ##-- parent code
      $srv->{children}{$pid} = undef;
      $srv->vlog($srv->{logSpawn}, "spawned subprocess $pid");
      $srv->{qt0} = undef;
      next;
    }

    ##-- child|serial code: pass request to handler
    eval {
      $rsp = $handler->run($srv,$localPath,$csock,$hreq);
    };
    if ($@) {
      $srv->clientError($csock,RC_INTERNAL_SERVER_ERROR,"handler ", (ref($handler)||$handler), "::run() died:<br/><pre>", xml_escape($@), "</pre>");
      $srv->reapClient($csock,$handler,$chost);
      ++$srv->{nErrors};
    }
    elsif (!defined($rsp)) {
      $srv->clientError($csock,RC_INTERNAL_SERVER_ERROR,"handler ", (ref($handler)||$handler), "::run() failed");
      $srv->reapClient($csock,$handler,$chost);
      ++$srv->{nErrors};
    }

    ##-- maybe cache response
    if ($cacheable
	&& !$forkable ##-- no caching if we're forked
	&& ($hreq->header('Cache-Control')||'') !~ /\bno-store\b/)
      {
	if (!defined($srv->{cacheLimit}) || length(${$rsp->content_ref}) <= $srv->{cacheLimit}) {
	  $srv->vlog($srv->{logCache}, "caching response");
	  $srv->{cache}->set($urikey,$rsp);
	} else {
	  $srv->vlog($srv->{logCache},
		     "response length=",
		     length(${$rsp->content_ref}),
		     " exceeds server limit=$srv->{cacheLimit}: NOT caching response");
	}
      }

    #sleep(3); ##-- DEBUG: simulate long processing

    ##-- ... and dump response to client
    if (!$csock->opened) {
      $srv->logwarn("client socket closed unexpectedly");
      ++$srv->{nErrors};
      next;
    } elsif ($csock->error) {
      $srv->logwarn("client socket has errors");
      ++$srv->{nErrors};
      next;
    }
    $srv->vlog($srv->{logResponse}, "cached response: ", $rsp->as_string) if ($srv->{logResponse});
    $csock->send_response($rsp);
  }
  continue {
    ##-- cleanup after client
    $srv->reapClient($csock,$handler,$chost) if (!$pid);
    $hreq=$handler=$localPath=$pid=$rsp=undef;
  }


  $srv->info("server exiting\n");
  return $srv->finish();
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
      $srv->vlog($srv->{logReap},"reaped subprocess pid=$child, status=$?");
      delete $srv->{children}{$child};
    }
    #$SIG{CHLD}=$srv->reaper() if ($srv->{installReaper}); ##-- re-install reaper for SysV
  };
}

## undef = $srv->reapClient($csock, $handler_or_undef, $chost_or_undef)
sub reapClient {
  my ($srv,$csock,$handler,$chost) = @_;
  return if (!$csock);
  $srv->vlog($srv->{logClose}, "closing connection to client ", ($chost // ($csock->opened ? $csock->peerhost : '-undef-')));
  if ($csock->opened) {
    $csock->force_last_request();
    $csock->shutdown(2);
  }
  $handler->finish($srv,$csock) if (defined($handler));
  exit 0 if ($srv->{pid} && $srv->{pid} != $$);
  return;
}

##==============================================================================
## Methods: Local: Path Handlers

## $handler = $srv->registerPathHandler($pathStr, \%handlerSpec)
## $handler = $srv->registerPathHandler($pathStr, \@handlerSpec)
## $handler = $srv->registerPathHandler($pathStr, $handlerObject)
##  + registers a path handler for path $pathStr
##  + sets $srv->{paths}{$pathStr} = $handler
sub registerPathHandler {
  my ($srv,$path,$ph) = @_;

  if (ref($ph) && ref($ph) eq 'HASH') {
    ##-- HASH ref: implicitly parse
    my $class = DTA::CAB::Server::HTTP::Handler->fqClass($ph->{class});
    $srv->logconfess("unknown class '", ($ph->{class}||'??'), "' for path '$path'")
      if (!UNIVERSAL::isa($class,'DTA::CAB::Server::HTTP::Handler'));
    $ph = $class->new(%$ph);
  }
  elsif (ref($ph) && ref($ph) eq 'ARRAY') {
    ##-- ARRAY ref: implicitly parse
    my $class = DTA::CAB::Server::HTTP::Handler->fqClass($ph->[0]);
    $srv->logconfess("unknown class '", ($ph->[0]||'??'), "' for path '$path'")
      if (!UNIVERSAL::isa($class,'DTA::CAB::Server::HTTP::Handler'));
    $ph = $class->new(@$ph[1..$#$ph]);
  }

  ##-- prepare URI
  $ph->prepare($srv,$path)
    or $srv->logconfess("Path::prepare() failed for path string '$path'");

  return $srv->{paths}{$path} = $ph;
}


## ($handler,$localPath) = $srv->getPathHandler($hreq_uri)
sub getPathHandler {
  my ($srv,$uri) = @_;

  my @segs = $uri->canonical->path_segments;
  my ($i,$path,$handler);
  for ($i=$#segs; $i >= 0; $i--) {
    $path = join('/',@segs[0..$i]);
    return ($handler,$path) if (defined($handler=$srv->{paths}{$path}));
  }
  return ($handler,$path);
}



##==============================================================================
## Methods: Local: Access Control

## $bool = $srv->clientAllowed($clientSock)
##  + returns true iff $cli may access the server
sub clientAllowed {
  my ($srv,$csock,$chost) = @_;
  $chost = $csock->peerhost() if (!$chost);
  return ($chost =~ $srv->{_allow} || $chost !~ $srv->{_deny});
}

## undef = $srv->denyClient($clientSock)
## undef = $srv->denyClient($clientSock, $denyMessage)
##  + denies access to $client
##  + shuts down client socket
sub denyClient {
  my ($srv,$csock,@msg) = @_;
  my $chost = $csock->peerhost();
  @msg = "Access denied from client $chost" if (!@msg);
  $srv->clientError($csock, RC_FORBIDDEN, @msg);
}

##======================================================================
## Methods: Local: error handling

## undef = $srv->clientError($clientSock,$status,@message)
##  + send an error message to the client
##  + $status defaults to RC_INTERNAL_SERVER_ERROR
##  + shuts down the client socket
sub clientError {
  my ($srv,$csock,$status,@msg) = @_;
  if ($csock->opened) {
    my $chost = $csock->peerhost();
    my $msg   = join('',@msg);
    $status   = RC_INTERNAL_SERVER_ERROR if (!defined($status));
    $srv->vlog($srv->{logClientError}, "clientError($chost): $msg");
    if ($msg !~ /: client closed$/i) {
      ##-- don't try to write to sockets reporting 'client closed': this crashes the running server inexplicably!
      my $_warn=$^W;
      $^W=0;
      #$csock->send_error($status, $msg); ##-- response not parseable as xml (see mantis bug #12941)
      $csock->send_response(DTA::CAB::Server::HTTP::Handler->errorResponse($status,$msg));
      $^W=$_warn;
    }
    $csock->force_last_request();
    $csock->shutdown(2);
  }
  $csock->close() if (UNIVERSAL::can($csock,'close'));
  $@ = undef;     ##-- unset eval error
  return undef;
}

## $qtavg = $srv->qtfinish()
##   + called at end of query-processing to update the query-time average
sub qtfinish {
  my $srv = shift;
  return $srv->{qtAvg} if (!$srv->{qt0});
  my $t0 = $srv->{qt0};
  my $t1 = [gettimeofday];
  $srv->{qt0} = undef;
  return $srv->{qtAvg}->append(tv_interval($t0,$t1),$t1);
}

1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Server::HTTP - DTA::CAB standalone HTTP server using HTTP::Daemon

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Server::HTTP;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 
 ##========================================================================
 ## Methods: subclass API (abstractions for HTTP::UNIX)
 
 $str = $srv->socketLabel();
 $str = $srv->daemonLabel();
 $bool = $srv->canBindSocket();
 $class = $srv->daemonClass();
 $class_or_undef = $srv->clientClass();
 
 ##========================================================================
 ## Methods: Generic Server API
 
 $rc = $srv->prepareLocal();
 $rc = $srv->run();
 
 ##========================================================================
 ## Methods: Local: Path Handlers
 
 $handler = $srv->registerPathHandler($pathStr, \%handlerSpec);
 ($handler,$localPath) = $srv->getPathHandler($hreq_uri);
 
 ##========================================================================
 ## Methods: Local: Access Control
 
 $bool = $srv->clientAllowed($clientSock);
 undef = $srv->denyClient($clientSock);
 
 ##========================================================================
 ## Methods: Local: error handling
 
 undef = $srv->clientError($clientSock,$status,@message);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

L<DTA::CAB::Server::HTTP|DTA::CAB::Server::HTTP>
inherits from
L<DTA::CAB::Server|DTA::CAB::Server>,
and supports the L<DTA::CAB::Server|DTA::CAB::Server> API.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $srv = CLASS_OR_OBJ->new(%args);

=over 4

=item Arguments and Object Structure:

 (
  ##-- Underlying HTTP::Daemon server
  daemonMode => $daemonMode,    ##-- one of 'serial', or 'fork' [default='serial']
  daemonArgs => \%daemonArgs,   ##-- args to HTTP::Daemon->new()
  paths      => \%path2handler, ##-- maps local URL paths to handlers
  daemon     => $daemon,        ##-- underlying HTTP::Daemon object
  cxsrv      => $cxsrv,         ##-- associated DTA::CAB::Server::XmlRpc object (for XML-RPC handlers)
  xopt       => \%xmlRpcOpts,   ##-- options for RPC::XML::Server sub-object (for XML-RPC handlers; default: {no_http=>1,logRegisterProc=>'off'})
  ##
  ##-- caching
  cacheSize  => $nelts,         ##-- maximum number of responses to cache (default=1024; undef for no cache)
  cacheLimit => $nbytes,        ##-- max number of content bytes for cached responses (default=undef: no limit)
  cache      => $lruCache,      ##-- response cache: (key = $url, value = $response), a DTA::CAB::Cache::LRU object
  ##
  ##-- security
  allowUserOptions => $bool,   ##-- allow client-specified analysis options? (default: true)
  allow => \@allow_ip_regexes, ##-- allow queries from these clients (default=none)
  deny  => \@deny_ip_regexes,  ##-- deny queries from these clients (default=none)
  _allow => $allow_ip_regex,   ##-- single allow regex (compiled by 'prepare()')
  _deny  => $deny_ip_regex,    ##-- single deny regex (compiled by 'prepare()')
  maxRequestSize => $bytes,    ##-- maximum request content-length in bytes (default: undef//-1: no max)
  ##
  ##-- forking
  forkOnGet => $bool,	    ##-- fork() handler for HTTP GET requests? (default=0)
  forkOnPost => $bool,	    ##-- fork() handler for HTTP POST requests? (default=1)
  forkMax => $n,	    ##-- maximum number of subprocess to spwan (default=4; 0~no limit)
  children => \%pids,	    ##-- child PIDs
  pid => $pid,		    ##-- PID of parent server process
  ##
  ##-- logging
  logRegisterPath => $level,   ##-- log registration of path handlers at $level (default='info')
  logAttempt => $level,        ##-- log connection attempts at $level (default=undef: none)
  logConnect => $level,        ##-- log successful connections (client IP and requested path) at $level (default='debug')
  logRquestData => $level,     ##-- log full client request data at $level (default=undef: none)
  logResponse => $level,       ##-- log full client response at $level (default=undef: none)
  logCache => $level,          ##-- log cache hit data at $level (default=undef: none)
  logClientError => $level,    ##-- log errors to client at $level (default='debug')
  logClose => $level,          ##-- log close client connections (default=undef: none)
  logReap => $level,           ##-- log harvesting of child pids (default=undef: none)
  logSpawn => $level,          ##-- log spawning of child pids (default=undef: none)
  ##
  ##-- (inherited from DTA::CAB::Server)
  as  => \%analyzers,    ##-- ($name=>$cab_analyzer_obj, ...)
  aos => \%anlOptions,   ##-- ($name=>\%analyzeOptions, ...) : %opts passed to $anl->analyzeXYZ($xyz,%opts)
 )

=item path handlers:

Each path handler specified in $opts{paths} should be one of the following:

=over 4

=item *

An object descended from L<DTA::CAB::Server::HTTP::Handler|DTA::CAB::Server::HTTP::Handler>.

=item *

A HASH ref of the form

 { class=>$subclass, %newArgs }

The handler will be instantiated by $subclass-E<gt>new(%newArgs).
$subclass may be specified as a suffix of C<DTA::CAB::Server::HTTP::Handler>,
e.g. $subclass="Query" will instantiate a handler of class C<DTA::CAB::Server::HTTP::Handler::Query>.

=item *

An ARRAY ref of the form

 [$subclass, @newArgs ]

The handler will be instantiated by $subclass-E<gt>new(@newArgs).
$subclass may be specified as a suffix of C<DTA::CAB::Server::HTTP::Handler>,
e.g. $subclass="Query" will instantiate a handler of class C<DTA::CAB::Server::HTTP::Handler::Query>.

=back

=back

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP: Methods: subclass API
=pod

=head2 Methods: subclass API

=over 4

=item socketLabel

 $str = $srv->socketLabel();

returns symbolic label for bound socket address;
default returns string of the form "ADDR:PORT"
using $srv-E<gt>{daemonArgs}.

=item daemonLabel

 $str = $srv->daemonLabel();

returns symbolic label for running daemon;
default returns string of the form "ADDR:PORT"
using $srv-E<gt>{daemon}.

=item canBindSocket

 $bool = $srv->canBindSocket();

returns true iff socket can be bound; should set $! on error;
default tries to bind INET socket as specified in $srv-E<gt>{daemonArgs}.

=item daemonClass

 $class = $srv->daemonClass();

get underlying L<HTTP::Daemon|HTTP::Daemon> class,
default returns 'HTTP::Daemon'.

=item clientClass

 $class_or_undef = $srv->clientClass();

get class for client connections, or undef (default)
if client sockets are not to be re-blessed into a different class.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP: Methods: Generic Server API
=pod

=head2 Methods: Generic Server API

=over 4

=item prepareLocal

 $rc = $srv->prepareLocal();

Subclass-local initialization.
This override initializes the underlying HTTP::Daemon object,
sets up the path handlers, and compiles the server's _allow and _deny
regexes.

=item run

 $rc = $srv->run();

Run the server on the specified port until further notice.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP: Methods: Local: Path Handlers
=pod

=head2 Methods: Local: Path Handlers

=over 4

=item registerPathHandler

 $handler = $srv->registerPathHandler($pathStr, \%handlerSpec);
 $handler = $srv->registerPathHandler($pathStr, \@handlerSpec)
 $handler = $srv->registerPathHandler($pathStr, $handlerObject)

Registers a path handler for path $pathStr (and all sub-paths).
See L</new>() for a description of the allowed forms for handler specifications.

Sets $srv-E<gt>{paths}{$pathStr} = $handler

=item getPathHandler

 ($handler,$localPath) = $srv->getPathHandler($hreq_uri);

Gets the most specific path handler (and its local path) for the URI object $hreq_uri.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP: Methods: Local: Access Control
=pod

=head2 Methods: Local: Access Control

=over 4

=item clientAllowed

 $bool = $srv->clientAllowed($clientSock);

Returns true iff $clientSock may access the server.

=item denyClient

 undef = $srv->denyClient($clientSock);
 undef = $srv->denyClient($clientSock, $denyMessage)

Denies access to $clientSock
and shuts down client socket.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Server::HTTP: Methods: Local: error handling
=pod

=head2 Methods: Local: error handling

=over 4

=item clientError

 undef = $srv->clientError($clientSock,$status,@message);

Sends an error message to the client and
shuts down the client socket.
$status defaults to RC_INTERNAL_SERVER_ERROR (see HTTP::Status).

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<DTA::CAB::Server(3pm)|DTA::CAB::Server>,
L<DTA::CAB::Server::HTTP::Handler(3pm)|DTA::CAB::Server::HTTP::Handler>,
L<DTA::CAB::Server::HTTP::UNIX(3pm)|DTA::CAB::Server::HTTP::UNIX>,
L<DTA::CAB::Client::HTTP(3pm)|DTA::CAB::Client::HTTP>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut
