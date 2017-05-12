package Activator::DB;
use strict;
use warnings;

use Activator::Log qw( :levels );
use Activator::Registry;
use DBI;
use Exception::Class::DBI;
use Exception::Class::TryCatch;
use Data::Dumper;
use Time::HiRes qw( gettimeofday tv_interval );
use Scalar::Util;
use base 'Class::StrongSingleton';

# constructor: implements singleton
sub new {
    my ( $pkg, $conn_alias ) = @_;

    my $self = bless( {}, $pkg);

    $self->_init_StrongSingleton();

    return $self;
}

# connect to a db alias
# initializes singleton object returned from new()
# Args:
#   $conn_alias => the alias to use as configured in the registry
sub connect {
    my ( $pkg, $conn_alias ) = @_;
    my $self = &new( @_ );

    $conn_alias ||= 'default';

    # first call
    # TODO: also look for a some sighup to reload this config
    if( !keys( %{ $self->{config} } ) ) {
	$self->_init();
    }

    # set the current alias for the object
    if ( $conn_alias !~ /^def(ault)?$/ ) {
	$self->{cur_alias} = $conn_alias;
    }
    else {
	$self->{last_alias} = $self->{cur_alias};
	$self->{cur_alias} = $self->{default}->{connection};
    }

    my $conn;
    try eval {
	$conn = $self->_get_cur_conn();
    };
    if ( catch my $e ) {
	$self->{cur_alias} = $self->{last_alias};
	$e->rethrow;
    }


    # est. the actual connection if it's not set
    if ( !$conn->{dbh} ) {
	try eval {
	    $self->_debug_connection( 2, "Connecting to alias $self->{cur_alias}" );
	    $self->_debug_connection( 2, 'Connect Parameters:');
	    $self->_debug_connection( 2, "   dsn  => $conn->{dsn}");
	    $self->_debug_connection( 2, "   user => $conn->{user}");
	    $self->_debug_connection( 2, '   pass => ' . ( $conn->{pass} || ''));
	    $self->_debug_connection( 2, Data::Dumper->Dump( [ $conn->{attr} ], [ '  attr' ] ) );

	    try eval {
		$conn->{dbh} = DBI->connect( $conn->{dsn},
					     $conn->{user} || '',
					     $conn->{pass} || '',
					     $conn->{attr}
					   );
	    };

	    if ( catch my $e ) {
		Activator::Exception::DB->throw( 'dbh',
						 'connect',
						 "$e " .
						 Data::Dumper->Dump( [ $conn ], [ 'connection' ] )
					       );
	    }

	    # TODO: do something more generic with this
	    # mysql_auto_reconnect now cannot be disconnected
	    if ( $conn->{dsn} =~ /mysql/i ) {
		$conn->{dbh}->{mysql_auto_reconnect} = $self->{config}->{mysql}->{auto_reconnect};
	    }
	    elsif ( my $search_path = $conn->{config}->{Pg}->{search_path} ) {
		$self->do("SET search_path TO ?", [ $search_path ]);
	    }
	    # test cur_alias $conn->{dbh}, may throw exception
	    $self->_ping();
	    $self->_debug_connection( 2, "alias '$conn->{alias}' db handle pinged and ready for action");
	};
	if ( catch my $e ) {
	    $e->rethrow;
	}

    }

    return $self;
}

