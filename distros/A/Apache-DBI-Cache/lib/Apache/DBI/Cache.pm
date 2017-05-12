package Apache::DBI::Cache;

use 5.008;
use strict;
use warnings;
no warnings 'uninitialized';

our $VERSION = '0.08';

BEGIN { eval { require Apache; } }
BEGIN { eval { require mod_perl2; require Apache2::Module; } }

our $DEBUG = 0;
our $LOG=sub {
  my $level=shift;

  my @l=localtime;
  my $prefix=sprintf( '%5d %d%02d%02d %02d%02d%02d '.__PACKAGE__."   ",
		      $$, $l[5]+1900, $l[4]+1, @l[3,2,1,0] );
  print STDERR $prefix, @_, "\n" if( $DEBUG >= $level );
};

if( exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION}==2 ) {
  require Apache2::ServerUtil;
  require Apache2::Log;
  my $s = Apache2::ServerUtil->server;
  $s->push_handlers(PerlChildInitHandler => \&init);
  $s->push_handlers(PerlChildExitHandler => \&finish);
  $s->push_handlers(PerlChildInitHandler =>
		    sub {
		      Apache2::Status->menu_item('DBI_conn' => 'DBI connections',
						 \&statistics_as_html)
			  if Apache2::Module::loaded('Apache2::Status');
		    } );
  $LOG=sub {
    my $level=shift;

    my $log=$s->log;

    if( $level==0 ) {
      $log->error(__PACKAGE__.': '.join('', @_));
    } elsif( $level==1 ) {
      $log->info(__PACKAGE__.': '.join('', @_));
    } elsif( $DEBUG>=2 ) {
      $log->debug("$$: ".join('', @_));
    }
  };
} elsif( exists $INC{'Apache.pm'} ) {
  require Apache::Log;
  if( Apache->can('push_handlers') ) {
    Apache->push_handlers(PerlChildInitHandler => \&init);
    Apache->push_handlers(PerlChildExitHandler => \&finish);
    Apache->push_handlers(PerlChildInitHandler =>
			  sub {
			    Apache::Status->menu_item('DBI_conn' => 'DBI connections',
						      \&statistics_as_html)
				if( Apache->can('module') and              # really?
				    Apache->module('Apache::Status') );    # Apache::Status too?
			  } );
  }
  if( Apache->can('server') ) {
    $LOG=sub {
      my $level=shift;

      my $log=Apache->server->log;

      if( $level==0 ) {
	$log->error(__PACKAGE__.': '.join('', @_));
      } elsif( $level==1 ) {
	$log->info(__PACKAGE__.': '.join('', @_));
      } elsif( $DEBUG>=2 ) {
	$log->debug("$$: ".join('', @_));
      }
    };
  }
}

use DBI ();

require_version DBI 1.37;

our %Connected;    # cache for database handles
our @ChildConnect; # connections to be established when a new httpd child is created
our %STAT;	   # gather statistics. This will be tied to BerkeleyDB.
our $STATdb;	   # object %STAT is tied to
our %localSTAT;
our %plugin;

our $DELIMITER="\1";
our $GLOBAL_DESTROY;
our $PRIVATE='private_'.__PACKAGE__;

my $use_bdb;
my $envpath;
my $bdb_memcache;

sub import {
  my $class=shift;
  my %o;
  while( my ($k, $v)=splice @_, 0, 2 ) {
    $o{$k}=[] unless( exists $o{$k} );
    push @{$o{$k}}, $v;
  }

  $DEBUG=$o{debug}->[0] if(exists $o{debug});
  $LOG=$o{logger}->[0] if(exists $o{logger});
  $DELIMITER=$o{delimiter}->[0] if(exists $o{delimiter});

  if(exists $o{use_bdb}) {
    $use_bdb=$o{use_bdb}->[0];
  } elsif( eval {require BerkeleyDB; require File::Path;} ) {
    $use_bdb=1;
  }

  if( $use_bdb ) {
    require BerkeleyDB; require File::Path;

    if(exists $o{bdb_env}) {
      $envpath=$o{bdb_env}->[0];
    } elsif(exists $ENV{APACHE_DBI_CACHE_ENVPATH}) {
      $envpath=$ENV{APACHE_DBI_CACHE_ENVPATH};
    }
    $envpath='/tmp/'.__PACKAGE__ unless(length $envpath);
    File::Path::rmtree( $envpath );
    die "ERROR: Cannot remove $envpath: $!\n" if( -e $envpath );

    if(exists $o{bdb_memcache}) {
      $bdb_memcache=$o{bdb_memcache}->[0];
    } elsif(exists $ENV{APACHE_DBI_CACHE_CACHESIZE}) {
      $bdb_memcache=$ENV{APACHE_DBI_CACHE_CACHESIZE};
    }
    $bdb_memcache=20*1024 if( $bdb_memcache==0 );
  }

  if(exists $o{plugin}) {
    foreach my $v (@{$o{plugin}}) {
      if(ref $v eq 'ARRAY') {
	plugin(@{$v});
      } else {
	eval "use $v";
	die "$@" if $@;
      }
    }
  }
}

