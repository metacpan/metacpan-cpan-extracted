# -*- mode: cperl; eval: (follow-mode); -*-
#

package App::Regather;

use strict;
use warnings;
use diagnostics;

use Carp;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case gnu_getopt auto_version);
use IPC::Open2;
use List::Util   qw(uniqstr);

use Net::LDAP;
use Net::LDAP::LDIF;
use Net::LDAP::Constant qw( 
			    LDAP_CONNECT_ERROR
			    LDAP_LOCAL_ERROR
			    LDAP_OPERATIONS_ERROR
			    LDAP_SUCCESS
			    LDAP_SYNC_ADD
			    LDAP_SYNC_DELETE
			    LDAP_SYNC_MODIFY
			    LDAP_SYNC_PRESENT
			    LDAP_SYNC_REFRESH_AND_PERSIST
			    LDAP_SYNC_REFRESH_ONLY
			 );
use Net::LDAP::Control::SyncRequest;
use Net::LDAP::Util qw(generalizedTime_to_time);

use POSIX;
use Pod::Usage   qw(pod2usage);
use Sys::Syslog  qw(:standard :macros);
use Template;

use App::Regather::Config;
use App::Regather::Logg;
use App::Regather::Plugin;

use constant SYNST => [ qw( LDAP_SYNC_PRESENT LDAP_SYNC_ADD LDAP_SYNC_MODIFY LDAP_SYNC_DELETE ) ];

# my @DAEMONARGS = ($0, @ARGV);
our $VERSION   = '0.84.00';

sub new {
  my $class = shift;
  my $self =
    bless {
	   _progname => fileparse($0),
	   _daemonargs => [$0, @ARGV],
	   _opt   => {
		      ch          => undef,
		      cli         => undef,
		      colors      => 0,
		      config      => '/usr/local/etc/regather.conf',
		      fg          => 0,
		      force       => 0,
		      plugin_list => 0,
		      strict      => 0,
		      ts_fmt      => "%a %F %T %Z (%z)",
		      v           => 0,
		     }
	   }, $class;

  GetOptions(
	     'f|foreground' => \$self->{_opt}{fg},
	     'F|force'      => \$self->{_opt}{force},
	     'c|config=s'   => \$self->{_opt}{config},
	     'colors'       => \$self->{_opt}{colors},
	     'C|cli=s%'     => \$self->{_opt}{cli},
	     'S|strict'     => \$self->{_opt}{strict},
	     'config-help'  => \$self->{_opt}{ch},
	     'plugin-list'  => \$self->{_opt}{plugin_list},
	     'v+'           => \$self->{_opt}{v},
	     'h'            => sub { pod2usage(-exitval => 0, -verbose => 2); exit 0 },
	    );

  $self->{_opt}{l} = new
    App::Regather::Logg( prognam    => $self->{_progname},
			 foreground => $self->{_opt}{fg},
			 colors     => $self->{_opt}{colors} );

  if ( $self->{_opt}{plugin_list} ) {
    App::Regather::Plugin->new( 'list' )->run;
    exit 0;
  }

  $self->{_opt}{cf} = new
    App::Regather::Config ( filename => $self->{_opt}{config},
			    logger   => $self->{_opt}{l},
			    cli      => $self->{_opt}{cli},
			    verbose  => $self->{_opt}{v} );

  my $cf_mode = (stat($self->{_opt}{config}))[2] & 0777;
  my $fm_msg;
  if ( $cf_mode & 002 || $cf_mode & 006 ) {
    $fm_msg = 'world';
  } elsif ( $cf_mode & 020 || $cf_mode & 060) {
    $fm_msg = 'group';
  }
  if ( defined $fm_msg ) {
    $self->{_opt}{l}->cc( pr => 'err', fm => 'config file is accessible by ' . $fm_msg);
    pod2usage(-exitval => 2, -sections => [ qw(USAGE) ]);
    exit 1;
  }

  $self->{_opt}{last_forever} = 1;

  # !!! TO CORRECT
  if ( ! defined $self->{_opt}{cf} ) {
    $self->l->cc( pr => 'err', fm => "do fix config file ..." );
    pod2usage(-exitval => 2, -sections => [ qw(USAGE) ]);
    exit 1;
  }

  if ( $self->{_opt}{ch} ) {
    $self->{_opt}{cf}->config_help;
    exit 1;
  }

  return $self;
}