sub _init {
    my ( $self ) = @_;
    $self->_start_timer();
    my $setup = Activator::Registry->get( 'Activator::DB' );
    if (!keys %$setup ) {
	$setup = Activator::Registry->get( 'Activator->DB' );
	if (!keys %$setup ) {
	    Activator::Exception::DB->throw( 'activator_db_config', 'missing', 'You must define the key "Activator::DB" or "Activator->DB" in your project configuration' );
	}
    }

    # module defaults
    $self->{config} = { debug            => 0,
			debug_connection => 0,
			debug_attr       => 0,
			reconn_att       => 3,
			reconn_sleep     => 1,
			mysql => { auto_reconnect => 1 },
			Pg    => { search_path => 'public' },
		      };
    $self->{attr} = {   RaiseError   => 0,
			PrintError   => 0,
			HandleError  => Exception::Class::DBI->handler,
			AutoCommit   => 1,
		    };
    $self->{connections} = {};

    # setup the current alias key
    $self->{cur_alias} =
      $self->{default}->{connection} =
	$setup->{default}->{connection} ||
	  Activator::Exception::DB->throw( 'connect',
					   'config',
					   'default: connection not set!'
					 );

    # setup default attributes. NOTE: even though we only support
    # AutoCommit, this block can easily be extended for other
    # attributes.
    foreach my $key ( 'AutoCommit' ) {
	my $value = $setup->{default}->{attr}->{ $key };
	$self->{ $key } =
	  defined( $value ) ? $value : $self->{attr}->{ $key };
    }

    # setup default config
    foreach my $key( keys %{ $setup->{default}->{config} } ) {
    	if ( exists ( $self->{config}->{ $key } ) ) {
    	    $self->{config}->{ $key } = $setup->{default}->{config}->{ $key };
    	}
    	else {
    	    WARN( "Ignoring default->config->$key: unsupported config option" );
    	}
    }

#    Activator::Log::set_level( $self->{config}->{debug}
#			    ? $Activator::Log::$self->_debug
#			    : $Activator::Log::WARN );

    # setup connection strings
    my ( $host, $db, $user, $pass );
    my $conns = $setup->{connections};

    foreach my $alias ( keys( %$conns ) ) {
	my $engine;
	$engine = 'mysql' if $conns->{ $alias }->{dsn} =~ /mysql/;
	$engine = 'Pg'    if $conns->{ $alias }->{dsn} =~ /Pg/;
	$self->{connections}->{ $alias }  =
	  {
	   dsn    => $conns->{ $alias }->{dsn},
	   user   => $conns->{ $alias }->{user},
	   pass   => $conns->{ $alias }->{pass},
	   attr   =>
	   {
	    RaiseError  => $self->{attr}->{RaiseError},
	    PrintError  => $self->{attr}->{PrintError},
	    HandleError => $self->{attr}->{HandleError},
	    AutoCommit  => $conns->{ $alias }->{attr}->{AutoCommit} ||
                     	    $self->{attr}->{AutoCommit},
	   },
	   config => $self->{config},
	   alias => $alias,
           engine => $engine,
	  };

	# setup default config
	foreach my $key ( keys %{ $conns->{ $alias }->{config} } ) {
	    if ( exists ( $self->{config}->{ $key } ) ) {
		$self->{connections}->{ $alias }->{config}->{ $key } =
		  $conns->{ $alias }->{config}->{ $key };
	    } else {
		WARN( "Ignoring ${alias}->config->${key}: unsupported config option" );
	    }
	}
	$self->_debug_connection( 2, "Initialized connection ".
		       Data::Dumper->Dump( [ $self->{connections}->{$alias} ],
					   [ $alias ] ) );
    }
    $self->_debug_connection( 2, 'Activator::DB initialization successful');
}

# _ping>($conn)
#
#  Test a database handle and attempt to reconnect if it is done
#
#  Args:
#    $conn_alias => connection alias to check
#
#  Throws:
#     connection.failure - failure to ping connection
#
sub _ping {
    my ( $self ) = @_;
    my $conn = $self->_get_cur_conn();
    my $dbh = $conn->{dbh};
    local $dbh->{RaiseError} = 1;
    my $reconn_att =
      $conn->{config}->{reconn_att} ||
	$self->{config}->{reconn_att};
    my $reconn_sleep =
      $conn->{config}->{reconn_sleep} ||
	$self->{config}->{reconn_sleep};
    while ( $reconn_att > 0 ) {
	try eval { $dbh->ping(); };
	if ( catch my $e ) {
	    $reconn_att--;
	    sleep $reconn_sleep;
	    $reconn_sleep *= 2;
	} else {
	    return 1;
	}
    }
    ERROR( "connection to $conn->{alias} appears to be dead" );
    Activator::Exception::DB->throw( 'ping', 'failure' );
}

# _get_cur_conn
#
# return the internal connection hash for the current connection alias
sub _get_cur_conn {
    my ( $self ) = @_;

    if ( exists( $self->{connections}->{  $self->{cur_alias} } ) ) {
	my $conn = $self->{connections}->{  $self->{cur_alias} };

#	# set the log level to this connection
#	LEVEL( $conn->{config}->{debug}
#				? $Log::Log4perl::$self->_debug
#				: $Log::Log4perl::WARN );
	return $conn;
    }
    Activator::Exception::DB->throw('alias', 'invalid', $self->{cur_alias} )
}

