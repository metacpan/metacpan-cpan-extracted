package Bio::Das::ProServer::Daemon;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Tony Cox <avc@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use Sys::Hostname;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;
use Data::Dumper;
use POSIX qw(:signal_h);
use Compress::Zlib;
use Digest::MD5;
use CGI;
use Bio::Das::ProServer::Config;
$| = 1;

use vars qw/%CHILDREN $CHILDREN $DEBUG $VERSION/;
$VERSION = "1.5";

sub new {
  my ($class, $config) = @_;
  my $self = bless {}, $class;
  $self->config($config);
  return $self;
}

sub config {
  my ($self, $config) = @_;
  $self->{'config'} = $config if($config);
  $self->{'config'} ||= Bio::Das::ProServer::Config->new();
  return $self->{'config'};
}

#########
# main control loop
#
sub handle {
  my $self     = shift;
  my $config   = $self->config();
  my $host     = $config->host();
  my $port     = $config->port();
  my $prefork  = $config->prefork();
  my $HOSTNAME = &hostname();
  my $PIDFILE  = $config->pidfile()?($config->pidfile()):"$0.$HOSTNAME.pid";
  my $DEBUG    = 1;

  $self->log("Proserver v$VERSION startup...");
  $self->log("Listening on host:port $host:$port");
  # establish SERVER socket, bind and listen.
  my $server   = HTTP::Daemon->new(
				   ReuseAddr => 1,
				   LocalAddr => $host,
				   LocalPort => $port,
				   ) or die "Cannot start daemon: $!\n";

  $self->socket_server($server);
  my $url = $server->url();

  # Fork off  children.
  for (1 .. $prefork) {
    $self->make_new_child();
  }
  $self->log("Started $prefork child servers");

  my $pid = $self->make_pid_file($PIDFILE);
  $self->log("Wrote parent PID to $PIDFILE [PID: $pid]");
  $self->log("Please contact this server at this URL: $url");

  # Install signal handlers.
  $SIG{CHLD}  = \&REAPER;
  $SIG{INT}   = \&HUNTSMAN;
  $SIG{TERM}  = \&HUNTSMAN;
  $SIG{USR1}  = \&RESTART;
  $SIG{HUP}   = \&RESTART;

  # And maintain the population.
  while (1) {
    sleep;                          # wait for a signal (i.e., child's death)
    for (my $i = $CHILDREN; $i < $prefork; $i++) {
      $self->make_new_child();           # top up the child pool
    }
  }
}

###########################################################################################  
sub RESTART {
  PURGE_CHILDREN();	# kill all our child processes (without exiting ourself)
  print STDERR "Received USR1/HUP signal: ProServer restarting...\n";

  my ($exe) = $0 =~ /([a-zA-Z0-9\/\._]+)/;

  my @detaintargs = ();
  for my $a (@ARGV) {
    my ($d) = $a =~ /([a-zA-Z0-9\/\._\-]+)/;
    push @detaintargs, $d;
  }

  print STDERR qq(Restarting $exe @detaintargs\n);
  exec $exe, @detaintargs;	  # replace ourself with a new copy
}

