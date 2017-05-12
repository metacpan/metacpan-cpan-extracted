package Apache2::Translation;

use 5.008008;
use strict;
use warnings;
no warnings qw(uninitialized);

use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::RequestIO ();
use Apache2::ServerRec ();
use Apache2::ServerUtil ();
use Apache2::Connection ();
use Apache2::CmdParms ();
use Apache2::Directive ();
use Apache2::Module ();
use Apache2::Log ();
use Apache2::ModSSL ();
use APR::Table ();
use APR::SockAddr ();
use ModPerl::Util ();
use attributes;
use Apache2::Const -compile=>qw{:common :http
				:conn_keepalive
				:methods
				:override
				:satisfy
				:types
				:proxy
				:options
				ITERATE TAKE1 RAW_ARGS RSRC_CONF
				LOG_DEBUG};

our $VERSION = '0.34';

our ($cf,$r,$skip_uri_cut,$m2s,$need_fixup,$need_m2s, %CTX, $ctx);

our ($URI, $REAL_URI, $METHOD, $QUERY_STRING, $FILENAME, $DOCROOT,
     $HOSTNAME, $PATH_INFO, $HEADERS, $REQUEST,
     $C, $CLIENTIP, $KEEPALIVE,
     $MATCHED_URI, $MATCHED_PATH_INFO, $DEBUG, $STATE, $KEY, $RC);

BEGIN {
  package Apache2::Translation::Error;

  use strict;

  sub new {
    my $class=shift;
    bless {@_}=>$class;
  }
}

BEGIN {
  package Apache2::Translation::n;

  use strict;

  sub TIESCALAR {
    my $class=shift;
    bless {@_}=>$class;
  }

  sub STORE {
    my $I=shift;
    $r->notes->{__PACKAGE__."::".$I->{member}}=shift;
  }

  sub FETCH {
    my $I=shift;
    return $r->notes->{__PACKAGE__."::".$I->{member}};
  }
}

BEGIN {
  package Apache2::Translation::_r;

  use strict;

  sub TIESCALAR {
    my $class=shift;
    my %o=@_;
    bless eval("sub {\$r->$o{member}(\@_)}")=>$class;
  }

  sub STORE {my $I=shift; $I->(@_);}
  sub FETCH {my $I=shift; $I->();}
}

tie $URI, 'Apache2::Translation::_r', member=>'uri';
tie $REAL_URI, 'Apache2::Translation::_r', member=>'unparsed_uri';
tie $METHOD, 'Apache2::Translation::_r', member=>'method';
tie $QUERY_STRING, 'Apache2::Translation::_r', member=>'args';
tie $FILENAME, 'Apache2::Translation::_r', member=>'filename';
tie $DOCROOT, 'Apache2::Translation::_r', member=>'document_root';
tie $HOSTNAME, 'Apache2::Translation::_r', member=>'hostname';
tie $PATH_INFO, 'Apache2::Translation::_r', member=>'path_info';
tie $REQUEST, 'Apache2::Translation::_r', member=>'the_request';
tie $HEADERS, 'Apache2::Translation::_r', member=>'headers_in';

tie $C, 'Apache2::Translation::_r', member=>'connection';
tie $CLIENTIP, 'Apache2::Translation::_r', member=>'connection->remote_ip';
tie $KEEPALIVE, 'Apache2::Translation::_r', member=>'connection->keepalive';

tie $MATCHED_URI, 'Apache2::Translation::n', member=>'uri';
tie $MATCHED_PATH_INFO, 'Apache2::Translation::n', member=>'pathinfo';
tie $KEY, 'Apache2::Translation::n', member=>'key';
tie $DEBUG, 'Apache2::Translation::n', member=>'debug';


use constant {
  START      => 0,
  PREPROC    => 1,
  PROC       => 2,
  DONE       => 3,
  LOOKUPFILE => 4,

  LOOKUPFILE_URI => ':LOOKUPFILE:',
  PRE_URI        => ':PRE:',
};