# explode args for a db query sub
sub _explode {
    my ( $pkg, $bindref, $args ) = @_;

    my $bind = $bindref || [];
    my $self = $pkg;
    my $connect_to = $args->{connect};

     # handle static calls
    if ( !( Scalar::Util::blessed($self) && $self->isa( 'Activator::DB') ) ) {
	if ( $connect_to ) {
	    $self = Activator::DB->connect( $connect_to );
	}
	else {
	    Activator::Exception::DB->throw( 'connect', 'missing');
	}
    }

    # static or OO, respect the connect
    if ( $connect_to ) {
	$self->{cur_alias} = $connect_to;
    }

    # This next line insures that $self refers to the singleton object
    $self = $self->connect( $self->{cur_alias} );
    my $conn = $self->_get_cur_conn()
      or Activator::Exception::DB->throw( 'connection',
					  'failure',
					  "_explode couldn't get connection for alias '$self->{cur_alias}'");

    my $attr        = $args->{attr} || {};

    return ( $self, $bind, $attr );
}

# This can never die, so we jump through hoops to return some valid scalar.
#     * replace undef values with NULL, since this is how dbi will do it
#     * If $bind is of wrong type, don't do substitutions.
#     * shift @vals to handle the case of '?' in the bind values
#     * @vals? in the regexp is to handle fewer args on the right than the left
# TODO: support attrs in debug
sub _get_sql {
    my ( $pkg, $sql, $bind ) = @_;
    $sql  ||= '';
    $bind ||= [];

    if ( ref( $bind ) eq 'ARRAY' ) {
	my @vals = @$bind;
 	map {
 	    if ( !defined($_) ) {
 		$_ = 'NULL';
 	    }
 	    else {
 		$_ =  "'$_'";
 	    } } @vals;
 	$sql =~ s/\?/@vals? (shift @vals) : '?'/egos;

	return $sql;
    }
    else {
	if ( $bind ) {
	    return "[SQL] ${sql} [BIND VARS] $bind";
	}
	return $sql;
    }
}

# returns sth, unless you want the result of the execute,
sub _get_sth {
    my ( $self, $sql, $bind, $attr, $want_exec_result ) = @_;

    my $conn = $self->_get_cur_conn();
    my $sth;

    try eval {
	$sth = $conn->{dbh}->prepare_cached( $sql, $attr );
    };
    if ( catch my $e ) {
	$self->_ping();
	try eval {
	    $sth = $conn->{dbh}->prepare_cached( $sql, $attr );
	};
	if ( catch my $e ) {
	    Activator::Exception::DB->throw( 'sth',
					     'prepare',
					     $e . " SQL: " .
					     $self->_get_sql( $sql, $bind )
					   );
	}
    }

    my $res;
    try eval {
	$res = $sth->execute( @$bind );
    };
    if ( catch my $e ) {
	Activator::Exception::DB->throw( 'sth',
					 'execute',
					 $e . " SQL: " .
					 $self->_get_sql( $sql, $bind )
				       );
    }

    if ( $want_exec_result ) {
	$sth->finish();
	return $res;
    }
    return $sth;
}

################################################################################

# getrow subs
#
# Note that we jump through some hoops ( return array of everything )
# to consolidate these 3 functions, and still log from the appropriate
# function.
#
sub getrow {
    my ($self, $sql, $bind, $args, @ret) = &_fetch( 'getrow', @_);
    return @ret;
}

sub getrow_arrayref {
    my ($self, $sql, $bind, $args, $ret) = &_fetch( 'getrow_arrayref', @_);
    return $ret;
}

sub getrow_hashref {
    my ($self, $sql, $bind, $args, $ret) = &_fetch( 'getrow_hashref', @_);
    return $ret;
}

sub getall {
    my ($self, $sql, $bind, $args, $ret) = &_fetch( 'getall', @_);
    return $ret;
}

sub getall_arrayrefs {
    my ($self, $sql, $bind, $args, $ret) = &_fetch( 'getall_arrayrefs', @_);
    return $ret;
}

sub getall_hashrefs {
    my ($self, $sql, $bind, $args, $ret) = &_fetch( 'getall_hashrefs', @_);
    return $ret;
}