###########################################################################################  
sub make_new_child {

  my $self    = shift;
  my $config  = $self->config();
  my $server  = $self->socket_server();
  my $pid;
  my $sigset  = POSIX::SigSet->new(&POSIX::SIGINT);
  $sigset->addset(&POSIX::SIGHUP);

  my $sigset2 = POSIX::SigSet->new(&POSIX::SIGHUP);

  # block 'INT' signal during fork
  sigprocmask(SIG_BLOCK, $sigset) or die "Can't block SIGINT for fork: $!\n";
  die "fork: $!" unless defined ($pid = fork);

  if ($pid) {
    ###########################################################################################
    # Parent process code executes from here
    # Parent records the child's birth and returns.
    ###########################################################################################
    sigprocmask(SIG_UNBLOCK, $sigset) or die "Can't unblock SIGINT for fork: $!\n";
    $CHILDREN{$pid} = 1;
    $CHILDREN++;
    $self->log("Child born: $pid (Total children: $CHILDREN)\n") if $DEBUG;
    return;

  } else {
    ###########################################################################################
    # Child process code executes from here
    ###########################################################################################

    my $cleandetach = 0;

    $SIG{INT}  = 'DEFAULT';
    $SIG{HUP}  = sub { $self->log("Received SIGHUP, child $$ resigning\n"); exit; };
    $SIG{TERM} = sub { $cleandetach = 1; };

    sigprocmask(SIG_UNBLOCK, $sigset) or die "Can't unblock SIGINT for fork: $!\n";

    for (my $i=0; $i < $config->maxclients(); $i++) {
      if($cleandetach) {
	$self->log("Received SIGTERM. Clean child $$ exit");
	exit;
      }

      my $c   = $server->accept();
      next unless($c);
      my $req = $c->get_request();

      unless($req) {
	print STDERR qq(Daemon: Error! Accepted connection but could not build request object.\n);
	print STDERR qq(another get_req returns: ), $c->get_request(), "\n";
	next;
      }

      my $url = $req->uri();
      my $cgi;

      #########
      # process the parameters
      #
      if ($req->method() eq 'GET') {
	$cgi = CGI->new($url->query());

      } elsif ($req->method() eq 'POST') {
	$cgi = CGI->new($req->{'_content'});
      }

      $self->use_gzip(-1); # the default

      my $path   = $url->path();
      $self->log("Request: $path");
      $path      =~ m|das/([^/]+)(.*)|;
      my $dsn    = $1 || "";
      my $method = $2 || "";
      ($method)  = $method =~ m|([a-z_]+)|i;

      if ($req->header('Accept-Encoding') && ($req->header('Accept-Encoding') =~ /gzip/) ) {
	$self->use_gzip(1);
	$self->log("  compressing content [client understands gzip content]");
      }

      #########
      # recognised request type
      #
      if ($req->method() eq 'GET' || $req->method() eq 'POST') {
	my $res     = HTTP::Response->new();
	my $content = "";

	#########
	# unrecognised DSN
	#
	if($path ne "/das/dsn" && !$config->knows($dsn)) {
	  $c->send_error("401", "Bad data source");
	  $c->close();
	  $self->log("401 [Bad data source]");
	  next;
	}

	if  ($path eq "/das/dsn") {
	  $content .= $self->do_dsn_request($res);

	} elsif ($config->adaptor($dsn)->implements($method)) {

	  if($method eq "features") {
	    $content .= $self->do_feature_request($res, $dsn, $cgi);

	  } elsif ($method eq "stylesheet") {
	    $content .= $self->do_stylesheet_request($res, $dsn);

	  } elsif($method eq "dna") {
	    $content .= $self->do_dna_request($res, $dsn, $cgi);

	  } elsif($method eq "entry_points") {
	    $content .= $self->do_entry_points_request($res, $dsn, $cgi);

	  } elsif($method eq "types") {
	    $content .= $self->do_types_request($res, $dsn, $cgi);
	  }
	} elsif (!$method) {
	  $content .= $self->do_homepage_request($res, $dsn, $cgi);

	} else {
	  $c->send_error("501", "Unimplemented feature");
	  $c->close();
	  $self->log("501 [Unimplemented feature]");
	  next;
	}

	if( ($self->use_gzip() == 1) && (length($content) > 10000) ) {
	  $content = $self->gzip_content($content);
	  $res->content_encoding('gzip') if $content;
	  $self->use_gzip(0)
	}

	$res->content_length(length($content));
	$res->content($content);
	$c->send_response($res);

	#########
	# unrecognised request type
	#
      } else {
	$c->send_error(RC_FORBIDDEN);
      }

      $c->close();
      if($cleandetach) {
	$self->log("Received SIGTERM. Clean child $$ shutdown");
	exit;
      }
    }

    print STDERR  "Child $$: reached max client count - exiting.\n";
    exit; ## very, very important exit!
  }
}

########################################################################################
# DAS method: entry_points
#
sub do_entry_points_request {
  my ($self, $res, $dsn, $cgi) = @_;

  my $adaptor = $self->adaptor($dsn);
  my $content = $adaptor->open_dasep();
  $content   .= $adaptor->das_entry_points();
  $content   .= $adaptor->close_dasep();

  $self->header($res, $adaptor);

  return $content;
}

#########
# DAS method: types
#
sub do_types_request {
  my ($self, $res, $dsn, $cgi) = @_;

  my $adaptor = $self->adaptor($dsn);
  my $content = $adaptor->open_dastypes();
  my @segs    = $cgi->param('segment');
  $content   .= $adaptor->das_types({'segments' => \@segs});
  $content   .= $adaptor->close_dastypes();

  $self->header($res, $adaptor);

  return $content;
}

#########
# DAS method: features/1.0
#
sub do_feature_request {
  my ($self, $res, $dsn, $cgi) = @_;

  my $adaptor  = $self->adaptor($dsn);
  my $content  = $adaptor->open_dasgff();
  my @segs     = $cgi->param('segment');
  my @features = $cgi->param('feature_id');

  for my $segment (@segs) {
    $self->log("  segment ===> $segment");
  }

  $content .= $adaptor->das_features({
				      'segments' => \@segs,
				      'features' => \@features,
				     });
  $content .= $adaptor->close_dasgff();

  $self->header($res, $adaptor);

  return $content;
}