sub progname { shift->{_progname} }

sub progargs { return join(' ', @{shift->{_daemonargs}}); }

sub cf { shift->{_opt}{cf} }

sub l { shift->{_opt}{l} }

sub o {
  my ($self,$opt) = @_;
  croak "unknown/undefined variable"
    if ! exists $self->{_opt}{$opt};
  return $self->{_opt}{$opt};
}

sub run {
  my $self = shift;

  $self->l->cc( pr => 'info', fm => "%s:%s: options provided from CLI:\n%s", ls => [ __FILE__,__LINE__, $self->o('cli') ] )
    if defined $self->o('cli') && keys( %{$self->o('cli')} ) && $self->o('v') > 1;

  $self->l->set_m( $self->cf->getnode('log')->as_hash );
  $self->l->set( notify       => [ $self->cf->get('core', 'notify') ] );
  $self->l->set( notify_email => [ $self->cf->get('core', 'notify_email') ] );

  $self->l->cc( pr => 'info', fm => "%s: Dry Run is set on, no file is to be changed\n" )
    if $self->cf->get(qw(core dryrun));
  $self->l->cc( pr => 'info', fm => "%s:%s: Config::Parse object as hash:\n%s",
	        ls => [ __FILE__,__LINE__, $self->cf->as_hash ] ) if $self->o('v') > 3;
  $self->l->cc( pr => 'info', fm => "%s:%s: %s",
		ls => [ __FILE__,__LINE__, $self->progargs ] );
  $self->l->cc( pr => 'info', fm => "%s:%s: %s v.%s is starting ...",
		ls => [ __FILE__,__LINE__, $self->progname, $VERSION, ] );

  @{$self->{_opt}{svc}} = grep { $self->cf->get('service', $_, 'skip') != 1 } $self->cf->names_of('service');

  $self->daemonize if ! $self->o('fg');

  our $s;
  my  $tmp;
  my  $cfgattrs = [];
  my  $mesg;
  my  @svc_map;

  foreach my $i ( @{$self->{_opt}{svc}} ) {
    foreach ( qw( s m ) ) {
      if ( $self->cf->is_section('service', $i, 'map', $_) ) {
	@svc_map = values( %{ $self->cf->getnode('service', $i, 'map', $_)->as_hash } );
	# push @svc_map, $self->cf->getnode('service', $i, 'ctrl_attr');
	$cfgattrs = [ @{$cfgattrs}, @svc_map, @{$self->cf->get('service', $i, 'ctrl_attr')} ];
      } else {
	@svc_map = ();
      }
    }

    push @{$cfgattrs}, '*'
      if $self->cf->get('service', $i, 'all_attr') != 0;

    $self->l->cc( pr => 'warning', ls => [ __FILE__,__LINE__, $i, ],
		  fm => "%s:%s: no LDAP attribute to process is mapped for service `%s`" )
      if $self->cf->get('service', $i, 'all_attr') == 0 && scalar @svc_map == 0;

  }

  @{$tmp} = sort @{[ @{$cfgattrs}, qw( associatedDomain
				       authorizedService
				       description
				       entryUUID
				       entryCSN
				       createTimestamp
				       creatorsName
				       modifiersName
				       modifyTimestamp ) ]};
  @{$cfgattrs} = uniqstr @{$tmp};

  #
  ## -=== MAIN LOOP =====================================================-
  #

  my $ldap_opt      = $self->cf->getnode(qw(ldap opt))->as_hash;
  my $uri           = delete $ldap_opt->{uri};
  while ( $self->o('last_forever') ) {
    if ( $self->cf->is_set(qw(core altroot)) ) {
      chdir($self->cf->get(qw(core altroot))) || do {
	$self->l->cc( pr => 'err', fm => "%s:%s: main: unable to chdir to %s",
		  ls => [ __FILE__,__LINE__, $self->cf->get(qw(core altroot)) ] );
	exit 1;
      };
    }

    $self->{_opt}{ldap} =
      Net::LDAP->new( $uri, @{[ map { $_ => $ldap_opt->{$_} } %$ldap_opt ]} )
	|| do {
	  $self->l->cc( pr => 'err', fm => "%s:%s: Unable to connect to %s; error: %s",
			ls => [ __FILE__,__LINE__, $uri, $! ] );
	  if ( $self->o('strict') ) {
	    exit LDAP_CONNECT_ERROR;
	  } else {
	    next;
	  }
	};

    my $start_tls_options = $self->cf->getnode(qw(ldap ssl))->as_hash if $self->cf->is_section(qw(ldap ssl));
    if ( exists $start_tls_options->{ssl} && $start_tls_options->{ssl} eq 'start_tls' ) {
      delete $start_tls_options->{ssl};
      eval {
	$mesg =
	  $self->o('ldap')->start_tls( @{[ map { $_ => $start_tls_options->{$_} } %$start_tls_options ]} );
      };
      if ( $@ ) {
	$self->l->cc( pr => 'err', fm => "%s:%s: TLS negotiation failed: %s", ls => [ __FILE__,__LINE__, $! ] );
	if ( $self->o('strict') ) {
	  exit LDAP_CONNECT_ERROR;
	} else {
	  next;
	}
      } else {
	$self->l->cc( pr => 'info', fm => "%s: TLS negotiation succeeded" ) if $self->o('v') > 1;
      }
    }

    my $bind = $self->cf->getnode(qw(ldap bnd))->as_hash if $self->cf->is_section(qw(ldap bnd));
    if ( ref($bind) eq 'HASH' ) {
      if ( exists $bind->{dn} ) {
	my @bind_options;
	push @bind_options, delete $bind->{dn};
	while ( my($k, $v) = each %{$bind} ) {
	  push @bind_options, $k => $v;
	}
	$mesg = $self->o('ldap')->bind( @bind_options );
	if ( $mesg->code ) {
	  ####### !!!!!!! TODO: to implement exponential delay on error sending to awoid log file/notify
	  ####### !!!!!!! queue overflow
	  $self->l->cc( pr => 'err', fm => "%s:%s: bind error: %s",
			ls => [ __FILE__,__LINE__, $mesg->error ] );
	  if ( $self->o('strict') ) {
	    exit $mesg->code;
	  } else {
	    next;
	  }
	}
      }
    }

    $self->{_opt}{req} =
      Net::LDAP::Control::SyncRequest->new( mode     => LDAP_SYNC_REFRESH_AND_PERSIST,
					    critical => 1,
					    cookie   => undef, );

    $mesg = $self->o('ldap')->search( base     => $self->cf->get(qw(ldap srch base)),
				      scope    => $self->cf->get(qw(ldap srch scope)),
				      control  => [ $self->o('req') ],
				      callback => sub {$self->ldap_search_callback(@_)},
				      filter   => $self->cf->get(qw(ldap srch filter)),
				      attrs    => $cfgattrs,
				      sizelimit=> $self->cf->get(qw(ldap srch sizelimit)),
				      timelimit=> $self->cf->get(qw(ldap srch timelimit)),
				    );
    if ( $mesg->code ) {
      $self->l->cc( pr => 'err',
		    fm => "%s:%s: LDAP search ERROR...\n% 13s%s\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
		    ls => [ __FILE__,__LINE__,
			    'base: ',   $self->cf->get(qw(ldap srch base)),
			    'scope: ',  $self->cf->get(qw(ldap srch scope)),
			    'filter: ', $self->cf->get(qw(ldap srch filter)),
			    'attrs: ',  join("\n", @{$cfgattrs}) ] );
      $self->l->cc_ldap_err( mesg => $mesg );
      exit $mesg->code if $self->o('strict');
    } else {
      $self->l->cc( pr => 'info',
		    fm => "%s:%s: LDAP search:\n% 13s%s\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
		    ls => [ __FILE__,__LINE__,
			    'base: ',   $self->cf->get(qw(ldap srch base)),
			    'scope: ',  $self->cf->get(qw(ldap srch scope)),
			    'filter: ', $self->cf->get(qw(ldap srch filter)),
			    'attrs: ',  join("\n", @{$cfgattrs}) ] ) if $self->o('v') > 2;
    }
  }

  $mesg = $self->o('ldap')->unbind;
  if ( $mesg->code ) {
    $self->l->cc_ldap_err( mesg => $mesg );
    exit $mesg->code;
  }

  closelog();

}