sub plugin {
  my $driver=shift;
  my $old=$plugin{$driver};
  if( @_==2 and ref $_[0] eq 'CODE' and ref $_[1] eq 'CODE' ) {
    $plugin{$driver}=[@_];
  } elsif( @_==2 and !defined $_[0] and !defined $_[1] ) {
    delete $plugin{$driver};
  }
  return @{$old||[]};
}

sub _statop {
  my $statIdx=shift;

  if( $STATdb ) {
    my $lock=$STATdb->cds_lock;
    my $stat=$STAT{$statIdx} || [0,0,0,0,0];
    my $lstat=$localSTAT{$statIdx} || [0,0,0,0,0];
    while( my ($i, $x)=splice @_, 0, 2 ) {
      $stat->[$i]+=$x;
      $lstat->[$i]+=$x;
    }
    $STAT{$statIdx}=$stat;
    $localSTAT{$statIdx}=$lstat;
    $lock->cds_unlock;
  } else {
    my $stat=$STAT{$statIdx} || [0,0,0,0,0];
    while( my ($i, $x)=splice @_, 0, 2 ) {
      $stat->[$i]+=$x;
    }
    $STAT{$statIdx}=$stat;
  }
}

{
  my $init=0;
  sub init {
    if( $init ) {
      $LOG->(2, "init: already initialized");
      return 1;
    }

    undef $GLOBAL_DESTROY;
    if( $use_bdb ) {
      $LOG->(1, "init: initializing BerkeleyDB environment at $envpath");
      unless( -d $envpath ) {
	File::Path::mkpath( $envpath );
	die "ERROR: Cannot create $envpath: $!\n" unless( -d $envpath );
      }

      my $env=BerkeleyDB::Env->new
	( -Home=>$envpath,
	  -Cachesize=>$bdb_memcache,
	  -ErrFile=>\*STDERR,
	  -ErrPrefix=>__PACKAGE__.' BerkeleyDB',
	  -Flags=>(&BerkeleyDB::DB_CREATE|
		   &BerkeleyDB::DB_INIT_CDB|
		   &BerkeleyDB::DB_INIT_MPOOL),
	);
      die "ERROR: Cannot create BerkeleyDB environment ($envpath): $BerkeleyDB::Error\n"
	unless( $env );

      $STATdb=tie( %STAT, 'BerkeleyDB::Btree',
		   -Filename=>'handles.db',
		   -Env=>$env,
		   -Flags=>&BerkeleyDB::DB_CREATE,
		);
      $STATdb->filter_store_value( sub {no warnings 'uninitialized'; $_=join ':', @$_} );
      $STATdb->filter_fetch_value( sub {no warnings 'uninitialized'; $_=[split ':', $_]} );
    } else {
      $LOG->(1, "init: working without BerkeleyDB");
    }

    # redirect connects to us
    $DBI::connect_via=__PACKAGE__.'::connect';
    # redirect &DBI::connect_cached to DBI::connect
    undef &DBI::connect_cached;
    *DBI::connect_cached=\&DBI::connect;
    my @l;
    for my $aref (@ChildConnect) {
      shift @$aref if( UNIVERSAL::isa( $aref->[0], __PACKAGE__ ) );
      my $dbh=DBI->connect(@$aref);
      push @l, $dbh if($dbh);
    }
    @ChildConnect=();
    @l=();
    $init=1;
    eval 'END{finish();}';
    1;
  }

  sub finish {
    return unless( $init );
    $GLOBAL_DESTROY=1;
    if( $STATdb ) {
      foreach (keys %localSTAT) {
	_statop( $_,
		 0, -$localSTAT{$_}->[0],   # decr. handle count
		 1, -$localSTAT{$_}->[1] ); # decr. free count
      }
    }
    %Connected=();

    if( $use_bdb ) {
      $LOG->(2, "finish: shutting down BerkeleyDB environment");
      undef $STATdb;
      untie %STAT;
    }

    $init=0;
    1;
  }
}

