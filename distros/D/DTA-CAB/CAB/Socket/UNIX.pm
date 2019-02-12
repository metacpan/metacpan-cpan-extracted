## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Socket::UNIX.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: UNIX-socket based queue: common utilities

package DTA::CAB::Socket::UNIX;
use DTA::CAB::Socket ':flags';
use DTA::CAB::Utils ':files';
use IO::Handle;
use IO::File;
use IO::Socket;
use IO::Socket::UNIX;
use Carp;
use Exporter;
use strict;

##==============================================================================
## Globals
##==============================================================================
our @ISA = qw(DTA::CAB::Socket);

##==============================================================================
## Constructors etc.
##==============================================================================

## $s = DTA::CAB::Socket::UNIX->new(%args)
##  + %$s, %args:
##    (
##     ##-- NEW in DTA::CAB::Socket::UNIX
##     local  => $path,     ##-- path to local UNIX socket (for server; set to empty string to use a tempfile)
##     peer   => $path,     ##-- path to peer socket (for client)
##     listen => $n,        ##-- queue size for listen (default=SOMAXCONN)
##     perms  => $perms,    ##-- file create permissions for server socket (default=0600)
##     unlink => $bool,     ##-- if true, server socket will be unlink()ed on DESTROY() (default=true)
##     pid    => $pid,      ##-- pid of creating process (unlink() is only called if !defined($pid) || $$==$pid); (re-)set by open()
##     ##
##     ##-- INHERITED from DTA::CAB::Socket
##     fh    => $sockfh,     ##-- an IO::Socket::UNIX object for the socket
##     timeout => $secs,     ##-- default timeout for select() (default=undef: none)
##     nonblocking => $bool, ##-- if true, set O_NONBLOCK on open()
##     logSocket => $level,  ##-- log level for full trace (default=undef (none))
##     logRequest => $level, ##-- log level for client requests (server only; default=undef (none))
##    )
sub new {
  my ($that,%args) = @_;
  my $s = $that->SUPER::new(
			    #local =>undef,
			    #peer  =>undef,
			    ##
			    ##-- server-only options
			    listen =>SOMAXCONN,
			    unlink =>1,
			    pid    =>$$,
			    perms  =>0600,
			    %args,
			   );
  return $s->open() if (!defined($s->{fh}) && (defined($s->{local}) || defined($s->{peer})));
  return $s;
}

## undef = $qs->DESTROY
##  + destructor calls close()
sub DESTROY {
  $_[0]->unlink() if ($_[0]{local} && $_[0]{unlink} && (!defined($_[0]{pid}) || $_[0]{pid}==$$));
}

## $path = $s->path()
##  + returns path to unix socket
sub path {
  return $_[0]{local} || $_[0]{peer} || undef;
}


##==============================================================================
## Open/Close

## $s = $s->unlink()
##  + unlinks $s->{local} if possible
##  + implicitly calls close()
sub unlink {
  $_[0]->close();
  CORE::unlink($_[0]{local}) if ($_[0]{local} && -w $_[0]{local});
}

## $s_or_undef = $s->open(%args)
##   + wrapper for $s->{fh} = IO::Socket::UNIX->new(Type=>SOCK_STREAM, %args)
##   + no sanity checks are performed
sub open {
  $_[0]->vtrace("open ", @_[1..$#_]);
  my ($s,%args) = @_;

  ##-- close and unlink if we can
  $s->close() if ($s->opened);
  $s->unlink() if ($s->{local} && $s->{unlink});

  ##-- clobber %$s with %$args
  @$s{keys %args} = values %args;
  $s->{pid} = $$;

  if (defined($s->{local})) {
    ##-------- server socket
    $s->{local} = tmpfsfile('cabXXXXX') if (!$s->{local}); ##-- local=>'' : use tempfile
    my $path = $s->{local};

    ##-- unlink any stale files of new pathname
    if (-e $path) {
      CORE::unlink($path)
	  or $s->logconfess("cannot unlink existing file at UNIX socket path '$path': $!");
    }

    ##-- bind the socket
    $s->{fh} = IO::Socket::UNIX->new(Type=>SOCK_STREAM, Local=>$s->{local}, Listen=>($s->{listen}||SOMAXCONN))
      or $s->logconfess("cannot bind local UNIX socket '$path': $!");

    ##-- set permissions
    if (defined($s->{perms})) {
      chmod($s->{perms}, $path)
	or $s->logcluck(sprintf("cannot set perms=%0.4o for local UNIX socket '%s': $!", $s->{perms}, $path));
    }

    ##-- report
    $s->vlog('info', sprintf("created UNIX socket '%s' with permissions %0.4o", $path, ((stat($path))[2] & 0777)));
  }
  elsif (defined($s->{peer})) {
    ##-------- client socket
    $s->{fh} = IO::Socket::UNIX->new(Type=>SOCK_STREAM, Peer=>$s->{peer})
      or $s->logconfess("cannot connect to UNIX socket $s->{peer} as client: $!");

    ##-- report
    $s->vtrace("connected to UNIX socket '$s->{peer}'");
  }
  else {
    ##-- unknown
    $s->logconfess("open(): no 'local' or 'peer' argument defined");
  }

  ##-- set non-blocking mode if requested
  $s->nonblocking(1) if ($s->{nonblocking});

  ##-- return
  return $s;
}

##==============================================================================
## Server Methods

## $client = $CLASS_OR_OBJECT->newClient(%args)
##  + wrapper for clients, called by $s->accept()
##  + default just calls $CLASS_OR_OBJECT->new(%args)
sub newClient {
  my $that = shift;
  my %args = (%$that,@_);
  delete($args{local});
  $args{peer} = $that->{local} if (ref($that) && defined($that->{local}));
  return $that->clientClass->new(%args);
}


1; ##-- be happy

__END__