sub _fetch {
    my ( $fn, $pkg, $sql, $bindref, %args ) = @_;
    my ( $self, $bind, $attr ) = $pkg->_explode( $bindref, \%args );

    $self->_start_timer();

    my $conn = $self->_get_cur_conn();

    my ( $sth, $e );
    try eval {
	$sth = $self->_get_sth( $sql, $bind, $attr );
    };
    if ( catch my $e ) {
	$e->rethrow;
    }

    my ( @row, $row, $rows );
    if ( $fn eq 'getrow') {
	try eval {
	    @row = $sth->fetchrow_array();
	    $sth->finish();
	};
    }
    elsif ( $fn eq 'getrow_arrayref' ) {
	try eval {
	    $row = $sth->fetchrow_arrayref();
	    $sth->finish();
	};
    }
    elsif ( $fn eq 'getrow_hashref' ) {
	try eval {
	    $row = $sth->fetchrow_hashref();
	    $sth->finish();
	};
    }
    elsif ( $fn eq 'getall_arrayrefs' || $fn eq 'getall' ) {
	try eval {
	    $row = $sth->fetchall_arrayref();
	    $sth->finish();
	};
    }
    elsif ( $fn eq 'getall_hashrefs' ) {
	try eval {
	    $row = $sth->fetchall_arrayref( {} );
	    $sth->finish();
	};
    }

    if ( catch my $e ) {
	Activator::Exception::DB->throw( 'sth',
					 'fetch',
					 $e .
					 $self->_get_sql( $sql, $bind )
				       );
    }


    # clean up return value for total consistency.
    if ( !defined( $row ) ) {
	if ( $fn eq 'getrow_hashref' ) {
	    $row = {};
	}
	else {
	    $row = [];
	}
    }
    $self->_debug_sql( 5, $sql, $bind, \%args);

    if ( $fn eq 'getrow' ) {
	return ( $self, $sql, $bind, \%args, @row );
    }

    return ( $self, $sql, $bind, \%args, $row );
}

sub do_id {
    my ( $pkg, $sql, $bindref, %args ) = @_;
    my ( $self, $bind, $attr ) = $pkg->_explode( $bindref, \%args );
    my $conn = $self->_get_cur_conn();

    $self->_start_timer();

    my $res;
    try eval {
	$res = $self->_get_sth( $sql, $bind, $attr, 'want_exec_result' );
    };
    if ( catch my $e ) {
	$e->rethrow;
    }

    $self->_debug_sql( 4, $sql, $bind, \%args );

    if ( $res == 1 ) {
	if ( $conn->{engine} eq 'mysql' ) {
	    return $conn->{dbh}->{mysql_insertid};
	}
	elsif ( $conn->{engine} eq 'Pg' ) {
	    my $row = $self->getrow_arrayref( "SELECT currval('$args{seq}')" );
	    return @$row[0];
	}
    } else {
	Activator::Exception::DB->throw('execute',
					'failure',
					$self->_get_sql( $sql, $bind ) .
					" did not cause an insert"
				       );
    }
}

sub do {
    my ( $pkg, $sql, $bindref, %args ) = @_;
    my ( $self, $bind, $attr, $alt_error ) = $pkg->_explode( $bindref, \%args );
    my $conn = $self->_get_cur_conn();

    $self->_start_timer();

    my $res;
    try eval {
	$res = $conn->{dbh}->do( $sql, $attr, @$bind );
    };
    if ( catch my $e ) {
	$e->rethrow;
    }

    $self->_debug_sql( 4, $sql, $bind, \%args );

    if ( $res eq '0E0' ) {
	return 0;
    }
    return $res;
}

# allow diconnection before DESTROY is called
sub disconnect_all {
    my ( $pkg ) = @_;
    my $self = $pkg->connect('default');
    foreach my $conn ( keys %{ $self->{connections} } ) {
	if ( exists( $self->{connections}->{ $conn }->{dbh} ) ) {
	    $self->{connections}->{ $conn }->{dbh}->disconnect();
	}
    }
}

# Transaction support
sub begin_work {
    my ( $self ) = @_;
    $self->begin();
}

sub begin {
    my ( $self ) = @_;
    my $conn = $self->_get_cur_conn();
    $conn->{dbh}->{AutoCommit} = 0;
}

