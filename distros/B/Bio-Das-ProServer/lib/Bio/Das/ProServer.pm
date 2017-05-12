#########
# ProServer DAS Server
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2003-05-22
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Source:        $Source $
# Id:            $Id $
#
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
## no critic (Variables::RequireLocalizedPunctuationVars)
## no critic (ControlStructures::ProhibitCascadingIfElse)
#
package Bio::Das::ProServer;
use warnings;
use strict;
use Bio::Das::ProServer::Config;
use CGI qw(:cgi);
use HTTP::Request;
use HTTP::Response;
use Compress::Zlib;
use Getopt::Long;
use POE;                         # Base features.
use POE::Filter::HTTPD;          # For serving HTTP content.
use POE::Wheel::ReadWrite;       # For socket I/O.
use POE::Wheel::SocketFactory;   # For serving socket connections.
use POSIX qw(setsid strftime);
use File::Spec;
use Sys::Hostname;
use Bio::Das::ProServer::SourceAdaptor;
use Bio::Das::ProServer::SourceHydra;
use Socket;
use English qw(-no_match_vars);
use Carp;
use Readonly;

our $DEBUG          = 0;
our $VERSION        = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };
Readonly::Scalar our $GZIP_THRESHOLD => 10_000;
$ENV{'PATH'}        = '/bin:/usr/bin:/usr/local/bin';
our $COORDINATES    = undef;
Readonly::Scalar our $WRAPPERS => {
  # Note that the xml-stylesheet processing instructions below use the 'text/xsl' media type, this is technically incorrect as it is not a registered type, really it should be 'application/xslt+xml' but text/xsl is universally supported by browsers
  'sources'      => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<?xml-stylesheet type="text/xsl" href="sources.xsl"?>\n<SOURCES>\n),
                     'close' => qq(</SOURCES>\n),
                    },
  'dsn'          => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<?xml-stylesheet type="text/xsl" href="dsn.xsl"?>\n<!DOCTYPE DASDSN SYSTEM 'http://www.biodas.org/dtd/dasdsn.dtd' >\n<DASDSN>\n),
                     'close' => qq(</DASDSN>\n),
                    },
  'features'     => {
                     'open'  => qq(<?xml version="1.0" standalone="yes"?>\n<?xml-stylesheet type="text/xsl" href="features.xsl"?>\n<!DOCTYPE DASGFF SYSTEM "http://www.biodas.org/dtd/dasgff.dtd">\n<DASGFF>\n  <GFF href="%sourceurl/features">\n),
                     'close' => qq(  </GFF>\n</DASGFF>\n),
                    },
  'dna'          => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<?xml-stylesheet type="text/xsl" href="sequence.xsl"?>\n<!DOCTYPE DASDNA SYSTEM "http://www.biodas.org/dtd/dasdna.dtd">\n<DASDNA>\n),
                     'close' => qq(</DASDNA>\n),
                    },
  'sequence'     => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<?xml-stylesheet type="text/xsl" href="sequence.xsl"?>\n<!DOCTYPE DASSEQUENCE SYSTEM "http://www.biodas.org/dtd/dassequence.dtd">\n<DASSEQUENCE>\n),
                     'close'  => qq(</DASSEQUENCE>\n),
                    },
  'types'        => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<?xml-stylesheet type="text/xsl" href="types.xsl"?>\n<!DOCTYPE DASTYPES SYSTEM "http://www.biodas.org/dtd/dastypes.dtd">\n<DASTYPES>\n  <GFF version="1.0" href="%sourceurl/types">\n),
                     'close'  => qq(  </GFF>\n</DASTYPES>\n),
                    },
  'entry_points' => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<!DOCTYPE DASEP SYSTEM "http://www.biodas.org/dtd/dasep.dtd">\n<DASEP>\n  <ENTRY_POINTS href="%sourceurl/entry_points" version="1.0">\n),
                     'close'  => qq(  </ENTRY_POINTS>\n</DASEP>\n),
                    },
  'alignment'    => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<dasalignment xmlns="http://www.efamily.org.uk/xml/das/2004/06/17/dasalignment.xsd" xmlns:align="http://www.efamily.org.uk/xml/das/2004/06/17/alignment.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema-instance" xsd:schemaLocation="http://www.efamily.org.uk/xml/das/2004/06/17/dasalignment.xsd http://www.efamily.org.uk/xml/das/2004/06/17/dasalignment.xsd">\n),
                     'close'  => qq(</dasalignment>\n),
                    },
  'structure'    => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<dasstructure xmlns="http://www.efamily.org.uk/xml/das/2004/06/17/dasstructure.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema-instance" xsd:schemaLocation="http://www.efamily.org.uk/xml/das/2004/06/17/dasstructure.xsd">\n),
                     'close'  => qq(</dasstructure>\n),
                    },
  'interaction'  => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<DASINT xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://dasmi.de/" xsi:schemaLocation="http://dasmi.de/ http://dasmi.de/dasint.xsd">\n),
                     'close'  => qq(</DASINT>\n),
                    },
  'volmap'       => {
                     'open'  => qq(<?xml version="1.0" standalone="no"?>\n<!DOCTYPE DASVOLMAP SYSTEM "http://biocomp.cnb.uam.es/das/dtd/dasvolmap.dtd">\n<DASVOLMAP version="1.0">\n),
                     'close'  => qq(</DASVOLMAP>\n),
                    },
  'stylesheet'   => {
                     'open'  => q(),
                     'close'  => q(),
                    },
};