#########
# DAS method: dna / sequence
#
sub do_dna_request {
  my ($self, $res, $dsn, $cgi) = @_;

  my $adaptor = $self->adaptor($dsn);
  my $content = $adaptor->open_dassequence();
  my @segs    = $cgi->param('segment');

  for my $segment (@segs) {
    $self->log("  segment ===> $segment");
  }

  $content .= $adaptor->das_dna(\@segs);
  $content .= $adaptor->close_dassequence();

  $self->header($res, $adaptor);

  return $content;
}

#########
# DAS method: dsn
#
sub do_dsn_request {
  my ($self, $res) = @_;

  my $adaptor = $self->adaptor();
  my $content = $adaptor->das_dsn();
  $self->header($res, $adaptor);

  return $content;
}

#########
# DAS method: stylesheet
#
sub do_stylesheet_request {
  my ($self, $res, $dsn) = @_;

  my $adaptor = $self->adaptor($dsn);
  my $content = $adaptor->das_stylesheet();
  $self->header($res, $adaptor);

  return $content;
}

#########
# Non-standard source information/homepage
#
sub do_homepage_request {
  my ($self, $res, $dsn) = @_;

  my $adaptor = $self->adaptor($dsn);
  my $content = $adaptor->das_homepage();
  $res->code("200 OK");
  $res->header("Content-Type" => "text/html");

  return $content;
}

#########
# DAS/HTTP headers
#
sub header {
  my ($self, $response, $adaptor, $code) = @_;
  my $config = $self->config();

  $response->code($code || "200 OK"); # is this the right format?
  $response->header('Content-Type'       => 'text/plain');
  $response->header('X_DAS_Version'      => $config->das_version());
  $response->header('X_DAS_Status'       => $code || "200 OK");
  $response->header('X_DAS_Capabilities' => $adaptor->das_capabilities());
}

#########
# handle gzipped content
#
sub gzip_content {
  my ($self, $content) = @_;

  if($content && $self->use_gzip()) {
    my $d = Compress::Zlib::memGzip($content);
    return $d if ($d);

    warn ("Content compression failed: $!\n");
    return(undef);

  } else {
    warn ("Inconsistent request for gzip content\n");
  }
}

#########
# gzip on/off helper
#
sub use_gzip {
  my ($self, $var)    = @_;
  $self->{'use_gzip'} = $var if($var);
  return($self->{'use_gzip'});
}

#########
# return an appropriate adaptor object given a DSN
#
sub adaptor {
  my ($self, $dsn) = @_;
  return $self->config->adaptor($dsn);
}

#########
# return an appropriate adaptor object given a DSN
#
sub socket_server {
  my ($self, $s) = @_;
  if ($s) {
    $self->{'_socket_server'} = $s;
  }
  return ($self->{'_socket_server'});
}

#########
# debug log
#
sub log {
  my ($self, @messages) = @_;
  for my $m (@messages) {
    print STDERR "$m\n";
  }
}

###########################################################
# create a PID file so we can be sent a TERM/INT signal
#
sub make_pid_file {
  my ($self, $pidfile) = @_;

  ($pidfile) = $pidfile =~ /([a-zA-Z0-9\.\/_\-]+)/;
  open (PID, ">$pidfile") or die "Cannot create pid file: $!\n";
  print PID "$$\n";
  close(PID);
  return($$);
}

###########################################################
sub REAPER {                        	# takes care of dead children
  my $sigset  = POSIX::SigSet->new(&POSIX::SIGCHLD);
  sigprocmask(SIG_BLOCK, $sigset) or die "Can't block SIGCHLD for reaper: $!\n";
  my $pid = wait;
  if (delete $CHILDREN{$pid}){
    $CHILDREN--;
  } else {
    #warn("Attempted to delete a non-child PID: $pid!\n") if $DEBUG;
    #warn("Child PIDs are:\n", join("\n",keys %CHILDREN), "\n") if $DEBUG;
  }
  sigprocmask(SIG_UNBLOCK, $sigset);
  print STDERR "Got SIGCHLD from: $pid\n";
  $SIG{CHLD} = \&REAPER;
}

###########################################################
sub HUNTSMAN {                      	# signal handler for SIGINT
  &PURGE_CHILDREN();
  exit;                           	# clean up with dignity
}

###########################################################
sub PURGE_CHILDREN {                      	# signal handler for SIGINT
  local($SIG{CHLD}) = 'IGNORE';   	# we're going to kill our children
  print STDERR "Killing children...\n";
  kill 'TERM' => keys %CHILDREN;
}

###########################################################
1;