{
  my @undef_at_cleanup;
  sub undef_at_request_cleanup {
    my @l=grep {ref eq 'REF' or ref eq 'SCALAR'} @_;
    return unless( @l );
    $LOG->(2, "undef_at_request_cleanup: @{[map {${$_}} @l]}");
    unless( @undef_at_cleanup ) {
      if( exists $ENV{MOD_PERL_API_VERSION} and $ENV{MOD_PERL_API_VERSION}==2 ) {
	require Apache2::RequestUtil;
	Apache2::RequestUtil->request
	    ->push_handlers(PerlCleanupHandler=>\&request_cleanup);
      } elsif( exists $INC{'Apache.pm'} and Apache->can( 'push_handlers' ) ) {
	Apache->push_handlers(PerlCleanupHandler=>\&request_cleanup);
      }
    }
    push @undef_at_cleanup, @l;
  }
  sub request_cleanup {
    $LOG->(2, "request_cleanup:");
    foreach my $v (@undef_at_cleanup) {
      $LOG->(2, "    undefining ${$v}");
      undef ${$v};
    }
    @undef_at_cleanup=();
  }
}

sub connect_on_init {
  # provide a handler which creates all connections during server startup

  # store connections
  push @ChildConnect, [@_];
}


# the connect method called from DBI::connect
our %patched_classes=('Apache::DBI::Cache'=>1);
sub connect {
  my $class = shift;
  unshift @_, $class if ref $class;
  my $drh    = shift;
  my @args   = map { defined $_ ? $_ : "" } @_;

  unless( 3 == $#args and ref $args[3] eq "HASH" ) {
    @args=(@args[0..2], {});
  }

  my ($Idx, $statIdx, $ctx);
  if( exists $plugin{$drh->{Name}} ) {
    my @l=$plugin{$drh->{Name}}->[0]->(@args);
    if( @l ) {
      my $nocache;
      ($ctx, $nocache)=splice @l, 4, 2;
      @args[0..2]=@l[0..2];
      %{$args[3]}=%{$l[3]};
      return $drh->connect(@args) if( $nocache );
    } else {
      return $drh->connect(@args);
    }
  }
  my $dsn="dbi:$drh->{Name}:$args[0]";

  my $RootClass=delete $args[3]->{RootClass};
  unless( defined $RootClass ) {
    # this is a very ugly hack
    package		# this line break should make the CPAN indexer happy
      DB;		# to get @DB::args set by caller()
    for( my $i=1; my @l=caller($i++); ) {
      if( $l[3] eq 'DBI::connect' ) {
	$RootClass=$DB::args[0] unless( $DB::args[0] eq 'DBI' );
	last;
      }
    }
  }

  $Idx    =join $DELIMITER, $drh->{Name}, $args[0], $args[1], $args[2];
  $statIdx=join $DELIMITER, $drh->{Name}, $args[0], $args[1];

  # should we default to '__undef__' or something for undef values?
  map { $Idx .= "$DELIMITER$_=" .
	  (defined $args[3]->{$_}
	   ? $args[3]->{$_}
	   : '');
      } sort keys %{$args[3]};

  if( defined $RootClass ) {
    unless( $patched_classes{$RootClass} ) {
      # this is a very ugly hack
      $patched_classes{$RootClass}=1;
      no strict 'refs';
      no warnings 'redefine';
      *{$RootClass.'::db::disconnect'}=\&Apache::DBI::Cache::db::disconnect;
      *{$RootClass.'::db::DESTROY'}=\&Apache::DBI::Cache::db::DESTROY;
    }
    $args[3]->{RootClass}=$RootClass;
  } else {
    $args[3]->{RootClass}=__PACKAGE__;
  }

  if( exists $Connected{$Idx} ) {
    while( my $dbh=shift @{$Connected{$Idx}} ) {
      local $GLOBAL_DESTROY=2;
      if( eval{$dbh->ping} ) {
	if( exists $plugin{$drh->{Name}} ) {
	  unless( $plugin{$drh->{Name}}->[1]->($dbh, @args, $ctx) ) {
	    _statop( $statIdx,
		     4, 1,	# plugin failure
		     1, -1,	# decr. free count
		     0, -1 );	# decr. handle count
	    $LOG->(2, "reusing connection to '$Idx' failed due to plugin error");
	    undef $dbh;
	    next;
	  }
	}
	_statop( $statIdx,
		 2, 1,		# incr. usage count
		 1, -1 );	# decr. free count
	$LOG->(2, "reusing connection to '$Idx'");
	$dbh->{$PRIVATE}->{disconnected}=0;
	return $dbh;
      } else {
	_statop( $statIdx,
		 3, 1,		# ping failure
		 1, -1,		# decr. free count
		 0, -1 );	# decr. handle count
	$LOG->(2, "reusing connection to '$Idx' failed due to PING failure");
	undef $dbh;
      }
    }
  }

  my $dbh=$drh->connect(@args);

  if( defined $dbh ) {
    my $privattr={%{$args[3]}};
    delete $privattr->{RootClass};
    $dbh->{$PRIVATE}=+{
		       disconnected=>0,
		       idx=>$Idx,
		       statIdx=>$statIdx,
		       attr=>$privattr,
		      };

    if( exists $plugin{$drh->{Name}} ) {
      local $GLOBAL_DESTROY=2;
      unless( $plugin{$drh->{Name}}->[1]->($dbh, @args, $ctx) ) {
	_statop( $statIdx, 4, 1 ); # plugin error
	$LOG->(2, "new connection to '$Idx' failed due to plugin error");
	undef $dbh;
	return;
      }
    }

    _statop( $statIdx, 0, 1, 2, 1 ); # incr. handle count, incr. usage
  }

  # return the new database handle
  $LOG->(2, "new connection to '$Idx'");
  return $dbh;
}