#
## ===================================================================
#

sub daemonize {
  my $self = shift;

  my ( $pid, $fh, $pp, $orphaned_pid_mtime );
  if ( -e $self->cf->get(qw(core pid_file)) ) {
    open( $fh, "<", $self->cf->get(qw(core pid_file))) || do {
      die "Can't open $self->cf->get(qw(core pid_file)) for reading: $!";
      exit 1;
    };
    $pid = <$fh>;
    close($fh) || do {
      print "close $self->cf->get(qw(core pid_file)) (opened for reading) failed: $!\n\n";
      exit 1;
    };

    if ( kill(0, $pid) ) {
      print "Doing nothing\npidfile $self->cf->get(qw(core pid_file)) of the proces with pid $pid, exists and the very process is alive\n\n";
      exit 1;
    }

    $orphaned_pid_mtime = strftime( $self->o('ts_fmt'), localtime( (stat( $self->cf->get(qw(core pid_file)) ))[9] ));
    if ( unlink $self->cf->get(qw(core pid_file)) ) {
      $self->l->cc( pr => 'debug', fm => "%s:%s: orphaned %s was removed",
		ls => [ __FILE__,__LINE__, $self->cf->get(qw(core pid_file)) ] )
	if $self->o('v') > 0;
    } else {
      $self->l->cc( pr => 'err', fm => "%s:%s: orphaned %s (mtime: %s) was not removed: %s",
		ls => [ __FILE__,__LINE__, $self->cf->get(qw(core pid_file)), $orphaned_pid_mtime, $! ] );
      exit 2;
    }

    undef $pid;
  }

  $pid = fork();
  die "fork went wrong: $!\n\n" unless defined $pid;
  exit(0) if $pid != 0;

  setsid || do { print "setsid went wrong: $!\n\n"; exit 1; };

  open( $pp, ">", $self->cf->get(qw(core pid_file))) || do {
    print "Can't open $self->cf->get(qw(core pid_file)) for writing: $!"; exit 1; };
  print $pp "$$";
  close( $pp ) || do {
    print "close $self->cf->get(qw(core pid_file)) (opened for writing), failed: $!\n\n"; exit 1; };

  if ( $self->o('v') > 1 ) {
    open (STDIN,  "</dev/null") || do { print "Can't redirect /dev/null to STDIN\n\n";  exit 1; };
    open (STDOUT, ">/dev/null") || do { print "Can't redirect STDOUT to /dev/null\n\n"; exit 1; };
    open (STDERR, ">&STDOUT")   || do { print "Can't redirect STDERR to STDOUT\n\n";    exit 1; };
  }

  $SIG{HUP}  =
    sub { my $sig = @_;
	  $self->l->cc( pr => 'warning', fm => "%s:%s: SIG %s received, restarting", ls => [ __FILE__,__LINE__, $sig ] );
	  exec('perl', @{$self->o('_daemonargs')}); };
  $SIG{INT} = $SIG{QUIT} = $SIG{ABRT} = $SIG{TERM} =
    sub { my $sig = @_;
	  $self->l->cc( pr => 'warning', fm => "%s:%s:  SIG %s received, exiting", ls => [ __FILE__,__LINE__, $sig ] );
	  $self->{_opt}{last_forever} = 0;
	};
  $SIG{PIPE} = 'ignore';
  $SIG{USR1} =
    sub { my $sig = @_;
	  $self->l->cc( pr => 'warning', fm => "%s:%s: SIG %s received, doing nothing" ), ls => [ __FILE__,__LINE__, $sig ] };

  if ( $self->cf->is_set(qw(core uid)) && $self->cf->is_set(qw(core gid)) ) {
    setgid ( $self->cf->get(qw(core gid_number)) ) || do { print "setgid went wrong: $!\n\n"; exit 1; };
    setuid ( $self->cf->get(qw(core uid_number)) ) || do { print "setuid went wrong: $!\n\n"; exit 1; };
  }

  $self->l->cc( pr => 'info', fm => "%s:%s: %s v.%s is started.", ls => [ __FILE__,__LINE__, $self->progname, $VERSION ] );
}