sub commit {
    my ( $self ) = @_;
    my $conn = $self->_get_cur_conn();
    $conn->{dbh}->commit;
    $conn->{dbh}->{AutoCommit} = 1;
}

sub abort {
    my ( $self ) = @_;
    $self->rollback();
}

sub rollback {
    my ( $self ) = @_;
    my $conn = $self->_get_cur_conn();
    try eval {
	$conn->{dbh}->rollback;
    };
    catch my $e;
    $conn->{dbh}->{AutoCommit} = 1;
    if ( $e ) {
        $e->rethrow;
    }
}

sub as_string {
    my ( $pkg, $sql, $bind ) = @_;
    return Activator::DB->_get_sql( $sql, $bind );
}

sub _start_timer {
    my ( $self ) = @_;
    $self->{debug_timer} = [gettimeofday];
}

sub _debug_sql {
    my ( $self, $depth, $sql, $bind, $args ) = @_;

    if ( $sql =~ /foo/ ) {
	warn Dumper( $args );
    }
    my $conn = $self->_get_cur_conn();
    if ( $args->{debug} ||
	 $self->{config}->{debug} ||
	 $conn->{config}->{debug} ) {
	local $Log::Log4perl::caller_depth;
	$Log::Log4perl::caller_depth += $depth;
	my $str = $self->_get_sql( $sql, $bind );
	DEBUG( tv_interval( $self->{debug_timer}, [ gettimeofday ] ). " $str".
	       ( $self->{config}->{debug_attr} ? "\n\t" .
	       Data::Dumper->Dump( [ $conn->{attr} ], [ 'attr' ] ) : '' )
	     );
    }
}

sub _debug_connection {
    my ( $self, $depth, $msg, $args ) = @_;
    if ( $self->{config}->{debug_connection} ) {
	local $Log::Log4perl::caller_depth;
	$Log::Log4perl::caller_depth += $depth;
	DEBUG( $msg );
    }
}

sub _debug {
    my ( $self, $depth, $msg ) = @_;
    if ( $self->{config}->{debug} ) {
	local $Log::Log4perl::caller_depth;
	$Log::Log4perl::caller_depth += $depth;
	DEBUG( $msg );
    }
}

sub begin_debug {
    my ( $self ) = @_;
    $self->{config}->{debug} = 1;
}

sub end_debug {
    my ( $self ) = @_;
    $self->{config}->{debug} = 0;
}

=head1 NAME

Activator::DB - Wrap DBI with convenience subroutines and consistant
access accross all programs in a project.

=head1 Synopsis

  use Activator::DB;
  my $db = Activator::DB->connect('default'); # connect to default db

=over

=item *

Get a single row:

    my @row     = $db->getrow( $sql, $bind, @args );
    my $rowref  = $db->getrow_arrayref( $sql, $bind, @args );

=item *

Get hashref of col->value pairs:

    my $hashref = $db->getrow_hashref( $sql, $bind, @args );

=item *

Get all rows arrayref (these are identical):

    my $rowsref = $db->getall( $sql, $bind, @args );
    my $rowsref = $db->getall_arrayrefs( $sql, $bind, @args );

=item *

Get all rows ref: with each row a hashref of cols->value pairs:

    my $rowsref = $db->getall_hashrefs( $sql, $bind, @args );

=item *

C<do> any query ( usually INSERT, DELETE, UPDATE ):

    my $id = $db->do( $sql, $bind, @args );

=item *

C<do> query, but return id instead of success.:

    my $id = $db->do_id( $sql, $bind, @args );
   ( NOTE: this is very mysql dependant at the moment)

=item *

Get data from a different db for a while:

    $db->connect('alt'); # connect to alternate db
    # do something

    $db->connect('def'); # reset to default connection
    # do something else

=item *

Transactions (NOT YET IMPLEMENTED)::

    my $altdb = Activator::DB->connect('altdb');
    $db->begin_work();
    $db->do( @stuff );
    $db->do( @more_stuff );
    $db->commit();

=back

=head1 DESCRIPTION

C<Activator::DB> module provides convenience and total consistency to
accessing a database throughout a project. The idea is to reduce
typing for the common cases, and remove worrying about connections.
This module is a wrapper for DBI providing these advantages:

=over

=item *

Provides connect string aliases centrally configured.

=item *

Provide consistent arguments handling to all query functions.

=item *

Provides connection caching without Apache::DBI -- this allows use of
your model layer code in crons, daemons AND website.

=item *

Connection and query debug dumps using your project or module level
C<Activator::Log> config, or on a per-query basis.

=item *

Allows all code in your project/team/company to access the db in a
consistent fashion.

=item *

By default, dies on all errors enforcing try/catch programming

=item *

Implemented as a singleton so each process is guranteed to be using no
more than one connection to each database from the pool.

=back

Disadvantages:

=over

=item *

If you know DBI, you don't necessarily know C<Activator::DB>

=item *

NOT THREAD SAFE

=item *

Only tested with MySql and PostgreSQL

=back

=head1 CONFIGURATION

This module uses L<Activator::Registry> to automatically choose default
databases, and L<Activator::Log> to log warnings and errors.

=head2 Registry Setup (from Activator::Registry)

This module expects an environment variable ACT_REG_YAML_FILE to be
set. If you are utilizing this module from apache, this directive must
be in your httpd configuration:

  SetEnv ACT_REG_YAML_FILE '/path/to/config.yml'

If you are using this module from a script, you need to insure that
the environment is properly set using a BEGIN block:

  BEGIN{
      $ENV{ACT_REG_YAML_FILE} ||= '/path/to/config.yml'
  }

=head2 Registry Configuration

Add an C<Activator::DB> section to your project YAML configuration file:

 'Activator::Registry':
    log4perl<.conf>:         # Log4perl config file or definition
                             # See Logging Configuration below
   'Activator::DB':
     default:                # default configuration for all connections
       connection: <conn_alias>

   ## Optional default attributes and config for all connections
       config:
         debug:      0/1     # default: 0, affects all queries, all aliases
         reconn_att: <int>   # attempt reconnects this many times. default: 3
         reconn_sleep: <int> # initial sleep seconds between reconnect attempts.
                             # doubles every attempt. default: 1
       attr:                 # connection attributes. Only AutoCommit at this time
         AutoCommit: 0/1     # default: 1

   ## You must define at least one connection alias
     connections:
       <conn_alias>:
         user: <user>
         pass: <password>
         dsn: '<DSN>' # MySql Example: DBI:mysql:<DBNAME>:<DBHOST>
                      # PostgreSQL Example: DBI:Pg:dbname=<DBNAME>
                      # see: perldoc DBI, perldoc DBD::Pg, perldoc DBD::mysql
                      # for descriptions of valid DSNs

   ## These attributes and config are all optional, and use the default from above
         attr:
           AutoCommit: 0/1
         config:
            debug:     0/1   # only affects this connection


=head1 USAGE

This module can be used either pseudo-OO or static on multiple
databases. I say pseudo-OO, because you don't call new: this module
auto-vivicates a singleton object whenever you connect for the first
time.

=over

=item ## pseudo-OO example:

  my $db = Activator::DB->connect( 'db_alias' );
  $db->query_method( $sql, $bind, @args );
  $db->connect( 'alt_db_alias' );
  $db->query_method( $sql, $bind, @args );
  $db->connect( 'db_alias' );
  $db->query_method( $sql, $bind, @args );

=item ## Static formatted calls require that you dictate the connection for
every request. So, the above can also be done as:

  Activator::DB->query_method( $sql, $bind, connect => 'db_alias', @args );
  Activator::DB->query_method( $sql, $bind, connect => 'alt_db_alias', @args );
  Activator::DB->query_method( $sql, $bind, connect => 'db_alias', @args );

=item ## However, the common use case for this module is:

  my $db = Activator::DB->connect( 'db_alias' );
  $db->query_method( $sql, $bind, @args );
    ### do some perl
  $db->query_method( $sql, $bind, @args );
    ### do some perl
  $db->query_method( $sql, $bind, @args );
    ### do some perl
  ... etc.

=back

=head2 connect() Usage

  my $db = Activator::DB->connect('my_db');   # connect to my_db
  my $db->connect('default'); # connect to default db
  my $db->connect('def');     # shortcut to default db
  my $db->connect();          # shortercut to default db

=head2 connect() Caveat