sub run {
  my $class       = shift;
  my $self        = bless {}, $class;
  my $opts        = {};
  $self->{'opts'} = $opts;
  my @saveargv    = @ARGV;
  my $result      = GetOptions(
                               $opts,
                               qw(debug
                                  version
                                  port=i
                                  help|h|usage
                                  hostname=s
                                  inifile|config|c=s
                                  pidfile=s
                                  logfile=s
                                  X|x),
                              );
  $DEBUG   = $opts->{'debug'};
  my $vstr = "ProServer DAS Server v$VERSION (c) GRL 2007";

  if($opts->{'version'}) {
    print $vstr, "\n" or croak $OS_ERROR;
    return;
  }

  my @msg = ($vstr,
             'http://www.sanger.ac.uk/proserver/', q(),
             'Please cite:',
             ' ProServer: A simple, extensible Perl DAS server.',
             ' Finn RD, Stalker JW, Jackson DK, Kulesha E, Clements J, Pettett R.',
             ' Bioinformatics 2007; doi: 10.1093/bioinformatics/btl650; PMID: 17237073',
            );

  my $maxmsg = (sort { $a <=> $b } map { length $_ } @msg)[-1];

  print  q(#)x($maxmsg+6), "\n" or croak $OS_ERROR;
  for my $m (@msg) {
    printf qq(#  %-${maxmsg}s  #\n), $m or croak $OS_ERROR;
  }
  print  q(#)x($maxmsg+6), "\n\n" or croak $OS_ERROR;

  @ARGV = @saveargv; ## no critic

  if($opts->{'help'}) {
    print <<'EOT' or croak $ERRNO;
 -debug           # Enable extra debugging
 -port   <9000>   # Listen on this port (overrides configuration file)
 -hostname <*>    # Listen on this interface x (overrides configuration file)
 -pidfile <*>     # Use this process ID file (overides configuration file)
 -logfile <*>     # Use this log file (overides configuration file)
 -help            # This help
 -config          # Use this configuration file
 -x               # Development mode - disables server forking
 
 To stop the server:
   kill -TERM `cat eg/proserver.myhostname.pid`

 To restart the server:
   kill -USR1 `cat eg/proserver.myhostname.pid`
EOT
    return;
  }

  if(!$opts->{'inifile'}) {
    $opts->{'inifile'} = File::Spec->catfile('eg', 'proserver.ini');
    $class->log(qq(Using default '$opts->{'inifile'}' file.));
  }

  if(!-e $opts->{'inifile'}) {
    $class->log(qq(Invalid configuration file: $opts->{'inifile'}. Stopping.));
    return;
  }

  # backwards-compatibility switch
  $opts->{'interface'} = $opts->{'hostname'};
  delete $opts->{'hostname'};

  my $config = Bio::Das::ProServer::Config->new($opts);
  $self->{'config'} = $config;

  # Load in the co-ordinates file
  my $coord_dir  = $config->{'coordshome'};
  my %all_coords = ();

  for my $coordfile ( glob File::Spec->catfile($coord_dir, '*.xml') ) {
    open my $fh_coord, q(<), $coordfile or croak "Unable to open coordinates file $coordfile";
    my @coordfull;
    while (my $blk = <$fh_coord>) {
      $blk =~ s{^\s*(<\?xml.*?>)?(\s*</?DASCOORDINATESYSTEM>\s*)?}{}mixs;
      $blk =~ s/\s*$//mxs;
      push @coordfull, grep { $_ }
                       split m{</COORDINATES>}mxs, $blk;
    }
    close $fh_coord or croak "Unable to close coordinates file $coordfile";

    my %coords;
    for (@coordfull) {
      my ($uri) = m/uri\s*=\s*"(.*?)"/mxs;
      my ($des) = m/>(.*)$/mxs;
      $coords{lc $des} = $coords{lc $uri} = {
        'uri'         => $uri,
        'description' => $des,
        'source'      => my ($t)  = m/source\s*=\s*"(.*?)"/mxs,
        'authority'   => my ($au) = m/authority\s*=\s*"(.*?)"/mxs,
        'version'     => my ($v)  = m/version\s*=\s*"(.*?)"/mxs,
        'taxid'       => my ($s)  = m/taxid\s*=\s*"(.*?)"/mxs,
      };
    }

    $class->log(q(Loaded ).((scalar keys %coords)/2)." co-ordinate systems from $coordfile");
    %all_coords = (%all_coords, %coords);
  }
  $COORDINATES = \%all_coords;

  if($opts->{'X'}) {
    $config->maxclients(0);
  } else {
    if (fork) {
      $class->log(qq(Parent process $PID detached...));
      return;
    } else {
      $class->log(qq(Child process $PID continuing...));
      if (POE::Kernel->can('has_forked')) {
        $poe_kernel->has_forked();
      }
    }
  }

  setsid() or croak 'Cannot setsid';

  my $pidfile = $opts->{'pidfile'} || $config->pidfile() || sprintf '%s.%s.pid', $PROGRAM_NAME||'proserver', hostname() || 'localhost';
  $self->make_pidfile($pidfile);

  my $logfile = $opts->{'logfile'} || $config->logfile();
  if (!defined $logfile) {
    my ($vol, $path) = File::Spec->splitpath($pidfile);

    if(!$path) {
      ($vol, $path) = File::Spec->splitpath($opts->{'inifile'});
    }

    $logfile = File::Spec->catpath($vol, $path, sprintf 'proserver.%s.log', hostname() );
  }

  open STDIN, '<', File::Spec->devnull or croak "Can't open STDIN from the null device: [$ERRNO]";
  if(!$opts->{'X'}) {
    my $errlog = $logfile;
    $errlog    =~ s/\.log$/.err/mxs;
    $class->log(qq(Logging STDOUT to $logfile and STDERR to $errlog));
    open STDOUT, '>>', $logfile or croak "Can't open STDOUT to $logfile: [$ERRNO]";
    open STDERR, '>>', $errlog  or croak "Can't open STDERR to STDOUT: [$ERRNO]";
  }

  if(exists $config->{'ensemblhome'}) {
    my ($eroot) = $config->{'ensemblhome'} =~ m{([a-zA-Z0-9_/\.\-]+)}mxs;
    $ENV{'ENS_ROOT'}     = $eroot;
    unshift @INC, File::Spec->catdir($eroot, 'ensembl' , 'modules');
    $class->log(qq(Set ENS_ROOT to $ENV{'ENS_ROOT'}));
  }

  if(exists $config->{'oraclehome'}) {
    $ENV{'ORACLE_HOME'}  = $config->{'oraclehome'};
    $class->log(qq(Set ORACLE_HOME to $ENV{'ORACLE_HOME'}));
  }

  if(exists $config->{'bioperlhome'}) {
    my ($broot) = $config->{'bioperlhome'} =~ m{([a-zA-Z0-9_/\.\-]+)}mxs;
    $ENV{'BIOPERL_HOME'} = $broot;
    unshift @INC, $broot;
    $class->log(qq(Set BIOPERL_HOME to $ENV{'BIOPERL_HOME'}));
  }

  $self->{'logformat'} = $config->logformat();

  # Spawn up to max server processes, and then run them.  Exit
  # when they are done.

  $class->log(q(Proserver started));

  $self->server_spawn($config->maxclients());
  $poe_kernel->run();
  return;
}

sub DEBUG { return $DEBUG; } # Enable a lot of runtime information.

### Spawn the main server.  This will run as the parent process.

sub server_spawn {
  my ($self, $max_processes) = @_;

  return POE::Session->create(
           inline_states => {
             _start         => \&server_start,
             _stop          => \&server_stop,
             do_fork        => \&server_do_fork,
             got_error      => \&server_got_error,
             got_sig_hup    => \&server_got_sig_hup,
             got_sig_int    => \&server_got_sig_int,
             got_sig_chld   => \&server_got_sig_chld,
             got_connection => \&server_got_connection,
             _child         => sub { 0 },
           },
           heap => {
             max_processes => $max_processes,
             self          => $self,
           },
         );
}

### The main server session has started.  Set up the server socket and
### bookkeeping information, then fork the initial child processes.

sub server_start {
  my @args = @_;
  my ( $kernel, $heap ) = @args[ KERNEL, HEAP ]; ## no critic
  my $config = $heap->{'self'}->{'config'};

  $heap->{server} = POE::Wheel::SocketFactory->new
    ( BindAddress    => $config->interface()||undef,
      BindPort       => $config->port(),
      SuccessEvent   => 'got_connection',
      FailureEvent   => 'got_error',
      Reuse          => 'on',
      SocketDomain   => AF_INET,
      SocketType     => SOCK_STREAM,
      SocketProtocol => 'tcp',
      ListenQueue    => SOMAXCONN,
    );

  $kernel->sig( INT   => 'got_sig_int' );
  $kernel->sig( TERM  => 'got_sig_int' );
  $kernel->sig( KILL  => 'got_sig_int' );
  $kernel->sig( HUP   => 'got_sig_hup' );
  $kernel->sig( USR1  => 'got_sig_hup' );

  $heap->{children}   = {};
  $heap->{is_a_child} = 0;

  carp sprintf q(Server %d has begun listening on %s:%d),
    $PID,
    $config->interface() || q(*),
    $config->port();

  $kernel->yield('do_fork');
  carp 'Exited fork';
  return;
}

### The server session has shut down.  If this process has any
### children, signal them to shutdown too.

sub server_stop {
  my @args = @_;
  my $heap = $args[HEAP];
  DEBUG and carp "Server $PID stopped.\n";
  $heap->{'is_a_child'} && return;
  return $heap->{'self'}->remove_pidfile();
}

### The server session has encountered an error.  Shut it down.

sub server_got_error {
  my @args = @_;
  my ( $heap, $syscall, $errno, $error ) = @args[ HEAP, ARG0 .. ARG2 ];
  DEBUG and
    carp( "Server $PID got $syscall error $errno: $error\n",
          "Server $PID is shutting down.\n",
        );
  delete $heap->{server};
  return;
}

### The server has a need to fork off more children.  Only honor that
### request form the parent, otherwise we would surely "forkbomb".
### Fork off as many child processes as we need.

sub server_do_fork {
  my @args = @_;
  my ( $kernel, $heap ) = @args[ KERNEL, HEAP ];

  return if $heap->{is_a_child};

  my $current_children = keys %{ $heap->{children} };
  for ( $current_children + 2 .. $heap->{max_processes} ) {

    DEBUG and carp "Server $PID is attempting to fork.\n";

    my $pid = fork;

    if(!defined $pid) {
      DEBUG and
        carp( "Server $PID fork failed: $ERRNO\n",
              "Server $PID will retry fork shortly.\n",
            );
      $kernel->delay( do_fork => 1 );
      return;
    }

    # Parent.  Add the child process to its list.
    if ($pid) {
      DEBUG and carp "Server $PID forked child $pid\n";
      $heap->{children}->{$pid} = 1;
      $kernel->sig_child($pid, 'got_sig_chld');
      next;
    }

    # Child.  Clear the child process list.
    if (POE::Kernel->can('has_forked')) {
      $kernel->has_forked();
    }
    $heap->{is_a_child} = 1;
    $heap->{children}   = {};
    $heap->{hitcount}   = 0;
    return;
  }
  return;
}

### The server session received SIGHUP.  Re-execute this process, remembering any argv options

sub server_got_sig_hup {
  my (@args) = @_;
  DEBUG and carp "Server $PID received SIGHUP|USR1.\n";

  #########
  # shutdown children
  #
  server_stop(@args);

  #########
  # exec(self)
  #
  __PACKAGE__->log(qq(0=$PROGRAM_NAME, argv=@ARGV));
  return exec $PROGRAM_NAME, @ARGV;
}

### The server session received SIGINT.  Make sure the signal is sent to
### child processes too. With no resources left in use, the process will exit.

sub server_got_sig_int {
  my ( $kernel, $heap, $signame ) = @_[ KERNEL, HEAP, ARG0 ];

  DEBUG and carp "Server $PID received $signame.\n";
  delete $heap->{server};
  if ( !$heap->{is_a_child} ) {
    kill $signame, keys %{ $heap->{children} };
  }
  $kernel->sig_handled();

  return 0;
}

### The server session received a SIGCHLD, indicating that some child
### server has gone away.  Remove the child's process ID from our
### list, and trigger more fork() calls to spawn new children.

sub server_got_sig_chld {
  my ( $kernel, $heap, $child_pid ) = @_[ KERNEL, HEAP, ARG1 ];

  if ( delete $heap->{children}->{$child_pid} ) {
    DEBUG and carp "Server $PID reaped child $child_pid via SIGCHLD.\n";
    if ( exists $heap->{server} ) {
      $kernel->yield('do_fork');
    }
  }
  return 0;
}

### The server session received a connection request.  Spawn off a
### client handler session to parse the request and respond to it.

sub server_got_connection {
  my ( $heap, $socket, $peer_addr, $peer_port ) = @_[ HEAP, ARG0, ARG1, ARG2 ];

  DEBUG and carp "Server $PID received a connection.\n";

  POE::Session->create(
                       inline_states =>
                       { _start      => sub {
                           eval {
                             client_start(@_);
                             1;
                           } or do {
                             carp $EVAL_ERROR;
                           };
                         },
                         _stop       => \&client_stop,
                         got_request => sub {
                           eval {
                             client_got_request(@_);
                             1;
                           } or do {
                             carp $EVAL_ERROR;
                           };
                         },
                         got_flush   => \&client_flushed_request,
                         got_error   => \&client_got_error,
                         _parent     => sub { 0 },
                       },
                       heap =>
                       { self      => $heap->{'self'},
                         socket    => $socket,
                         peer_addr => $peer_addr,
                         peer_port => $peer_port,
                       },
                      );

  return;
}

### The client handler has started.  Wrap its socket in a ReadWrite
### wheel to begin interacting with it.

sub client_start {
  my ($heap, $session) = @_[HEAP, SESSION];

  $heap->{client} = POE::Wheel::ReadWrite->new(
                                               Handle       => $heap->{socket},
                                               Filter       => POE::Filter::HTTPD->new(),
                                               InputEvent   => 'got_request',
                                               ErrorEvent   => 'got_error',
                                               FlushedEvent => 'got_flush',
                                              );

  DEBUG and carp "Client handler $PID/", $session->ID, " started.\n";
  return;
}

### The client handler has stopped.  Log that fact.

sub client_stop {
  my $session = $_[SESSION];
  DEBUG and carp "Client handler $PID/", $session->ID, " stopped.\n";
  return;
}

### The client handler has received a request.  If it's an
### HTTP::Response object, it means some error has occurred while
### parsing the request.  Send that back and return immediately.
### Otherwise parse and process the request, generating and sending an
### HTTP::Response object in response.

sub client_got_request {
  my ( $heap, $session, $request) = @_[ HEAP, SESSION, ARG0 ];

  DEBUG and
    carp "Client handler $PID/", $session->ID, " is handling a request.\n";

  if ( $request->isa('HTTP::Response') ) {
    $heap->{client}->put($request);

  } else {
    my $response = build_das_response($heap, $request);
    $heap->{hitcount}++;
    $heap->{client}->put($response);
  }

  return;
}

sub response_xsl {
  my ($heap, $request, $call) = @_;
  my $config   = $heap->{'self'}->{'config'};
  my $response = HTTP::Response->new(200);
  #$response->content_type( _content_type($request, 'application/xslt+xml', 'application/xml', 'text/xsl', 'text/xml') );
  $response->content_type( 'text/xsl' );
  $response->content( _substitute( $heap, $config->adaptor()->das_xsl({'call'=>$call}) ) );
  return $response;
}

sub response_general {
  my ($heap, $request, $dsn, $call, $cgi) = @_;

  my $response;

  my $config  = $heap->{'self'}->{'config'};
  eval {
    my $adaptor = $config->adaptor($dsn);

    # Perform authentication (if specified)
    if (my $authenticator = $adaptor->authenticator()) {
      $response = $authenticator->authenticate({
                                                  'socket'    => $heap->{'socket'},
                                                  'peer_addr' => $heap->{'peer_addr'},
                                                  'peer_port' => $heap->{'peer_port'},
                                                  'request'   => $request,
                                                  'cgi'       => $cgi,
                                                  'call'      => $call,
                                                  });
      # If the authenticator returns a response, use it (exit the eval)
      defined $response && return;
    }

    $response = HTTP::Response->new(200);
    my $method   = "das_$call";
    if(substr($call, -3, 3) eq 'xsl') {
      $method = 'das_xsl';
      $response->content_type( _content_type($request, 'application/xslt+xml', 'application/xml', 'text/xsl', 'text/xml') );
    } else {
      $response->content_type( _content_type($request, 'application/xml', 'text/xml') );
    }

    my $query   = { 'call' => $call };

    if ($call eq 'features') {
      $query->{'segments'}   = [$cgi->param('segment')];
      $query->{'types'}      = [$cgi->param('type')];
      $query->{'categories'} = [$cgi->param('category')];
      $query->{'categorize'} = $cgi->param('categorize') || undef;
      if ($adaptor->implements('feature-by-id')) {
        $query->{'features'}   = [$cgi->param('feature_id')];
      }
      if ($adaptor->implements('maxbins')) {
        $query->{'maxbins'} = $cgi->param('maxbins') || undef;
      }
    }

    elsif ($call eq 'types' || $call eq 'sequence' || $call eq 'dna') {
      $query->{'segments'} = [$cgi->param('segment')];
    }

    elsif ($call eq 'entry_points') {
      $query->{'rows'} = $cgi->param('rows') || undef;
    }

    elsif ($call eq 'alignment') {
      $query->{'queries'}  = [$cgi->param('query')];
      $query->{'subjects'} = [$cgi->param('subject')];
      $query->{'rows'}     = $cgi->param('rows') || undef;
      $query->{'cols'}     = $cgi->param('cols') || undef;
      $query->{'subcoos'}  = $cgi->param('subjectcoordsys') || undef;
    }

    elsif ($call eq 'structure') {
      $query->{'query'}  = $cgi->param('query') || undef;
      $query->{'chains'} = [$cgi->param('chain')];
      $query->{'models'} = [$cgi->param('model')];
    }

    elsif ($call eq 'interaction') {
      $query->{'interactors'} = [$cgi->param('interactor')];
      $query->{'details'}     = [$cgi->param('detail')];
      $query->{'operation'}   = $cgi->param('operation') || undef;
    };

    if($adaptor->implements($call) || $method eq 'das_xsl') {

      my $use_gzip = 0;
      my $enc = $request->header('Accept-Encoding') || q();
      if($enc =~ /gzip/mixs) {
        if(DEBUG) {
          carp 'Client accepts compression';
        }
        $use_gzip = 1;
      }

      my ($head, $foot) = (q[], q[]);
      if(exists $WRAPPERS->{$call}) {
        $head = $WRAPPERS->{$call}->{open};
        $foot = $WRAPPERS->{$call}->{close};
      }
      my $body    = $adaptor->$method($query);
      $head = _substitute($heap, $head, $dsn);
      if ($method eq 'das_xsl') {
        $body = _substitute($heap, $body, $dsn);
      }
      $response->last_modified($adaptor->dsncreated_unix);
      $response->expires(time() + 30); # limit cacheability to 30 seconds from now
      my $content = $head.$body.$foot;

      if($use_gzip && (length $content > $GZIP_THRESHOLD)) {
        if(DEBUG) {
          carp 'Compressing content';
        }

        my $squashed = Compress::Zlib::memGzip($content);

        if($squashed) {
          $content = $squashed;
          $response->content_encoding('gzip');

        } else {
          carp 'Content compression failed: ', $ERRNO, "\n";
        }
      }

      $response->content($content);

    } elsif($call eq 'stylesheet') {
      $response->content_type('text/plain');
      $response->header('X-DAS-Status' => 404);
      $response->content('Bad stylesheet (requested stylesheet unknown)');

    } elsif(!exists $WRAPPERS->{$call}) {
      $response->content_type('text/plain');
      $response->header('X-DAS-Status' => 400);
      $response->content("Bad command (command not recognized: $call)");

    } else {
      $response->content_type('text/plain');
      $response->header('X-DAS-Status' => 501);
      $response->content(qq(Unimplemented command for $dsn: @{[$call||q()]}));
    }

    1;

  } or do {
    carp $EVAL_ERROR;

    chomp( my $err = $EVAL_ERROR );
    $response = HTTP::Response->new(500);
    $response->content_type('text/plain');
    $response->header('X-DAS-Status' => 500);
    $response->content("Bad data source $dsn (error processing command: '$call')\n\nThe error was: '$err'");
  };

  return $response;
}

sub response_dsn {
  my ($heap, $request) = @_;
  my $config  = $heap->{'self'}->{'config'};
  my $resp    = _substitute( $heap, $WRAPPERS->{'dsn'}->{'open'} );
  for my $adaptor (sort { lc $a->dsn cmp lc $b->dsn } grep { defined $_ } $config->adaptors()) {
    $resp .= $adaptor->das_dsn();
  }
  $resp .= $WRAPPERS->{'dsn'}->{'close'};
  my $response = HTTP::Response->new(200);
  $response->content_type( _content_type($request, 'application/xml', 'text/xml') );
  $response->content($resp);
  return $response;
}

sub response_sources {
  my ($heap, $request, $call) = @_;
  # Note that structure of 'sources' call has two formats (baseuri/das/sources or baseuri/das/<dsn>)
  my $config  = $heap->{'self'}->{'config'};
  my %data;
  grep {
    defined $_ &&
    (!$call || $call eq $_->dsn || $call eq $_->source_uri || $call eq $_->version_uri) &&
    ($data{$_->source_uri}{$_->version_uri} = $_);
  } $config->adaptors();

  my $resp = _substitute( $heap, $WRAPPERS->{'sources'}->{'open'}, $call );
  while (my ($s_uri, $s_data) = each %data) {
    my @versions = keys %{$s_data};
    if(!scalar @versions) {
      next;
    }

    for my $i (0..(scalar @versions -1)) {
      eval {
        $resp .= $s_data->{$versions[$i]}->das_sourcedata({
                                                           'skip_open'  => $i > 0,
                                                           'skip_close' => $i+1 < scalar @versions,
                                                          });
      } or do {
        carp "Error generating source data for '$versions[$i]':\n$EVAL_ERROR\n";
      };
    }
  }
  $resp .= $WRAPPERS->{'sources'}->{'close'};

  my $response = HTTP::Response->new(200);
  $response->content_type( _content_type($request, 'application/xml', 'text/xml') );
  $response->content($resp);
  return $response;
}

sub response_homepage {
  my ($heap, $request) = @_;
  my $config  = $heap->{'self'}->{'config'};
  my $response = HTTP::Response->new(200);
  $response->content_type( _content_type($request, 'application/xhtml+xml', 'text/html', 'application/xml', 'text/xml') );
  my $content = _substitute( $heap, q(<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="%baseuri/das/homepage.xsl"?>
) );
  $content .= q(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <title>Welcome to ProServer</title>
    <style type="text/css">
html,body{background:#ffc;font-family:helvetica,arial,sans-serif}
thead{background-color:#700;color:#fff}
thead th{margin:0;padding:2px}
a{color:#a00;}a:hover{color:#aaa}
.cite ul{list-style:none;padding:0;margin:0;}.cite li{display:inline;font-style:oblique;padding-right:0.5em}
.cite{margin-bottom:1em}
.footer_links{font-size:small;text-align:center;}
    </style>
  </head>
  <body>
  <div id="homepage_content">
  <div id="heading"><h1>Welcome to ProServer</h1></div>
  <div id="mainbody">
<p><i>Core by Roger Pettett &copy; Genome Research Ltd.</i></p>
<div class="cite">
<b>ProServer: A simple, extensible Perl DAS server.</b>
<ul><li>Finn RD,</li><li>Stalker JW,</li><li>Jackson DK,</li><li>Kulesha E,</li><li>Clements J,</li><li>Pettett R.</li></ul>
Bioinformatics 2007; <a href="http://bioinformatics.oxfordjournals.org/cgi/content/abstract/btl650v1">doi: 10.1093/bioinformatics/btl650</a>; PMID: 17237073
</div>
);

  $content .= sprintf q(<p>You can view a list of data sources available from this server via a <a href="%s/das/sources">SOURCES</a> or <a href="%1$s/das/dsn">DSN</a> request.</p>)."\n", ## no critic
              $config->server_url();

  $content .= '<h3>Server Maintainer:</h3>';
  my $maintainer = $config->{'maintainer'};
  if ($maintainer) {
    $content .= qq(<p><a href="mailto:$maintainer">$maintainer</a></p>\n);
  } else {
    $content .= qq(<p>This server has no configured maintainer.</p>\n);
  }

  $content .= '<h3>DAS Version:</h3>';
  $content .= '<p>'.$config->das_version.'</p>';

  $content .= '<h3>Loaded modules:</h3><ul>';
  for my $module ((map { 'Bio::Das::'.$_ }                                      sort keys %Bio::Das::),
                  (map { 'Bio::Das::ProServer::'.$_ }                           sort keys %Bio::Das::ProServer::),
                  (map { 'Bio::Das::ProServer::Authenticator::'.$_ }            sort keys %Bio::Das::ProServer::Authenticator::),
                  (map { 'Bio::Das::ProServer::SourceAdaptor::'.$_ }            sort keys %Bio::Das::ProServer::SourceAdaptor::),
                  (map { 'Bio::Das::ProServer::SourceAdaptor::Transport::'.$_ } sort keys %Bio::Das::ProServer::SourceAdaptor::Transport::),
                  (map { 'Bio::Das::ProServer::SourceHydra::'.$_ }              sort keys %Bio::Das::ProServer::SourceHydra::),
                 ) {

    if($module !~ /::$/mxs) {
      next;
    }

    my $cpkg  = substr $module, 0, -2;
    my $str   = $cpkg->VERSION;
    $str || next;
    $content .= qq(<li>$cpkg v$str</li>\n);
  }

  $content .= qq(
</ul>
<br /><br /><br />
<div class="footer_links"><a href="http://www.sanger.ac.uk/proserver/">ProServer homepage</a> | <a href="http://www.dasregistry.org/">DAS registry</a> | <a href="http://biodas.org/">BioDAS.org</a></div>
</div></div>
</body>
</html>\n);

  $response->content($content);
  return $response;
}

sub build_das_response {
  my ($heap, $request) = @_;

  my $response;
  my $uri          = $request->uri();
  my $config = $heap->{'self'}->{'config'};
  my $cgi;
  my $http_method = lc $request->method();

  #########
  # Check the HTTP method being used
  #
  if ($http_method eq 'get' || $http_method eq 'post') {

    # Extract the query parameters
    if ($http_method eq 'get') {
      my ($query) = $request->uri() =~ /\?(.*)$/mxs;
      $cgi = CGI->new($query);
    } else {
      $cgi = CGI->new($request->{'_content'}); ## Nasty - should use some sort of raw_content method
    }

    #########
    # Handle DAS responses here
    #
    my ($dsn, $call) = $uri =~ m{/das1?(?:/([^/\?\#]+))(?:/([^/\?\#]+))?}mxs;
    $dsn           ||= q();
    $call          ||= q();

    # /das/foo/bar
    if ($call) {

      # /das/sources/foo OR /das/homepage/foo
      if ($dsn eq 'sources' || $dsn eq 'homepage') {

        #Ê/das/sources/foo.xsl
        if ($call =~ m/.+\.xsl/mxs) {
          $response = response_xsl($heap, $request, $call); # pretend the URL was /das/foo.xsl
        }
        # /das/sources/foo
        elsif ($dsn eq 'sources') {
          $response = response_sources($heap, $request, $call);
        }
        # /das/homepage/foo
        else {
          $response = HTTP::Response->new(200);
          $response->content_type('text/plain');
          $response->header('X-DAS-Status' => 401);
          $response->content("Bad data source (data source unknown: $dsn)\nuri=@{[$uri||q()]}, dsn=@{[$dsn||q()]}, call=@{[$call||q()]}");
        }
      }

      # /das/%dsn/%command
      elsif($config->knows($dsn)) {

        # /das/%dsn/sources
        if ($call eq 'sources') {
          $response = response_sources($heap, $request, $dsn);
        }
        # /das/%dsn/%command OR # /das/%dsn/foo.xsl
        else {
          $response = response_general($heap, $request, $dsn, $call, $cgi);
        }
      }

      # /das/foo/bar
      else {
        $response = HTTP::Response->new(200);
        $response->content_type('text/plain');
        $response->header('X-DAS-Status' => 401);
        $response->content("Bad data source (data source unknown: $dsn)\nuri=@{[$uri||q()]}, dsn=@{[$dsn||q()]}, call=@{[$call||q()]}");
      }
    }

    # /das OR /das/foo
    else {

      # /das OR /das/homepage
      if (!$dsn || $dsn eq 'homepage') {
        $response = response_homepage($heap, $request);
      }

      # /das/foo.xsl
      elsif ($dsn =~ m/.+\.xsl/mxs) {
        $response = response_xsl($heap, $request, $dsn);
      }

      # /das/sources
      elsif ($dsn eq 'sources') {
        $response = response_sources($heap, $request);
      }

      # /das/dsn
      elsif ($dsn eq 'dsn') {
        $response = response_dsn($heap, $request);
      }

      # /das/%dsn
      elsif($config->knows($dsn)) {
        $response = response_sources($heap, $request, $dsn);
      }

      # /das/foo
      else {
        $response = HTTP::Response->new(200);
        $response->content_type('text/plain');
        $response->header('X-DAS-Status' => 401);
        $response->content("Bad data source (data source unknown: $dsn)\nuri=@{[$uri||q()]}, dsn=@{[$dsn||q()]}, call=@{[$call||q()]}");
      }
    }

    $response->content_length(length $response->content);
    #########
    # Add custom X-DAS headers
    #
    $response->header('X-DAS-Version' => $config->das_version);
    $response->header('X-DAS-Server'  => $config->server_version);
    if (!$response->header('X-DAS-Status')) {
      $response->header('X-DAS-Status'  => $response->code());
    }

    if($dsn && $config->knows($dsn) && (my $adaptor = $config->adaptor($dsn))) {
      eval {
        $response->header('X-DAS-Capabilities' => $adaptor->das_capabilities()||q());
        $adaptor->cleanup();
        1;
      } or do {
        carp $EVAL_ERROR;
      };

    } else {
      $response->header('X-DAS-Capabilities' => q(dsn/1.0; sources/1.0));
    }
    #
    # Finished handling das responses
    #########

  } elsif ($http_method eq 'options') {
    # For W3C Access Control preflight requests
    $response = HTTP::Response->new(200);
    $response->header('Access-Control-Allow-Methods' => 'GET, POST, OPTIONS');
    $response->header('Access-Control-Allow-Headers' => 'X-DAS-Version', 'X-DAS-Client');
    $response->header('Access-Control-Max-Age',      => '2592000'); # preflight can be cached for 30 days
  } else {
    # For methods other than POST, GET and OPTIONS
    $response = HTTP::Response->new(501); # "Not Implemented"
  }

  # Add Access Control headers (for cross site requests):
  $response->header('Access-Control-Allow-Origin' => q(*));
  $response->header('Access-Control-Expose-Headers' => 'X-DAS-Version, X-DAS-Server, X-DAS-Status, X-DAS-Capabilities');
  $response->header('Access-Control-Allow-Credentials' => 'true');

  #########
  # Generate access log
  #
  my $logline = $heap->{'self'}->{'logformat'};
  $logline    =~ s/%i/inet_ntoa($heap->{peer_addr})/emxs;                              # remote ip
  $logline    =~ s/%h/gethostbyaddr($heap->{peer_addr}, AF_INET);/emxs;                # remote hostname
  $logline    =~ s/%t/strftime '%Y-%m-%dT%H:%M:%S', localtime/emxs;                    # datetime yyyy-mm-ddThh:mm:ss
  $logline    =~ s/%r/$uri/mxs;                                                        # request uri
  $logline    =~ s/%>?s/@{[$response->code(), $response->header('X-DAS-Status')]}/mxs; # status

  if($heap->{'method'} &&
     $heap->{'method'} eq 'cgi') {
    __PACKAGE__->log($logline);

  } else {
    print $logline, "\n" or croak $OS_ERROR;
  }

  return $response;
}

# Does keyword substitution for response URLs
sub _substitute {
  my ($heap, $text, $dsn) = @_;

  my $config  = $heap->{'self'}->{'config'};
  my $subst   = {
     'host'     => $config->response_hostname(),
     'port'     => $config->response_port()     || q(),
     'protocol' => $config->response_protocol() || 'http',
     'baseuri'  => $config->response_baseuri()  || q(),
     'dsn'      => $dsn || q(),
  };
  $subst->{'serverurl'} = sprintf '%s://%s%s%s/das',
                               $subst->{'protocol'},
                               $subst->{'host'},
                               $subst->{'port'} ? ":$subst->{'port'}" : q(),
                               $subst->{'baseuri'};
  $subst->{'sourceurl'} = $subst->{'dsn'} ? $subst->{'serverurl'} . q(/) . $subst->{'dsn'} : $subst->{'serverurl'};
  $text =~ s/\%([a-z]+)/$subst->{$1}/smgxis;
  return $text;
}

# Sets content type from a list of possible types, according to the client's preference
sub _content_type {
  my ($request, @offered) = @_;

  my @wanted = split /\s*,\s*/mxs, $request->header('Accept') || q();
  my %wanted = ();
  for my $wanted (@wanted) {
    my ($k,$v) = split /\s*;\s*/mxs, $wanted;
    if ($v) {
      ($v) = $v =~ /q\s*=\s*([\d\.]+)/mxs;
    }
    $v ||= 1;
    $wanted{$v} ||= [];
    push @{ $wanted{$v} }, $k;
  }

  # Choose a content type based on:
  # 1. The client's preference indicated by score
  # 2. For equally scored preferences, use the server's preference
  for my $score (sort { $b <=> $a } keys %wanted) {
    for my $offered (@offered) {
      if ( scalar grep { lc $_ eq lc $offered } @{ $wanted{$score} }) {
        return $offered;
      }
    }
  }

  return $offered[0]; # The server isn't offering anything the client accepts, so just return what we want
}

### The client handler received an error.  Stop the ReadWrite wheel,
### which also closes the socket.

sub client_got_error {
  my @args = @_;
  my ( $heap, $operation, $errnum, $errstr ) = @args[ HEAP, ARG0, ARG1, ARG2 ];
  DEBUG and
    carp( "Client handler $PID/", $args[SESSION]->ID,
          " got $operation error $errnum: $errstr\n",
          "Client handler $PID/", $args[SESSION]->ID, " is shutting down.\n"
        );
  return delete $heap->{client};
}

### The client handler has flushed its response to the socket.  We're
### done with the client connection, so stop the ReadWrite wheel.

sub client_flushed_request {
  my @args = @_;
  my $heap = $args[HEAP];
  DEBUG and
    carp( "Client handler $PID/", $args[SESSION]->ID,
          " flushed its response.\n",
          "Client handler $PID/", $args[SESSION]->ID, " is shutting down.\n"
        );
  return delete $heap->{client};
}

### We're done.

sub make_pidfile {
  my ($self, $pidfile) = @_;
  my ($spidfile)       = $pidfile =~ /([a-zA-Z0-9\.\/_\-]+)/mxs;
  __PACKAGE__->log(qq(Writing pidfile $spidfile));
  $self->{'pidfile'} = $pidfile;
  open my $fh, '>', $spidfile or croak "Cannot create pid file: $ERRNO\n";
  print {$fh} "$PID\n" or croak $OS_ERROR;
  close $fh or carp "Error closing pid file: $ERRNO";
  return $PID;
}

sub remove_pidfile {
  my ($self)     = @_;
  my $spidfile    = $self->{'pidfile'};
  if($spidfile && -f $spidfile) {
    unlink $spidfile;
    DEBUG and carp 'Removed pidfile';
  }
  return;
}

sub log { ## no critic
  my ($self, @args) = @_;
  print {*STDERR} (strftime '[%Y-%m-%d %H:%M:%S] ', localtime), @args, "\n" or croak $OS_ERROR;
  return;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer

=head1 VERSION

$LastChangedRevision: 687 $

=head1 SYNOPSIS

  eg/proserver -help

=head1 DESCRIPTION

  ProServer is a server implementation of the DAS protocol.
  http://biodas.org/

  ProServer is based on example preforking POEserver at
  http://poe.perl.org/?POE_Cookbook/Web_Server_With_Forking

=head1 DIAGNOSTICS

  To run in non-pre-forking, debug mode:
  eg/proserver -debug -x

  Otherwise stdout logs to proserver-hostname.log and stderr to proserver-hostname.err

=head1 CONFIGURATION AND ENVIRONMENT

  See eg/proserver.ini

=head1 SUBROUTINES/METHODS

=head2 run

=head2 DEBUG

=head2 server_spawn

=head2 server_start

=head2 server_stop

=head2 server_got_error

=head2 server_do_fork

=head2 server_got_sig_hup

=head2 server_got_sig_int

=head2 server_got_sig_chld

=head2 server_got_connection

=head2 client_start

=head2 client_stop

=head2 client_got_request

=head2 response_xsl

=head2 response_general

=head2 response_dsn

=head2 response_sources

=head2 response_homepage

=head2 build_das_response

=head2 client_got_error

=head2 client_flushed_request

=head2 make_pidfile

=head2 remove_pidfile

=head2 log

=head1 DEPENDENCIES

Bio::Das::ProServer::Config
CGI :cgi
HTTP::Request
HTTP::Response
Compress::Zlib
Getopt::Long
POE
POE::Filter::HTTPD
POE::Wheel::ReadWrite
POE::Wheel::SocketFactory
POSIX setsid strftime
File::Spec
Sys::Hostname
Bio::Das::ProServer::SourceAdaptor
Bio::Das::ProServer::SourceHydra
Socket
English
Carp

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