sub ldap_search_callback {
  my ( $self, $msg, $obj ) = @_;


  my @controls = $msg->control;
  my $syncstate = scalar @controls ? $controls[0] : undef;

  my ( $s, $st, $mesg, $entry, @entries, $ldif, $map,
       $out_file_pfx_old,
       $tmp_debug_msg,
       $rdn, $rdn_old, $rdn_re,
       $pp, $chin, $chou, $chst, $cher, $email, $email_body );

  ######## !! not needed ?
  my $out_file_old;
  
  $self->l->cc( pr => 'debug', fm => "%s:%s: syncstate: %s", ls => [ __FILE__,__LINE__, $syncstate ] )
    if $self->o('v') > 5;
  $self->l->cc( pr => 'debug', fm => "%s:%s: object: %s", ls => [ __FILE__,__LINE__, $obj ] ) if $self->o('v') > 5;

  if ( defined $obj && $obj->isa('Net::LDAP::Entry') ) {
    $rdn = ( split(/=/, ( split(/,/, $obj->dn) )[0]) )[0];
    if ( defined $syncstate && $syncstate->isa('Net::LDAP::Control::SyncState') ) {
      $self->l->cc( pr => 'debug', fm => "%s:%s: SYNCSTATE:\n%s:", ls => [ __FILE__,__LINE__, $syncstate ] )
	if $self->o('v') > 4;
      $st = $syncstate->state;
      my %reqmod;
      $self->l->cc( fm => "%s:%s: received control %s: dn: %s", ls => [ __FILE__,__LINE__, SYNST->[$st], $obj->dn ] );

      #######################################################################
      ####### --- PRELIMINARY STUFF ----------------------------->>>>>>>>> 0
      #######################################################################

      ### LDAP_SYNC_DELETE arrives for both cases, object deletetion and attribute
      ### deletion and in both cases Net::LDAP::Entry obj, provided contains only DN,
      ### so, we need to "re-construct" it for further processing
      if ( $st == LDAP_SYNC_DELETE ) {
	$mesg = $self->o('ldap')->search( base     => $self->cf->get(qw(ldap srch log_base)),
			       scope    => 'sub',
			       sizelimit=> $self->cf->get(qw(ldap srch sizelimit)),
			       timelimit=> $self->cf->get(qw(ldap srch timelimit)),
			       filter   => '(reqDN=' . $obj->dn . ')', );
	if ( $mesg->code ) {
	  $self->l->cc( pr => 'err', nt => 1,
		    fm => "%s:%s: LDAP accesslog search on %s, error:\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
		    ls => [ __FILE__,__LINE__, SYNST->[$st],
			    'base: ',   $self->cf->get(qw(ldap srch log_base)),
			    'scope: ',  'sub',
			    'filter: ', '(reqDN=' . $obj->dn . ')' ] );
	  $self->l->cc_ldap_err( mesg => $mesg );
	  # exit $mesg->code; # !!! NEED TO DECIDE WHAT TO DO
	} else {
	  if ( $mesg->count == 0 ) {
	    $self->l->cc( pr => 'err', nt => 1,
			  fm => "%s:%s: LDAP accesslog search on %s, returned no result:\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
			  ls => [ __FILE__,__LINE__, SYNST->[$st],
				  'base: ',   $self->cf->get(qw(ldap srch log_base)),
				  'scope: ',  'sub',
				  'filter: ', '(reqDN=' . $obj->dn . ')' ] );
	    return;
	  } else {
	    $entry = pop @{[$mesg->sorted]};
	  }

	  if ( defined $entry && ! $entry->isa('Net::LDAP::Entry') ) {
	    $self->l->cc( pr => 'err', nt => 1,
		      fm => "%s:%s: LDAP accesslog search on %s, returned no result:\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
		      ls => [ __FILE__,__LINE__, SYNST->[$st],
			      'base: ',   $self->cf->get(qw(ldap srch log_base)),
			      'scope: ',  'sub',
			      'filter: ', '(reqDN=' . $obj->dn . ')' ] );
	    return;
	  } elsif ( defined $entry && $entry->get_value('reqType') eq 'delete' ) {
	    my $reqold = 'dn: ' . $obj->dn;
	    foreach ( @{$entry->get_value('reqOld', asref => 1)} ) {
	      s/^(.*;binary:) .*$/$1: c3R1Yg==/agis;
	      $reqold .= "\n" . $_;
	    }
	    my ( $file, @err );
	    open( $file, "<", \$reqold) ||
	      $self->l->cc( pr => 'err',
			fm => "%s:%s: Cannot open data from variable to read ldif: %s",
			ls => [ __FILE__,__LINE__, $! ] );
	    $ldif = Net::LDAP::LDIF->new( $file, "r", onerror => 'warn' );
	    while ( not $ldif->eof ) {
	      $entry = $ldif->read_entry;
	      $self->l->cc( pr => 'err', fm => "%s:%s: Reading LDIF error: %s",
			ls => [ __FILE__,__LINE__, $ldif->error ] ) if $ldif->error;
	    }
	    $obj = $entry;
	    $ldif->done;
	  } elsif ( defined $entry && $entry->get_value('reqType') eq 'modify' ) {
	    ### here we re-assemble $obj to have all attributes before deletion and since
	    ### after that it'll has ctrl_attr but reqType=delete, it'll go to $st == LDAP_SYNC_DELETE
	    %reqmod = map  { substr($_, 0, -2) => 1 } grep { /^(.*):-$/g }
	      @{$entry->get_value('reqMod', asref => 1)};

	    $mesg = $self->o('ldap')->search( base   => $obj->dn,
				   scope  => 'base',
				   filter => '(objectClass=*)', );
	    if ( $mesg->code ) {
	      $self->l->cc( pr => 'err', nt => 1,
			fm => "%s:%s: LDAP search %s %s error:\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
			ls => [ __FILE__,__LINE__, SYNST->[$st], 'reqType=modify',
				'base: ',     $self->cf->get(qw(ldap srch log_base)),
				'scope: ',    'sub',
				'filter: ',   '(reqDN=' . $obj->dn . ')' ] );
	      $self->l->cc_ldap_err( mesg => $mesg );
	      # exit $mesg->code; # !!! NEED TO DECIDE WHAT TO DO
	    } else {
	      $obj = $mesg->entry(0);
	      $obj->add( map { $_ => $reqmod{$_} } keys %reqmod );
	      # $obj->add( $_ => $reqmod{$_} ) foreach ( keys %reqmod );
	    }
	    $self->l->cc( pr => 'debug', fm => "%s:%s: %s reqType=modify reqMod: %s",
		      ls => [ __FILE__,__LINE__, SYNST->[$st], \%reqmod ] )	if $self->o('v') > 3;
	  } else {
	    $self->l->cc( pr => 'err', nt => 1,
		      fm => "%s:%s: LDAP accesslog search on %s, returned an object but it's something wrong with it:\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
		      ls => [ __FILE__,__LINE__, SYNST->[$st],
			      'base: ',   $self->cf->get(qw(ldap srch log_base)),
			      'scope: ',  'sub',
			      'filter: ', '(reqDN=' . $obj->dn . ')' ] );
	    return;
	  }
	}
      } elsif ( $st == LDAP_SYNC_MODIFY ) {
	$mesg = $self->o('ldap')->search( base     => $self->cf->get(qw(ldap srch log_base)),
			       scope    => 'sub',
			       sizelimit=> $self->cf->get(qw(ldap srch sizelimit)),
			       timelimit=> $self->cf->get(qw(ldap srch timelimit)),
			       filter   => '(reqDN=' . $obj->dn . ')', );
	if ( $mesg->code ) {
	  $self->l->cc( pr => 'err', nt => 1,
		    fm => "%s:%s: LDAP accesslog search on %s, error:\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
		    ls => [ __FILE__,__LINE__, SYNST->[$st], nt => 1,
			    'base: ',   $self->cf->get(qw(ldap srch log_base)),
			    'scope: ',  'sub',
			    'filter: ', '(reqDN=' . $obj->dn . ')' ] );
	  $self->l->cc_ldap_err( mesg => $mesg );
	} else {
	  if ( $mesg->count > 0 ) {
	    ### modified object has accesslog records when it was add/modify/delete
	    ### before, as well as ModRDN ... so, we need to be sure, there is no accesslog
	    ### object with reqNewRDN=<$obj->dn RDN> close to the processing time of this $obj

	    ### NEED TO BE FINISHED

	  } elsif ( $mesg->count == 0 ) {
	    ### modified object has no accesslog records when it was ModRDN-ed so, we search
	    ### for accesslog object with reqNewRDN=<$obj->dn RDN> to know old object RDN to use
	    ### it further for $out_file
	    $mesg = $self->o('ldap')->search( base     => $self->cf->get(qw(ldap srch log_base)),
				   scope    => 'sub',
				   sizelimit=> $self->cf->get(qw(ldap srch sizelimit)),
				   timelimit=> $self->cf->get(qw(ldap srch timelimit)),
				   filter   => '(reqNewRDN=' . (split(/,/, $obj->dn))[0] . ')', );
	    if ( $mesg->code ) {
	      $self->l->cc( pr => 'err', nt => 1,
			fm => "%s:%s: LDAP accesslog search on %s, error:\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
			ls => [ __FILE__,__LINE__, SYNST->[$st],
				'base: ',   $self->cf->get(qw(ldap srch log_base)),
				'scope: ',  'sub',
				'filter: ', '(reqNewRDN=' . (split(/,/, $obj->dn))[0] . ')' ] );
	      $self->l->cc_ldap_err( mesg => $mesg );
	      # exit $mesg->code; # !!! NEED TO DECIDE WHAT TO DO
	    } else {
	      ### here we pick last reqNewRDN entry up, to find the latest UUID for entries
	      ### with same DN if the object was added/deleted/ModRDN-ed several times
	      @entries = $mesg->sorted;
	      $entry = pop @entries;
	      if ( defined $entry ) {
		$rdn_re = qr/^$rdn: .*$/;
		###### !!! NEED FIX
		### slapd.log-20210510-regather-fails-on-rdn
		###
		### here we're searching master db log, and the record is absent there, while
		### it is still present (have no idea why) in local db log ...
		###
		### Can't use an undefined value as an ARRAY reference at /usr/local/lib/perl5/site_perl/App/Regather.pm line 546.
		### BEGIN failed--compilation aborted at /usr/local/bin/regather line 10 (#1)
		###     (F) A value used as either a hard reference or a symbolic reference must
		###     be a defined value.  This helps to delurk some insidious errors.
		### Uncaught exception from user code:
		###         Can't use an undefined value as an ARRAY reference at /usr/local/lib/perl5/site_perl/App/Regather.pm line 546.
		###         BEGIN failed--compilation aborted at /usr/local/bin/regather line 10.
		###### !!! NEED FIX
		if ( $entry->exists('reqOld') ) {
		  foreach ( @{$entry->get_value('reqOld', asref => 1)} ) {
		    $rdn_old = (split(/: /, $_))[1] if /$rdn_re/;
		  }
		}
		### now we reconstruct original object
		$mesg = $self->o('ldap')->search( base     => $self->cf->get(qw(ldap srch log_base)),
				       scope    => 'sub',
				       sizelimit=> $self->cf->get(qw(ldap srch sizelimit)),
				       timelimit=> $self->cf->get(qw(ldap srch timelimit)),
				       filter   => sprintf("(reqEntryUUID=%s)",
							   $entry->get_value('reqEntryUUID')) );
		if ( $mesg->code ) {
		  $self->l->cc( pr => 'err', nt => 1,
			    fm => "%s:%s: LDAP accesslog search on %s, error:\n% 13s%s\n% 13s%s\n% 13s%s\n\n",
			    ls => [ __FILE__,__LINE__, SYNST->[$st],
				    'base: ',   $self->cf->get(qw(ldap srch log_base)),
				    'scope: ',  'sub',
				    'filter: ', sprintf("(reqEntryUUID=%s)",
							$entry->get_value('reqEntryUUID') ) ] );
		  $self->l->cc_ldap_err( mesg => $mesg );
		  # exit $mesg->code; # !!! NEED TO DECIDE WHAT TO DO
		} else {
		  @entries = $mesg->sorted;
		  if ( $entries[0]->get_value('reqType') eq 'add' ) {
		    ### here we re-assemble $obj to have all attributes on its creation except RDN,
		    ### which we'll set from next to the last element and since after that it'll has
		    ### ctrl_attr but reqType=add, it'll go to $st == LDAP_SYNC_DELETE
		    $obj->add( map { /^(.*):\+ (.*)$/g } @{$entry->get_value('reqMod', asref => 1)} );
		    $obj->replace( $rdn => $entries[scalar(@entries) - 2]->get_value($rdn) );
		  } else {
		    $self->l->cc( pr => 'err', nt => 1,
			      fm => "%s:%s: %s object (before ModRDN) to delete not found! accesslog reqType=add object not found, object reqEntryUUID=%s should be processed manually",
			      ls => [ __FILE__,__LINE__, SYNST->[$st], $entry->get_value('reqEntryUUID') ] );
		  }
		}
	      } else {
		$self->l->cc( pr => 'err', nt => 1, ls => [ __FILE__,__LINE__, SYNST->[$st] ],
			  fm => "%s:%s: LDAP accesslog search on %s object returned no result\n\n" );
	      }
	    }
	  }
	}
      }

      ### picking up a service, the $obj relates to
      my $is_ctrl_attr;
	my $ctrl_srv_re;
	my $s;
      foreach ( @{$self->{_opt}{svc}} ) {
	$is_ctrl_attr = 0;
	foreach my $ctrl_attr ( @{$self->cf->get('service', $_, 'ctrl_attr')} ) {
	  if ( $obj->exists( $ctrl_attr ) ) {
	    $is_ctrl_attr++;
	  } else {
	    $is_ctrl_attr--;
	  }
	}
	$ctrl_srv_re = $self->cf->get('service', $_, 'ctrl_srv_re');
	if ( $is_ctrl_attr > 0 && $obj->dn =~ qr/$ctrl_srv_re/ &&
	     $is_ctrl_attr == scalar( @{$self->cf->get('service', $_, 'ctrl_attr')} ) ) {
	  $s = $_;
	}
      }

      if ( ! defined $s ) {
	$self->l->cc( pr => 'warning', ls => [ __FILE__,__LINE__, $obj->dn, SYNST->[$st] ],
		  fm => "%s:%s: dn: %s is not configured to be processed on control: %s" )
	  if $self->o('v') > 2;
	return;
      }

      #######################################################################
      ####### --------------------------------------------------->>>>>>>>> 1
      #######################################################################
      if ( $st == LDAP_SYNC_ADD || $st == LDAP_SYNC_MODIFY ) {

	# App::Regather::Plugin->new( 'args', { log    => $self->log,
	# 				 params => [ 1, 2, 3]} )->run;
	foreach my $svc ( @{$self->cf->get('service', $s, 'plugin')} ) {
	  App::Regather::Plugin->new( $svc, {
					     cf           => $self->cf,
					     force        => $self->o('force'),
					     log          => $self->l,
					     obj          => $obj,
					     out_file_old => $out_file_old,
					     prog         => sprintf("%s v.%s", $self->progname, $VERSION),
					     rdn          => $rdn,
					     s            => $s,
					     st           => $st,
					     ts_fmt       => $self->o('ts_fmt'),
					     v            => $self->o('v'),
					    } )->ldap_sync_add_modify;
	}

	#######################################################################
	####### --------------------------------------------------->>>>>>>>> 2
	#######################################################################
      } elsif ( $st == LDAP_SYNC_DELETE ) {

	foreach my $svc ( @{$self->cf->get('service', $s, 'plugin')} ) {
	  App::Regather::Plugin->new( $svc, {
					     cf           => $self->cf,
					     force        => $self->o('force'),
					     log          => $self->l,
					     obj          => $obj,
					     out_file_old => $out_file_old,
					     prog         => sprintf("%s v.%s", $self->progname, $VERSION),
					     rdn          => $rdn,
					     s            => $s,
					     st           => $st,
					     ts_fmt       => $self->o('ts_fmt'),
					     v            => $self->o('v'),
					    } )->ldap_sync_delete;
	}

      }
    } elsif ( defined $syncstate && $syncstate->isa('Net::LDAP::Control::SyncDone') ) {
      $self->l->cc( pr => 'debug', fm => "%s: Received SYNC DONE CONTROL" ) if $self->o('v') > 1;
    } elsif ( ! defined $syncstate ) {
      $self->l->cc( pr => 'warning', fm => "%s: LDAP entry without Sync State control" ) if $self->o('v') > 1;
    }

    $self->o('req')->cookie($syncstate->cookie) if $syncstate->cookie;

  } elsif ( defined $obj && $obj->isa('Net::LDAP::Intermediate') ) {
    $self->l->cc( pr => 'debug', fm => "%s:%s: Received Net::LDAP::Intermediate\n%s", ls => [ __FILE__,__LINE__, $obj ] )
      if $self->o('v') > 3;
    $self->o('req')->cookie($obj->{'asn'}->{'refreshDelete'}->{'cookie'});
  } elsif ( defined $obj && $obj->isa('Net::LDAP::Reference') ) {
    $self->l->cc( pr => 'debug', fm => "%s:%s: Received Net::LDAP::Reference\n%s", ls => [ __FILE__,__LINE__, $obj ] )
      if $self->o('v') > 3;
    return;
  } else {
    return;
  }
}

1;