Note that C<connect()> always returns the singleton object, which in some
usage patterns could cause some confusion:

  my $db1->connect('db1');           # connect to db1
  $db1->query( $sql, $bind, @args ); # acts on db1
  my $db2->connect('db2');           # connect to db2
  $db2->query( $sql, $bind, @args ); # acts on db2
  $db1->query( $sql, $bind, @args ); # still acts on db2!

For this reason, it is highly recommended that you always use the same
variable name (probably C<$db>) for the Activator::DB object.

=head2 Query Methods Usage

Every query function takes named arguments in the format of:

  Activator::DB->$query_method( $sql, $bind, opt_arg => <opt_value> );

Mandatory Arguments:

 sql   : sql statement string
 bind  : bind values arrayref

Optional Arguments:
 conn  => alias of the db connection (default is 'default')
          NOTE: this changes the connection alias for all future queries
 attr  => hashref of attributes to use for ONLY THIS QUERY
          Supported: AutoCommit
 debug => pretty print sql debugging lines

 # NOT YET SUPPORTED
 slice     => possible future support for DBI::getall_hashref
 max_rows  => possible future support for DBI::getall_hashref

Examples:

=over

=item ## Simple query:

    my @row = $db->getrow( $sql );

=item ## Needy query:

    my $res = $db->do( $sql, $bind,
          connect => 'altdb', # changes the alias for future connections!
          attr => { AutoCommit => 0, },
          debug => 1,
     );

=back

=head2 Query Failures & Errors

All query methods die on failure, and must be wrapped in a try/catch block.

  eval {
    Activator::DB->query_method( $sql, $bind, @args );
  };
  if ($@) {
    # catch the error
  }

We highly recommend (and use extensively)
L<Exception::Class::TryCatch> which allows this syntactic sugar:

  try eval {
    Activator::DB->query_method( $sql, $bind, @args );
  };
  if ( catch my $e ) {
     # rethrow, throw a new error, print something, AKA: handle it!
  }

Errors Thrown:

  connection failure         - could not connect to database
  sql missing                - query sub called without 'sql=>' argument
  connect missing            - static call without 'connect=>' argument
  prepare failure            - failure to $dbh->prepare
  execute failure            - failure to $dbh->execute
  alias_config missing       - connection alias has no configuration
  activator_db error         - sub _warn_or_die() died without error args passed in
  fetch failure              - $sth->fetch* call failed
  do failure                 - $dbh->do call failed

=head1 METHODS

=head2 getrow

=head2 getrow_arrayref

=head2 getrow_hashref

Prepare and Execute a SQL statement and get a the result of values
back via DBI::fetchrow_array(), DBI::fetchrow_arrayref(),
DBI::fetchrow_hashref() respectively. NOTE: Unlike DBI, these return
empty array/arrayref/hashref (like DBI::fetchall_arrayref does,
instead of undef) when there are no results.

Usage:

  my @row     = $db->getrow( $sql, $bind, @args )
  my $rowref  = $db->getrow_arrayref( $sql, $bind, @args )
  my $hashref = $db->getrow_hashref( $sql, $bind, @args )

=head2 getall

=head2 getall_arrayrefs

=head2 getall_hashrefs

Prepare and Execute a SQL statement, and return a reference to the
result obtained by DBI::fetchall_arrayref(). Returns an empty arrayref
if no rows returned for the query.

=over

=item *

C<getall()> is an alias for C<getall_arrayrefs()> and they both return an
arrayref of arrayrefs, one arrayref of values for each row of data
from the query.

  $rowrefs is [ [ row1_col1_val, row1_col2_val ],
                [ row2_col1_val, row2_col2_val ],
              ];

=item *

C<getall_hashrefs()> returns an arrayref of of rows represented by
hashrefs of column name => value mappings.

  $rowrefs is [ { col1 => val, col2 => val },
                { col1 => val, col2 => val },
              ];

=back

  my $rowref = $db->getall( $sql, $bind, @args )
  my $rowref = $db->getall_arrayrefs( $sql, $bind, @args )
  my $rowref = $db->getall_hashrefs( $sql, $bind, @args )

=head2 do

Execute a SQL statement and return the number of rows affected. Dies
on failure.

Usage:

  my $res = $db->do( $sql, $bind, @args )

=head2 do_id

Execute a SQL statement that generates an id and return the id. Dies
on failure.