my %states=
  (
   start      => START,
   preproc    => PREPROC,
   proc       => PROC,
   done       => DONE,
   lookupfile => LOOKUPFILE,
  );

my @state_names=qw/start preproc proc done lookupfile/;

my %default_shift=
  (
   &START      => &PREPROC,
   &PREPROC    => &PROC,
   &LOOKUPFILE => &PROC,
   &PROC       => &PROC,
  );

my %next_state=
  (
   &START      => &PREPROC,
   &PREPROC    => &PROC,
   &LOOKUPFILE => &PROC,
   &PROC       => &DONE,
  );

my @directives=
  (
   {
    name         => 'TranslationProvider',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::ITERATE,
    errmsg       => 'TranslationProvider Perl::Class [param1 ...]',
   },
   {
    name         => '<TranslationProvider',
    func         => __PACKAGE__.'::TranslationContainer',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::RAW_ARGS,
    errmsg       => <<'EOF',
<TranslationProvider Perl::Class>
    Param1 Value1
    Param2 Value2
    ...
</TranslationProvider>
EOF
   },
   {
    name         => 'TranslationKey',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'TranslationKey string',
   },
   {
    name         => 'TranslationEvalCache',
    req_override => Apache2::Const::RSRC_CONF,
    args_how     => Apache2::Const::TAKE1,
    errmsg       => 'TranslationEvalCache how_many',
   },
  );
Apache2::Module::add(__PACKAGE__, \@directives);