sub statistics {
  return \%STAT;
}

{
  my %esc=(qw/" &quot; < &lt; > &gt; & &amp;/);
  $esc{' '}='&nbsp;';
  my $esc=sub {
    my $v=shift;
    $v=length $v ? $v : ' ';
    $v=~s/(["<>& ])/$esc{$1}/ge;
    $v;
  };

  sub statistics_as_html {
    my @s;

    my $lock;

    if( $STATdb ) {
      $lock=$STATdb->cds_lock;
      push @s, "<h1>DBI Handle Statistics for this machine</h1>\n";
    } else {
      push @s, "<h1>DBI Handle Statistics for process ".$esc->($$)."</h1>\n";
    }

    push @s, ('<table border="1">'."\n",
	      '<tr><th>Driver</th><th>Datasource</th>'.
	      '<th>Username</th><th>Handle Count</th><th>Free Handles</th>'.
	      '<th>Usage Count</th><th>Ping Failures</th><th>Plugin Failures</th>'.
	      '</tr>'."\n");
    foreach my $k (keys %STAT) {
      my $v=join( '</td><td>', map {$esc->($_)} @{$STAT{$k}} );
      push( @s,
	    ('<tr><td>'.
	     join('</td><td>',
		  map {$esc->($_)} (split /\Q$DELIMITER\E/, $k)[0..2]).
	     "</td><td>$v</td></tr>\n") );
    }
    push @s, "</table>\n";

    $lock->cds_unlock if( defined $lock );
    return \@s;
  }
}

{
  package Apache::DBI::Cache::st;
  use base qw(DBI::st);
}

# overload disconnect
{
  package Apache::DBI::Cache::db;
  use base qw(DBI::db);
  use strict;

  sub disconnect {
    my $dbh=shift;

    my $priv=$dbh->{$PRIVATE};
    my $Idx=$priv->{idx};

    $LOG->(2, "disconnect $Idx");

    if( $priv->{'disconnected'} ) {
      $LOG->(2, "already disconnect");
      return 1;
    }

    if( $dbh->{Active} and !$dbh->{AutoCommit} and eval {$dbh->rollback} ) {
      $LOG->(2, "ROLLBACK");
    }

    foreach my $k (keys %{$priv->{attr}}) {
      $dbh->{$k}=$priv->{attr}->{$k};
    }

    $priv->{'disconnected'}=1;

    Apache::DBI::Cache::_statop( $priv->{statIdx}, 1, 1 ); # incr. free count
    if( exists $Connected{$Idx} ) {
      push @{$Connected{$Idx}}, $dbh;
    } else {
      $Connected{$Idx}=[$dbh];
    }

    1;
  }

  sub DESTROY {
    my $dbh=shift;

    if( $GLOBAL_DESTROY ) {
      if( $GLOBAL_DESTROY>1 ) {
	$LOG->(2, "GLOBAL DESTROY $dbh->{$PRIVATE}->{idx}");
      }
      $dbh->SUPER::disconnect;
      $dbh->SUPER::DESTROY;
    } else {
      $LOG->(2, "DESTROY $dbh->{$PRIVATE}->{idx}");
      $dbh->disconnect;
    }
    1;
  }
}

1;
__END__