Usage:

  my $id = $db->do_id( $sql, $bind, @args )

=cut

1;

=head1 SEE ALSO

L<DBI>, L<Activator::Registry>, L<Activator::Log>, L<Activator::Exception>, L<Exception::Class::DBI>, L<Class::StrongSingleton>, L<Exception::Class::TryCatch>

=head1 AUTHOR

Karim A. Nassar

=head1 COPYRIGHT

Copyright (c) 2007 Karim A. Nassar <karim.nassar@acm.org>

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut

__END__

################################################################################
## begin legacy

## =item B<getcol_arrayref>($sql, $bind, $colsref)
##
## Prepare and Execute a SQL statement on the default database, and
## get an arrayref of values back via DBI::selectcol_arrayref()
##
## Args:
##   $sql => sql statement
##   $bind => optional bind values arrayref for the sql statement
##   $colsref => optional arrayref containing the columns to return
##
## Returns:
##   an arrayref of values for each specified col of data from the query (default is the first column).  So each row of data from the query gives one or more sequential values in the output arrayref.
##   reference to an empty array when there is no matching data
##
##
## Usage example
##   my $ary_ref = getcol_arrayref("select id, name from table",{Columns=>[1,2]});
##   my %hash = @$ary_ref; # now $hash{$id} => $name
##
##   # to just get an arrayref of id values
##   my $ary_ref = getcol_arrayref("select id, name from table");
##
## Throws
##   connect.failure - on connect failure
##   dbi.failure - on failure of DBI::selectcol_arrayref
##
## =cut
##
## sub getcol_arrayref {
##     my ( $sql, $bind, $colsref ) = @_;
##
##     $self->{debug_start} = [ gettimeofday ];
##
##     my $colref;
##
##     my $dbh = &get_dbh();    # may throw connect.failure
##
##     eval {
## 	$colref
## 	    = $dbh->selectcol_arrayref( $sql, { Columns => $colsref },
## 	    @$bind );
##     };
##     if ( $@ ) {
## 	Activator::Exception::DB->throw( 'dbi', 'failure', $dbh->errstr || $@);
##     }
##
##     $self->_get_query_debug( 'getcol_arrayref', @_ );
##
##     return $colref;
## }
##
## =item B<getall_hr>($sql, $bind, $key_field)
##
## Prepare and Execute a SQL statement on the default database, and
## call DBI::fetchall_hashref(),
## returning a reference to a hash containing one hashref for each row.
##
## Args:
##   $sql => sql statement
##   $bind => optional bind values arrayref for the sql statement
##   $key_field => column name, column number or arrayref of colunm names/numbers
##                 column number starts at 1
## Returns:
##   a hashref of where each hash entry represents a row of data from the query.
##   The keys for the hash are the values in $key_field.
##   The values in the hash are hashrefs representing the rows in the form
##   returned by fetchrow_hashref.
##   Subsequent rows with the same key will replace previous ones.
##
##   Reference to an empty hash when there is no matching data
##
## Usage example
##   # for table with (id,name) values: ('goog', 'google'), (yhoo, 'yahoo')
##   my $hashref = getall_arrayrefs("select id, name from table",[], 'id'});
##   # $hashref = {
##   #             {goog} => {id=>'goog', name=>'google'},
##   #             {yhoo} => {id=>'yhoo', name=>'yahoo'}
##   #            }
##   my $hashref = getall_arrayrefs("select id, name from table",[]}, 2);
##   # $hashref = {
##   #             {google} => {id=>'goog', name=>'google'},
##   #             {yahoo}  => {id=>'yhoo', name=>'yahoo'}
##   #            }
##
## Throws
##   connect.failure - failure to connect to database
##   prepare.failure - failure to prepare a query for database
##   execute.failure - failure to execute a query on database
##   sth.failure - failure on fetch
##
## =cut
##
## sub getall_hr {
##     my ( $sql, $bind, $key_field ) = @_;
##
##     $self->{debug_start} = [ gettimeofday ];
##
##     my $sth = &_get_sth( $sql, $bind );
##
##     my $rv = $sth->fetchall_hashref( $key_field );
##
##     $sth->finish();
##
##     $self->_get_query_debug( 'getall_hr', @_ );
##
##     return $rv;
## }