sub postconfig {
  my($conf_pool, $log_pool, $temp_pool, $s) = @_;

  my $base=Apache2::Module::get_config( __PACKAGE__, $s );
  for(; $s; $s=$s->next ) {
    my $cfg=Apache2::Module::get_config( __PACKAGE__, $s );
    if( $cfg ) {
      next if defined $cfg->{provider};
      if( ref($cfg->{provider_param}) eq 'ARRAY' ) {
	my $param=$cfg->{provider_param};
	my $class=$param->[0];
	eval "use Apache2::Translation::$class;";
	if( $@ ) {
	  warn "ERROR: Cannot use Apache2::Translation::$class: $@" if $@;
	  eval "use $class;";
	  die "ERROR: Cannot use $class: $@" if $@;
	} else {
	  $class='Apache2::Translation::'.$class;
	}
	$cfg->{provider}=$class->new( Root=>Apache2::ServerUtil::server_root,
				      @{$param}[1..$#{$param}] );
      } elsif( $cfg->{provider_param} eq 'inherit' ) {
	if( defined $base->{provider} ) {
	  $cfg->{provider}=$base->{provider};
	} else {
	  die "ERROR: Cannot inherit provider from base server.";
	}
      }
    }
  }

  return Apache2::Const::OK;
}

sub setPostConfigHandler {
  my $h=Apache2::ServerUtil->server->get_handlers('PerlPostConfigHandler')||[];
  unless( grep $_==\&postconfig, @{$h} ) {
    Apache2::ServerUtil->server->push_handlers
	('PerlPostConfigHandler'=>\&postconfig);
  }
}

sub TranslationProvider {
  my($I, $parms, @args)=@_;
  $I=Apache2::Module::get_config(__PACKAGE__, $parms->server);
  unless( $I->{provider_param} ) {
    if( @args==1 and $args[0] eq 'inherit' ) {
      $I->{provider_param}=$args[0];
      setPostConfigHandler;
      return;
    } else {
      $I->{provider_param}=[shift @args];
    }
  }
  push @{$I->{provider_param}}, map {
    my @x=split /=/, $_, 2;
    (lc( $x[0] ), $x[1]);
  } @args;
  setPostConfigHandler;
}

sub TranslationContainer {
  my($I, $parms, $rest)=@_;
  $I=Apache2::Module::get_config(__PACKAGE__, $parms->server);
  local $_;
  my @l=map {
    s/^\s*//;
    s/\s*$//;
    if( length($_) ) {
      my @x=split( /\s+/, $_, 2 );
      $x[0]=lc $x[0];
      unless( $x[1]=~s/^'(.*)'$/$1/s ) {
	$x[1]=~s/^"(.*)"$/$1/s;
	$x[1]=~s/\$\{(\w+)\}/$ENV{$1}/ge;
      }
      @x;
    } else {
      ();
    }
  } split /\n/, $parms->directive->as_string;
  $I->{provider_param}=[$rest=~/([\w:]+)/, @l];
  setPostConfigHandler;
}

sub TranslationKey {
  my($I, $parms, $arg)=@_;
  $I=Apache2::Module::get_config(__PACKAGE__, $parms->server);
  $I->{key}=$arg;
  $I->{key_def}=1;
}

sub TranslationEvalCache {
  my($I, $parms, $arg)=@_;
  $I=Apache2::Module::get_config(__PACKAGE__, $parms->server);

  if( $arg!~/^\d/ ) {
    if( tied(%{$I->{eval_cache}}) ) {
      untie(%{$I->{eval_cache}});
    }
  } else {
    my $o;
    if( $o=tied(%{$I->{eval_cache}}) ) {
      $o->max_size($arg);
    } else {
      eval "use Tie::Cache::LRU";
      die "$@" if $@;
      tie %{$I->{eval_cache}}, 'Tie::Cache::LRU', $arg;
    }
  }
  $I->{eval_cache_def}=1;
}

sub SERVER_MERGE {
  my ($base, $add)=@_;
  my %merged;

  if( exists $add->{provider_param} ) {
    $merged{provider_param}=$add->{provider_param};
  } elsif( exists $base->{provider_param} ) {
    $merged{provider_param}='inherit';
  }

  if( $add->{eval_cache_def} ) {
    $merged{eval_cache}=$add->{eval_cache};
  } else {
    $merged{eval_cache}=$base->{eval_cache};
  }

  if( $add->{key_def} ) {
    $merged{key}=$add->{key};
  } else {
    $merged{key}=$base->{key};
  }

  return bless \%merged, ref($base);
}

sub SERVER_CREATE {
  my ($class, $parms)=@_;

  return bless {
		key=>'default',
		eval_cache=>{},
	       } => $class;
}

################################################################
# here begins the real stuff
################################################################

sub handle_eval {
  my ($eval)=@_;

  my $sub=$cf->{eval_cache}->{$eval};

  unless( $sub ) {
    $sub=<<"SUB";
sub {
# line 1 "code fragment"
  $eval
}
SUB

    $sub=eval $sub;
    if( $@ ) {
      (my $e=$@)=~s/\s*\Z//;
      $r->warn( __PACKAGE__.": $eval: $e" );
      return;
    }
    $cf->{eval_cache}->{$eval}=$sub;
  }

  my @rc;
  if( wantarray ) {
    @rc=eval {$sub->();};
  } else {
    $rc[0]=eval {$sub->();};
  }
  die $@ if( ref $@ );
  if( $@ ) {
    (my $e=$@)=~s/\s*\Z//;
    $r->warn( __PACKAGE__.": $eval: $e" );
  }

  return wantarray ? @rc : $rc[0];
}

sub add_note {
  $r->notes->add(__PACKAGE__."::".$_[0], $_[1]);
}

my %action_dispatcher;
%action_dispatcher=
  (
   do=>sub {
     my ($action, $what)=@_;
     handle_eval( $what );
     return 1;
   },

   perlhandler=>sub {
     my ($action, $what)=@_;
     add_note(response=>$what);
     $r->handler('modperl')
       unless( $r->handler=~/^(?:modperl|perl-script)$/ );

     # some perl handler use $r->location to get some "base path", e.g.
     # Catalyst. The only way to set this location is this.
     #add_note(config=>$MATCHED_URI."\t".'PerlResponseHandler '.$what);
     add_note(config=>$MATCHED_URI."\tPerlResponseHandler ".__PACKAGE__.'::response');
     add_note(shortcut_maptostorage=>" ".$MATCHED_PATH_INFO);
     $need_m2s++;

     # Translation done: return OK instead of DECLINED
     $RC=Apache2::Const::OK;
     return 1;
   },

   doc=>sub {
     my ($action, $what)=@_;
     add_note(response=>$what);
     $r->handler('modperl');
     add_note(config=>$MATCHED_URI."\tPerlResponseHandler ".__PACKAGE__.'::doc');
     add_note(shortcut_maptostorage=>" ".$MATCHED_PATH_INFO);
     $need_m2s++;

     # Translation done: return OK instead of DECLINED
     $RC=Apache2::Const::OK;
     return 1;
   },

   perlscript=>sub {
     my ($action, $what)=@_;
     $r->filename( scalar handle_eval( $what ) ) unless( $what=~/^\s*$/ );
     $r->handler('perl-script');
     $r->set_handlers( PerlResponseHandler=>'ModPerl::Registry' );
     add_note(fixupconfig=>'Options ExecCGI');
     add_note(fixupconfig=>'PerlOptions +ParseHeaders');
     $need_fixup++;
     return 1;
   },

   cgiscript=>sub {
     my ($action, $what)=@_;
     $r->filename( scalar handle_eval( $what ) ) unless( $what=~/^\s*$/ );
     $r->handler('cgi-script');
     add_note(fixupconfig=>'Options +ExecCGI');
     $need_fixup++;
     return 1;
   },

   proxy=>sub {
     my ($action, $what)=@_;
     my $real_url = $r->unparsed_uri;
     my $proxyreq = 1;
     if( length $what ) {
       $real_url=handle_eval( $what );
       $proxyreq=2;		# reverse proxy
     }
     add_note(fixupproxy=>"$proxyreq\t$real_url");
     $need_fixup++;
     return 1;
   },

   file=>sub {
     my ($action, $what)=@_;
     $r->filename( scalar handle_eval( $what ) );
     return 1;
   },

   uri=>sub {
     my ($action, $what)=@_;
     $r->uri( scalar handle_eval( $what ) );
     return 1;
   },

   config=>sub {
     my ($action, $what)=@_;
     foreach my $c (handle_eval( $what )) {
       add_note(config=>(ref $c
			 ? $c->[1]."\t".$c->[0]
			 : $MATCHED_URI."\t$c"));
     }
     $need_m2s++;
     return 1;
   },

   fixup=>sub {
     my ($action, $what)=@_;
     add_note(fixup=>$what);
     $need_fixup++;
     return 1;
   },

   fixupconfig=>sub {
     my ($action, $what)=@_;
     foreach my $c (handle_eval( $what )) {
       add_note(fixupconfig=>(ref $c
			      ? $c->[1]."\t".$c->[0]
			      : $MATCHED_URI."\t$c"));
     }
     $need_fixup++;
     return 1;
   },

   key=>sub {
     my ($action, $what)=@_;
     $KEY=handle_eval( $what );
     return 1;
   },

   state=>sub {
     my ($action, $what)=@_;
     $what=lc handle_eval( $what );
     if( exists $states{$what} ) {
       $STATE=$states{$what};
     } else {
       $r->warn(__PACKAGE__.": invalid state $what");
     }
     return 1;
   },

   error=>sub {
     my ($action, $what)=@_;
     my ($code, $msg)=handle_eval( $what );
     die Apache2::Translation::Error->new( code=>$code||500,
					   msg=>$msg||'unspecified error' );
   },

   redirect=>sub {
     my ($action, $what)=@_;
     my ($loc, $code)=handle_eval( $what );
     die Apache2::Translation::Error->new( msg=>"Action REDIRECT: location not set" )
       unless( length $loc );
     die Apache2::Translation::Error->new( loc=>$loc, code=>$code||302 );
   },

   call=>sub {
     my ($action, $what)=@_;
     local @ARGV;
     ($what, @ARGV)=handle_eval( $what );
     my @l=$cf->{provider}->fetch( $KEY, $what );
     @l=$cf->{provider}->fetch( '*', $what ) unless( @l );
     process( @l );
     return 1;
   },

   restart=>sub {
     my ($action, $what)=@_;
     if( length $what ) {
       my @l=handle_eval( $what );
       if( length $l[0] ) {
	 $r->uri($l[0]);
       } else {
	 $l[0]=$r->uri;
       }
       $l[1]=$cf->{key} unless( defined $l[1] );
       $l[2]='' unless( defined $l[2] );
       ($MATCHED_URI, $KEY, $MATCHED_PATH_INFO)=@l[0..2];
       $MATCHED_URI=~s!/+!/!g;
       die Apache2::Translation::Error->new( code=>Apache2::Const::HTTP_BAD_REQUEST,
					     msg=>"BAD REQUEST: $MATCHED_URI" )
	 unless( $MATCHED_URI=~m!^/! or $MATCHED_URI eq '*' );
     }
     $STATE=PREPROC;
     $skip_uri_cut++;
     return 0;
   },

   done=>sub {
     my ($action, $what)=@_;
     $STATE=$next_state{$STATE};
     return 0;
   },

   last=>sub {
     my ($action, $what)=@_;
     return 0;
   },
  );

sub handle_action {
  my ($a)=@_;
  if( $a=~/\A(?:(\w+)(?::\s*(.+))?)|(.+)\Z/s ) {
    my ($action, $what)=(defined $1 ? lc($1) : 'do',
			 defined $1 ? $2 : $3);

    warn "Action: $action: $what\n" if($DEBUG);

    if( exists $action_dispatcher{$action} ) {
      return $action_dispatcher{$action}->($action, $what);
    }
  }

  $r->warn(__PACKAGE__.": UNKNOWN ACTION '$a' skipped");
  return 1;
}

sub process {
  my $rec=shift;

  my $block;
  my $cond=1;
  my $all_skipped=1;

  if( $rec ) {
    warn "\nState $state_names[$STATE]: uri = $MATCHED_URI\n"
      if( $DEBUG==1 );
    $block=$rec->[0];
    #warn "\ncond=$cond\nblock=$block: $rec->[1]: $rec->[2]\n";
    if( $rec->[2]=~/^COND:\s*(.+)/si ) {
      warn "Action: cond: $1\n" if($DEBUG);
      $cond &&= handle_eval( $1 );
    } elsif( $cond ) {
      handle_action( $rec->[2] ) or return 0;
      $all_skipped=0;
    }
  }

  while( $rec=shift ) {
    #warn "\ncond=$cond\nblock=$block: $rec->[1]: $rec->[2]\n";
    unless( $block==$rec->[0] ) {
      $block=$rec->[0];
      $cond=1;
    }
    if( $rec->[2]=~/^COND:\s*(.+)/si ) {
      warn "Action: cond: $1\n" if($DEBUG);
      $cond &&= handle_eval( $1 );
    } elsif( $cond ) {
      handle_action( $rec->[2] ) or return 0;
      $all_skipped=0;
    }
  }

  if( $all_skipped ) {
    $STATE=$default_shift{$STATE};
  }

  return 1;
}

sub add_config {
  my $stmts=shift;

  my @l;
  foreach my $el (@{$stmts}) {
    if( ref($el) ) {
      if( @{$el}<2 ) {
	$el=$el->[0];
      } elsif( !length $el->[1] ) {
	$el->[1]='/';
      }
    }
    if( ref($el) ) {
      if( ref($l[0]) and $l[0]->[1] eq $el->[1] ) {
	push @l, $el;
      } else {
	if( @l ) {
	  if( ref($l[0]) ) {
	    if( $DEBUG>1 ) {
	      local $"="\n  ";
	      warn "Applying Config: path=$l[0]->[1]\n  @{[map {$_->[0]} @l]}\n";
	    }
	    $r->add_config( [map {$_->[0]} @l], 0xff, $l[0]->[1] );
	  } else {
	    if( $DEBUG>1 ) {
	      local $"="\n  ";
	      warn "Applying Config: path=undef\n  @l\n";
	    }
	    $r->add_config( \@l, 0xff );
	  }
	}
	@l=($el);
      }
    } else {			# $el is a simple line
      if( ref($l[0]) ) {	# but $l[0] is not
	if( @l ) {
	  if( $DEBUG>1 ) {
	    local $"="\n  ";
	    warn "Applying Config: path=$l[0]->[1]\n  @{[map {$_->[0]} @l]}\n";
	  }
	  $r->add_config( [map {$_->[0]} @l], 0xff, $l[0]->[1] );
	}
	@l=($el);
      } else {			# and so is $l[0]
	push @l, $el;
      }
    }
  }
  if( @l ) {
    if( ref($l[0]) ) {
      if( $DEBUG>1 ) {
	local $"="\n  ";
	warn "Applying Config: path=$l[0]->[1]\n  @{[map {$_->[0]} @l]}\n";
      }
      $r->add_config( [map {$_->[0]} @l], 0xff, $l[0]->[1] );
    } else {
      if( $DEBUG>1 ) {
	local $"="\n  ";
	warn "Applying Config: path=undef\n  @l\n";
      }
      $r->add_config( \@l, 0xff );
    }
  }
}

sub logger {
  my $s=join('', @_);
  foreach my $x (split /\n/, $s) {
    $r->server->log->notice($x);
  }
}

sub maptostorage {
  local ($cf,$r);
  $r=$_[0];
  local $SIG{__WARN__}=\&logger;

  warn "\nMapToStorage\n" if( $DEBUG>1 );

  my $rc=Apache2::Const::DECLINED;

  my @config=$r->notes->get(__PACKAGE__."::config");
  #$r->notes->unset(__PACKAGE__."::config");
  if( @config ) {
    add_config([map {my @l=split /\t/, $_, 2;
		     @l==2 ? [reverse @l] : $_} @config]);
  }

  my $shortcut=$r->notes->get(__PACKAGE__."::shortcut_maptostorage");
  #$r->notes->unset(__PACKAGE__."::shortcut_maptostorage");
  if( $shortcut ) {
    warn "PERLHANDLER: short cutting MapToStorage\n" if($DEBUG>1);
    unless(defined $r->path_info) {
      my $pi=substr($shortcut, 1);
      warn "PERLHANDLER: setting path_info to '$pi'\n" if($DEBUG>1);
      $r->path_info($pi);
    }
    $rc=Apache2::Const::OK;
  }

  return $rc;
}

sub fixup {
  local ($cf,$r);
  $r=$_[0];
  local $SIG{__WARN__}=\&logger;

  warn "\nFixup\n" if( $DEBUG>1 );

  foreach my $do ($r->notes->get(__PACKAGE__."::fixup")) {
    warn( "Fixup: $do\n" ) if($DEBUG>1);
    handle_eval( $do );
  }
  #$r->notes->unset(__PACKAGE__."::fixup");

  my @config=$r->notes->get(__PACKAGE__."::fixupconfig");
  #$r->notes->unset(__PACKAGE__."::fixupconfig");
  if( @config ) {
    add_config([map {my @l=split /\t/, $_, 2;
		     @l==2 ? [reverse @l] : $_} @config]);
  }
  my $proxy=$r->notes->get(__PACKAGE__."::fixupproxy");
  #$r->notes->unset(__PACKAGE__."::fixupproxy");
  if( length $proxy ) {
    my @l=split /\t/, $proxy;
    warn( ($l[0]==2?"REVERSE ":'')."PROXY to $l[1]\n" ) if($DEBUG>1);
    $r->proxyreq($l[0]);
    $r->filename("proxy:$l[1]");
    $r->handler('proxy_server');
  }

  return Apache2::Const::DECLINED;
}

sub response {
  local ($cf,$r);
  $r=$_[0];
  local $SIG{__WARN__}=\&logger;

  my $handler;
  my $what=$r->notes->get(__PACKAGE__."::response");
  #$r->notes->unset(__PACKAGE__."::response");
  $what=handle_eval( $what );

  {
    no strict 'refs';
    $handler=(defined(&{$what})?\&{$what}:
	      defined(&{$what.'::handler'})?\&{$what.'::handler'}:
	      $what->can('handler')?sub {$what->handler(@_)}:
	      $what);
  }

  if( ref $handler eq 'CODE' ) {
    unshift @_, $what if( grep $_ eq 'method', attributes::get($handler) );
    goto $handler;
  }

  unless( ref $handler ) {
    # handler routine not defined yet. try to load a module
    eval "require $handler";
    if( $@ ) {
      if( $handler=~s/::\w+$// ) {
	# retry without the trailing ::handler
	eval "require $handler";
      }
    }
    $r->warn( __PACKAGE__.": Handler module $handler loaded -- consider to load it at server startup" )
      unless( $@ );
    $handler=(defined(&{$what})?\&{$what}:
	      defined(&{$what.'::handler'})?\&{$what.'::handler'}:
	      $what->can('handler')?sub {$what->handler(@_)}:
	      $what);

    if( ref $handler eq 'CODE' ) {
      unshift @_, $what if( grep $_ eq 'method', attributes::get($handler) );
      goto $handler;
    }

    $r->warn( __PACKAGE__.": Cannot find handler $what".($@?": $@":'') );
  }
  return Apache2::Const::SERVER_ERROR;
}

sub doc {
  local ($cf,$r);
  $r=$_[0];
  local $SIG{__WARN__}=\&logger;

  my $what=$r->notes->get(__PACKAGE__."::response");
  #$r->notes->unset(__PACKAGE__."::response");

  my @l=handle_eval( $what );
  unshift @l, 'text/plain' if( @l==1 );
  $r->content_type( $l[0] );
  $r->headers_out->{'Content-Length'}=do { use bytes; length $l[1] };
  $r->print($l[1]);

  return Apache2::Const::OK;
}

my @state_machine=
  (
   # START
   sub {
     ($KEY, $MATCHED_URI, $MATCHED_PATH_INFO, $STATE)=
       ($cf->{key}, $r->uri, '', $m2s ? LOOKUPFILE : PREPROC);
     return if( $m2s );
     $MATCHED_URI=~s!/+!/!g;
     die Apache2::Translation::Error->new( code=>Apache2::Const::HTTP_BAD_REQUEST,
					   msg=>"BAD REQUEST: $MATCHED_URI" )
       unless( $MATCHED_URI=~m!^/! or $MATCHED_URI eq '*' );
   },

   # PREPROC
   sub {
     my $k=$KEY;
     process( $cf->{provider}->fetch( $k, PRE_URI ) );
     $STATE=PROC
       if( $k eq $KEY and $STATE==PREPROC );
   },

   # PROC
   sub {
     my $uri=$MATCHED_URI;
     unless( length $uri ) {
       $STATE=DONE;
       return;
     }
     process( $cf->{provider}->fetch( $KEY, $uri ) );
     if( $STATE==PROC and !$skip_uri_cut ) {
       if( $uri=~m!^[/*]$! and $MATCHED_URI eq $uri ) {
	 $STATE=$next_state{$STATE};
	 return;
       }
       if( $MATCHED_URI=~s!(/[^/]*)$!! ) {
	 $MATCHED_PATH_INFO=$1.$MATCHED_PATH_INFO;
	 $MATCHED_URI='/' unless( length $MATCHED_URI );
       }
     }
   },

   # DONE
   'ERROR: Trying to cycle in DONE state',

   # LOOKUPFILE
   sub {
     my $k=$KEY;
     process( $cf->{provider}->fetch( $k, LOOKUPFILE_URI ) );
     $STATE=PROC
       if( $k eq $KEY and $STATE==LOOKUPFILE );
   },

  );

sub handler {
  local ($cf,$r,$RC,$STATE,$m2s,$need_fixup,$need_m2s,%CTX, $ctx);
  $ctx=\%CTX;
  $r=$_[0];
  local $SIG{__WARN__}=\&logger;

  return Apache2::Const::DECLINED if( $r->notes->{__PACKAGE__.'-done'} );
  $r->notes->{__PACKAGE__.'-done'}=1;

  $m2s=(ModPerl::Util::current_callback eq 'PerlMapToStorageHandler');

  $cf=Apache2::Module::get_config(__PACKAGE__, $r->server);
  my $prov=$cf->{provider};

  $DEBUG=2 if( $r->server->loglevel==Apache2::Const::LOG_DEBUG );

  $STATE=START;
  eval {
    $prov->start;

    while( $STATE!=DONE ) {
      warn "\nState $state_names[$STATE]: ".
	   ($STATE==START?'...':"uri = $MATCHED_URI")."\n"
	if( $DEBUG>1 );
      local $skip_uri_cut;
      $state_machine[$STATE]->();
    }

    $prov->stop;

    $r->push_handlers( PerlFixupHandler=>__PACKAGE__.'::fixup' )
      if( $need_fixup );
    $r->push_handlers( PerlMapToStorageHandler=>__PACKAGE__.'::maptostorage' )
      if( !$m2s and $need_m2s );

    warn "proceed with URI '".$r->uri."' and FILENAME '".$r->filename."'\n"
      if( $DEBUG );
  };

  if( $@ ) {
    if( ref($@) eq 'Apache2::Translation::Error' ) {
      $@->{code}=Apache2::Const::SERVER_ERROR unless( exists $@->{code} );

      if( exists $@->{loc} and 300<=$@->{code} and $@->{code}<=399 ) {
	my $loc=$@->{loc};
	unless( $loc=~/^\w+:/ ) {
	  unless( $loc=~m!^/! ) {
	    my $uri=$r->uri;
	    $uri=~s![^/]*$!!;
	    $loc=$uri.$loc;
	  }

	  my $host=$r->headers_in->{Host} || $r->hostname;
	  $host=~s/:\d+$//;

	  if( $r->connection->is_https ) {
	    if( $r->connection->local_addr->port!=443 ) {
	      $loc=':'.$r->connection->local_addr->port.$loc;
	    }
	    $loc='https://'.$host.$loc;
	  } else {
	    if( $r->connection->local_addr->port!=80 ) {
	      $loc=':'.$r->connection->local_addr->port.$loc;
	    }
	    $loc='http://'.$host.$loc;
	  }
	}
	$r->err_headers_out->{Location}=$loc;
	# change status of $r->prev if $r is the result of an ErrorDocument
	my $er=$r->prev;
	if( $er ) {
	  while( $er->prev ) {$er=$er->prev};
	  $er->status($@->{code});
	}
      }

      if( exists $@->{msg} ) {
	$@->{msg}=~s/\s*$//;
	$r->log_reason(__PACKAGE__.": $@->{msg}");
      }

      return $@->{code};
    } else {
      (my $e=$@)=~s/\s*$//;
      $r->log_reason(__PACKAGE__.": TranslationProvider error: $e");
      return Apache2::Const::SERVER_ERROR;
    }
  }

  return maptostorage($r) if( $m2s );
  return $RC if( defined $RC );
  return length $r->filename ? Apache2::Const::OK : Apache2::Const::DECLINED;
}

1;
__END__
