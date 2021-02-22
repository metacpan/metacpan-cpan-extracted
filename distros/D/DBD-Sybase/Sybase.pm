# -*-Perl-*-
# $Id: Sybase.pm,v 1.119 2017/09/10 14:31:45 mpeppler Exp $

# Copyright (c) 1996-2011   Michael Peppler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
# Based on DBD::Oracle Copyright (c) 1994,1995,1996,1997 Tim Bunce

{

  package DBD::Sybase;

  use DBI        ();
  use DynaLoader ();
  use Exporter   ();

  use Sys::Hostname ();

  @ISA = qw(DynaLoader Exporter);

  @EXPORT = qw(CS_ROW_RESULT CS_CURSOR_RESULT CS_PARAM_RESULT
    CS_STATUS_RESULT CS_MSG_RESULT CS_COMPUTE_RESULT);

  $hostname  = Sys::Hostname::hostname();
  $init_done = 0;
  $VERSION   = '1.17';
  
  require_version DBI 1.30;

  # dl_open() calls need to use the RTLD_GLOBAL flag if
  # you are going to use the Kerberos libraries.
  # There are systems / OSes where this does not work (AIX 5.x, for example)
  # set to 1 to get RTLD_GLOBAL turned on.
  sub dl_load_flags { 0x00 }

  bootstrap DBD::Sybase $VERSION;

  $drh = undef;    # holds driver handle once initialised

  sub driver {
    return $drh if $drh;
    my ( $class, $attr ) = @_;
    $class .= "::dr";
    ($drh) = DBI::_new_drh(
      $class,
      {
        'Name'        => 'Sybase',
        'Version'     => $VERSION,
        'Attribution' => 'Sybase DBD by Michael Peppler',
      }
    );

    if ( $DBI::VERSION >= 1.37 && !$DBD::Sybase::init_done ) {
      DBD::Sybase::db->install_method('syb_nsql');
      DBD::Sybase::db->install_method('syb_date_fmt');
      DBD::Sybase::db->install_method('syb_isdead');
      DBD::Sybase::st->install_method('syb_ct_get_data');
      DBD::Sybase::st->install_method('syb_ct_data_info');
      DBD::Sybase::st->install_method('syb_ct_send_data');
      DBD::Sybase::st->install_method('syb_ct_prepare_send');
      DBD::Sybase::st->install_method('syb_ct_finish_send');
      DBD::Sybase::st->install_method('syb_output_params');
      DBD::Sybase::st->install_method('syb_describe');
      ++$DBD::Sybase::init_done;
    }

    $drh;
  }

  sub CLONE {
    undef $drh;
  }

  1;
}

{

  package DBD::Sybase::dr;    # ====== DRIVER ======
  use strict;

  sub connect {
    my ( $drh, $dbase, $user, $auth, $attr ) = @_;
    my $server = $dbase || $ENV{DSQUERY} || 'SYBASE';

    my ($this) = DBI::_new_dbh(
      $drh,
      {
        'Name'         => $server,
        'Username'     => $user,
        'CURRENT_USER' => $user,
      }
    );

    DBD::Sybase::db::_login( $this, $server, $user, $auth, $attr )
      or return undef;

    return $this;
  }

  sub data_sources {
    my @s;
    if ( $^O eq 'MSWin32' ) {
      open( INTERFACES, "$ENV{SYBASE}/ini/sql.ini" ) or return;
      @s = map { /\[(\S+)\]/i; "dbi:Sybase:server=$1" } grep /\[/i,
        <INTERFACES>;
      close(INTERFACES);
    } else {
      open( INTERFACES, "$ENV{SYBASE}/interfaces" ) or return;
      @s = map { /^(\S+)/i; "dbi:Sybase:server=$1" } grep /^[^\s\#]/i,
        <INTERFACES>;
      close(INTERFACES);
    }

    return @s;
  }
}

{

  package DBD::Sybase::db;    # ====== DATABASE ======
  use strict;

  use DBI qw(:sql_types);
  use Carp;

  sub prepare {
    my ( $dbh, $statement, @attribs ) = @_;

    # create a 'blank' sth

    my $sth = DBI::_new_sth( $dbh, { 'Statement' => $statement, } );

    DBD::Sybase::st::_prepare( $sth, $statement, @attribs )
      or return undef;

    $sth;
  }

  sub tables {
    my $dbh     = shift;
    my $catalog = shift;
    my $schema  = shift || '%';
    my $table   = shift || '%';
    my $type    = shift || '%';
    $type =~ s/[\'\"\s]//g;    # strip quotes and spaces
    if ( $type =~ /,/ ) {      # multiple types
      $type =
        '[' . join( '', map { substr( $_, 0, 1 ) } split /,/, $type ) . ']';
    } else {
      $type = substr( $type, 0, 1 );
    }
    $type =~ s/T/U/;

    my $sth;
    if ( $catalog and $catalog ne '%' ) {
      $sth =
        $dbh->prepare(
"select o.name from $catalog..sysobjects o, $catalog..sysusers u where o.type like '$type' and o.name like '$table' and o.uid = u.uid and u.name like '$schema'"
        );
    } else {
      $sth =
        $dbh->prepare(
"select o.name from sysobjects o, sysusers u where o.type like '$type' and o.name like '$table' and o.uid = u.uid and u.name like '$schema'"
        );
    }

    $sth->execute;
    my @names;
    my $dat;
    while ( $dat = $sth->fetch ) {
      push( @names, $dat->[0] );
    }
    @names;
  }

  # NOTE - RaiseError & PrintError is turned off while we are inside this
  # function, so we must check for any error, and return immediately if
  # any error is found.
  # XXX add optional deadlock detection?
  sub do {
    my ( $dbh, $statement, $attr, @params ) = @_;

    my $sth = $dbh->prepare( $statement, $attr ) or return undef;
    $sth->execute(@params)                       or return undef;
    return undef if $sth->err;
    if ( defined( $sth->{syb_more_results} ) ) {
      {
        while ( my $dat = $sth->fetch ) {
          return undef if $sth->err;

          # XXX do something intelligent here...
        }
        redo if $sth->{syb_more_results};
      }
    }
    my $rows = $sth->rows;

    ( $rows == 0 ) ? "0E0" : $rows;
  }

  # This will only work if the statement handle used to do the insert
  # has been properly freed. Otherwise this will try to fetch @@identity
  # from a different (new!) connection - which is obviously wrong.
  sub last_insert_id {
    my ( $dbh, $catalog, $schema, $table, $field, $attr ) = @_;

    # parameters are ignored.

    my $sth = $dbh->prepare('select @@identity');
    if ( !$sth->execute ) {
      return undef;
    }
    my $value;
    ($value) = $sth->fetchrow_array;
    $sth->finish;

    return $value;
  }

  sub table_info {
    my $dbh     = shift;
    my $catalog = $dbh->quote(shift);
    my $schema  = $dbh->quote(shift);
    my $table   = $dbh->quote(shift);
    my $type    = $dbh->quote(shift);

    # https://github.com/mpeppler/DBD-Sybase/issues/53
    # sp_tables is broken in ASE 15 and later...
    #my $sth = $dbh->prepare("sp_tables $table, $schema, $catalog, $type");
 
    my $sth = $dbh->prepare( q{
          select TABLE_QUALIFIER = db_name()
               , TABLE_OWNER     = u.name
               , TABLE_NAME      = o.name
               , TABLE_TYPE      =
                   case o.type
                       when "U" then "TABLE"
                       when "V" then "VIEW"
                       when "S" then "SYSTEM TABLE"
                   end
               , REMARKS         = NULL
            from sysobjects o
              join sysusers   u
                on u.uid = o.uid
           where o.type in ('U', 'V', 'S')
                  and o.id > 99
             });
 
    $sth->execute;
    $sth;
  }

  {

    my $names = [
      qw(TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME DATA_TYPE
        TYPE_NAME COLUMN_SIZE BUFFER_LENGTH DECIMAL_DIGITS
        NUM_PREC_RADIX NULLABLE REMARKS COLUMN_DEF SQL_DATA_TYPE
        SQL_DATETIME_SUB CHAR_OCTET_LENGTH ORDINAL_POSITION
        IS_NULLABLE
      )
    ];

    # Technique of using DBD::Sponge borrowed from DBD::mysql...
    sub column_info {
      my $dbh     = shift;
      my $catalog = $dbh->quote(shift);
      my $schema  = $dbh->quote(shift);
      my $table   = $dbh->quote(shift);
      my $column  = $dbh->quote(shift);

      my $sth = $dbh->prepare("sp_columns $table, $schema, $catalog, $column");
      return undef unless $sth;

      if ( !$sth->execute() ) {
        return DBI::set_err( $dbh, $sth->err(), $sth->errstr() );
      }
      my @cols;
      while ( my $d = $sth->fetchrow_arrayref() ) {
        push( @cols, [ @$d[ 0 .. 11 ], @$d[ 14 .. 19 ] ] );
      }
      my $dbh2;
      if ( !( $dbh2 = $dbh->{'~dbd_driver~_sponge_dbh'} ) ) {
        $dbh2 = $dbh->{'~dbd_driver~_sponge_dbh'} = DBI->connect("DBI:Sponge:");
        if ( !$dbh2 ) {
          DBI::set_err( $dbh, 1, $DBI::errstr );
          return undef;
        }
      }
      my $sth2 = $dbh2->prepare(
        "SHOW COLUMNS",
        {
          'rows'          => \@cols,
          'NAME'          => $names,
          'NUM_OF_FIELDS' => scalar(@$names)
        }
      );
      if ( !$sth2 ) {
        DBI::set_err( $sth2, $dbh2->err(), $dbh2->errstr() );
      }
      $sth2->execute;
      $sth2;
    }
  }

  sub primary_key_info {
    my $dbh     = shift;
    my $catalog = $dbh->quote(shift);    # == database in Sybase terms
    my $schema  = $dbh->quote(shift);    # == owner in Sybase terms
    my $table   = $dbh->quote(shift);

    my $sth = $dbh->prepare("sp_pkeys $table, $schema, $catalog");

    $sth->execute;
    $sth;
  }

  sub foreign_key_info {
    my $dbh        = shift;
    my $pk_catalog = $dbh->quote(shift);    # == database in Sybase terms
    my $pk_schema  = $dbh->quote(shift);    # == owner in Sybase terms
    my $pk_table   = $dbh->quote(shift);
    my $fk_catalog = $dbh->quote(shift);    # == database in Sybase terms
    my $fk_schema  = $dbh->quote(shift);    # == owner in Sybase terms
    my $fk_table   = $dbh->quote(shift);

    my $sth =
      $dbh->prepare(
"sp_fkeys $pk_table, $pk_schema, $pk_catalog, $fk_table, $fk_schema, $fk_catalog"
      );

    $sth->execute;
    $sth;
  }

  sub statistics_info {
    my $dbh       = shift;
    my $catalog   = $dbh->quote(shift);    # == database in Sybase terms
    my $schema    = $dbh->quote(shift);    # == owner in Sybase terms
    my $table     = $dbh->quote(shift);
    my $is_unique = shift;
    my $quick     = shift;

    my $sth =
      $dbh->prepare(
      "sp_indexes \@\@servername, $table, $schema, $catalog, NULL, $is_unique");

    $sth->execute;
    $sth;
  }

  sub ping_pl {    # old code - now implemented by syb_ping() in dbdimp.c
    my $dbh = shift;
    return 0 if DBD::Sybase::db::_isdead($dbh);

    # Use "select 1" suggested by Henri Asseily.
    my $sth = $dbh->prepare("select 1");

    return 0 if !$sth;

    my $rc = $sth->execute;

    # Changed && to || for 1.07.
    return 0 if ( !defined($rc) || DBD::Sybase::db::_isdead($dbh) );

    $sth->finish;
    return 1;
  }

  # Allows us to cache this data as it is static.
  my @type_info;

  sub type_info_all {
    my ($dbh) = @_;

    if(scalar(@type_info) > 0) {
      return \@type_info;
    }

   # Calling sp_datatype_info returns the appropriate data for the server that
   # we are currently connected to.
   # In general the data is static, so it's not really necessary, but ASE 12.5
   # introduces some changes, in particular char/varchar max lenghts that depend
   # on the server's page size. 12.5.1 introduces the DATE and TIME datatypes.
    my $sth = $dbh->prepare("sp_datatype_info");
    my $data;
    if ( $sth->execute ) {
      $data = $sth->fetchall_arrayref;
    }
    my $ti = [
      {
        TYPE_NAME          => 0,
        DATA_TYPE          => 1,
        PRECISION          => 2,
        LITERAL_PREFIX     => 3,
        LITERAL_SUFFIX     => 4,
        CREATE_PARAMS      => 5,
        NULLABLE           => 6,
        CASE_SENSITIVE     => 7,
        SEARCHABLE         => 8,
        UNSIGNED_ATTRIBUTE => 9,
        MONEY              => 10,
        AUTO_INCREMENT     => 11,
        LOCAL_TYPE_NAME    => 12,
        MINIMUM_SCALE      => 13,
        MAXIMUM_SCALE      => 14,
        sql_data_type      => 15,
        sql_datetime_sub   => 16,
        num_prec_radix     => 17,
        interval_precision => 18,
        USERTYPE           => 19
      },
    ];

    # ASE 11.x only returns 13 columns, MS-SQL return 20...
    my $columnCount = @{ $data->[0] };
    foreach my $columnName ( keys( %{ $ti->[0] } ) ) {
      if ( $ti->[0]->{$columnName} >= $columnCount ) {
        delete( $ti->[0]->{$columnName} );
      }
    }
    push( @$ti, @$data );

    foreach (@$ti) {
      push(@type_info, $_);
    }
    return \@type_info;
  }

  # First straight port of DBlib::nsql.
  # mpeppler, 2/19/01
  # Updated by Merijn Broeren 4/17/2007
  # This version *can* handle ? placeholders
  sub nsql {
    my ( $dbh, $sql, $type, $callback, $option ) = @_;
    my ( @res, %resbytype );
    my $retrycount   = $dbh->FETCH('syb_deadlock_retry');
    my $retrysleep   = $dbh->FETCH('syb_deadlock_sleep') || 60;
    my $retryverbose = $dbh->FETCH('syb_deadlock_verbose');
    my $nostatus     = $dbh->FETCH('syb_nsql_nostatus');

    $option = $callback if ref($callback) eq 'HASH' and ref($option) ne 'HASH';
    my $bytype = $option->{bytype} || 0;
    my $merge  = $bytype eq 'merge';

    my @default_types = (
      DBD::Sybase::CS_ROW_RESULT(),   DBD::Sybase::CS_CURSOR_RESULT(),
      DBD::Sybase::CS_PARAM_RESULT(), DBD::Sybase::CS_MSG_RESULT(),
      DBD::Sybase::CS_COMPUTE_RESULT()
    );
    my $oktypes = $option->{oktypes}
      || (
      $nostatus
      ? [@default_types]
      : [ @default_types, DBD::Sybase::CS_STATUS_RESULT() ]
      );
    my %oktypes = map { ( $_ => 1 ) } @$oktypes;

    my @params = $option->{arglist} ? @{ $option->{arglist} } : ();

    if ( ref $type ) {
      $type = ref $type;
    } elsif ( not defined $type ) {
      $type = "";
    }

    my $sth = $dbh->prepare($sql);
    return unless $sth;

    my $raiserror = $dbh->FETCH('RaiseError');

    my $errstr;
    my $err;

    # Rats - RaiseError doesn't seem to work inside of this routine.
    # So we fake it with lots of die() statements.
    #	$sth->{RaiseError} = 1;

  DEADLOCK:
    {

      # Initialize $err before each iteration through this loop.
      # Otherwise, we inherit the value from the previous failure.

      $err = undef;

      # ditto for @res, %resbytype
      @res       = ();
      %resbytype = ();

      # Use RaiseError technique to throw a fatal error if anything goes
      # wrong in the execute or fetch phase.
      eval {
        $sth->execute(@params) || die $sth->errstr;
        {
          my $result_type = $sth->{syb_result_type};
          my ( @set, $data );
          if ( not exists $oktypes{$result_type} ) {
            while ( $data = $sth->fetchrow_arrayref ) {
              ;    # do not include return status rows..
            }
          } elsif ( $type eq "HASH" ) {
            while ( $data = $sth->fetchrow_hashref ) {
              die $sth->errstr if ( $sth->err );
              if ( ref $callback eq "CODE" ) {
                unless ( $callback->(%$data) ) {
                  return;
                }
              } else {
                push( @set, {%$data} );
              }
            }
          } elsif ( $type eq "ARRAY" ) {
            while ( $data = $sth->fetchrow_arrayref ) {
              die $sth->errstr if ( $sth->err );
              if ( ref $callback eq "CODE" ) {
                unless ( $callback->(@$data) ) {
                  return;
                }
              } else {
                push( @set, ( @$data == 1 ? $$data[0] : [@$data] ) );
              }
            }
          } else {

            # If you ask for nothing, you get nothing.  But suck out
            # the data just in case.
            while ( $data = $sth->fetch ) { 1; }

    # NB this is actually *counting* the result sets which are not ignored above
            $res[0]++;    # Return non-null (true)
          }

          die $sth->errstr if ( $sth->err );

          if (@set) {
            if ($merge) {
              $resbytype{$result_type} ||= [];
              push @{ $resbytype{$result_type} }, @set;
            } elsif ($bytype) {
              push @res, { $result_type => [@set] };
            } else {
              push @res, @set;
            }
          }

          redo if $sth->{syb_more_results};
        }
      };

      # If $@ is set then something failed in the eval{} call above.
      if ($@) {
        $errstr = $@;
        $err    = $sth->err || $dbh->err;
        if ( $retrycount && $err == 1205 ) {
          if ( $retrycount < 0 || $retrycount-- ) {
            carp "SQL deadlock encountered.  Retrying...\n"
              if $retryverbose;
            sleep($retrysleep);
            redo DEADLOCK;
          } else {
            carp "SQL deadlock retry failed ",
              $dbh->FETCH('syb_deadlock_retry'), " times.  Aborting.\n"
              if $retryverbose;
            last DEADLOCK;
          }
        }

        last DEADLOCK;
      }
    }

    #
    # If we picked any sort of error, then don't feed the data back.
    #
    if ($err) {
      if ($raiserror) {
        croak($errstr);
      }
      return;
    } elsif ( ref $callback eq "CODE" ) {
      return 1;
    } else {
      if ($merge) {
        return %resbytype;
      } else {
        return @res;
      }
    }
  }

  if ( $DBI::VERSION >= 1.37 ) {
    *syb_nsql = *nsql;
  }
}

{

  package DBD::Sybase::st;    # ====== STATEMENT ======
  use strict;

  sub syb_output_params {
    my ($sth) = @_;

    my @results;
    my $status;

    {
      while ( my $d = $sth->fetch ) {

        # The tie() doesn't work here, so call the FETCH method
        # directly....
        if ( $sth->FETCH('syb_result_type') == 4042 ) {
          push( @results, @$d );
        } elsif ( $sth->FETCH('syb_result_type') == 4043 ) {
          $status = $d->[0];
        }
      }
      redo if $sth->FETCH('syb_more_results');
    }

    # XXX What to do if $status != 0???

    @results;
  }

  sub exec_proc {
    my ($sth) = @_;

    my @results;
    my $status;

    $sth->execute || return undef;

    {
      while ( my $d = $sth->fetch ) {

        # The tie() doesn't work here, so call the FETCH method
        # directly....
        if ( $sth->FETCH('syb_result_type') == 4043 ) {
          $status = $d->[0];
        }
      }
      redo if $sth->FETCH('syb_more_results');
    }

    # XXX What to do if $status != 0???

    $status;
  }

}

1;

__END__

=head1 NAME

DBD::Sybase - Sybase database driver for the DBI module

=head1 SYNOPSIS

    use DBI;

    $dbh = DBI->connect("dbi:Sybase:", $user, $passwd);

    # See the DBI module documentation for full details

=head1 DESCRIPTION

DBD::Sybase is a Perl module which works with the DBI module to provide
access to Sybase databases.

=head1 Connecting to Sybase

=head2 The interfaces file

The DBD::Sybase module is built on top of the Sybase I<Open Client Client 
Library> API. This library makes use of the Sybase I<interfaces> file
(I<sql.ini> on Win32 machines) to make a link between a logical
server name (e.g. SYBASE) and the physical machine / port number that
the server is running on. The OpenClient library uses the environment
variable B<SYBASE> to find the location of the I<interfaces> file,
as well as other files that it needs (such as locale files). The B<SYBASE>
environment is the path to the Sybase installation (eg '/usr/local/sybase').
If you need to set it in your scripts, then you I<must> set it in a
C<BEGIN{}> block:

   BEGIN {
       $ENV{SYBASE} = '/opt/sybase/11.0.2';
   }

   my $dbh = DBI->connect('dbi:Sybase:', $user, $passwd);


=head2 Specifying the server name

The server that DBD::Sybase connects to defaults to I<SYBASE>, but
can be specified in two ways.

You can set the I<DSQUERY> environement variable:

    $ENV{DSQUERY} = "ENGINEERING";
    $dbh = DBI->connect('dbi:Sybase:', $user, $passwd);

Or you can pass the server name in the first argument to connect():

    $dbh = DBI->connect("dbi:Sybase:server=ENGINEERING", $user, $passwd);

=head2 Specifying other connection specific parameters

It is sometimes necessary (or beneficial) to specify other connection
properties. Currently the following are supported:

=over 4

=item server

Specify the server that we should connect to.

     $dbh = DBI->connect("dbi:Sybase:server=BILLING",
			 $user, $passwd);

The default server is I<SYBASE>, or the value of the I<$DSQUERY> environment
variable, if it is set.

=item host

=item port

If you built DBD::Sybase with OpenClient 12.5.1 or later, then you can
use the I<host> and I<port> values to define the server you want to
connect to. This will by-pass the server name lookup in the interfaces file.
This is useful in the case where the server hasn't been entered in the 
interfaces file.

     $dbh = DBI->connect("dbi:Sybase:host=db1.domain.com;port=4100",
			 $user, $passwd);

=item maxConnect

By default DBD::Sybase (and the underlying OpenClient libraries) is limited
to openening 25 simultaneous connections to one or more database servers.
If you need more than 25 connections at the same time, you can use the
I<maxConnect> option to increase this number.

     $dbh = DBI->connect("dbi:Sybase:maxConnect=100",
			 $user, $passwd);


=item database

Specify the database that should be made the default database.

     $dbh = DBI->connect("dbi:Sybase:database=sybsystemprocs",
			 $user, $passwd);

This is equivalent to 

    $dbh = DBI->connect('dbi:Sybase:', $user, $passwd);
    $dbh->do("use sybsystemprocs");


=item charset

Specify the character set that the client uses.

     $dbh = DBI->connect("dbi:Sybase:charset=iso_1",
			 $user, $passwd);

The default charset used depends on the locale that the application runs
in. If you wish to interact with unicode varaiables (see syb_enable_utf8, below) then
you should set charset=utf8. Note however that this means that Sybase will expect all
data sent to it for char/varchar columns to be encoded in utf8 (e.g. sending iso8859-1 characters
like e-grave, etc).

=item language

Specify the language that the client uses.

     $dbh = DBI->connect("dbi:Sybase:language=us_english",
			 $user, $passwd);

Note that the language has to have been installed on the server (via
langinstall or sp_addlanguage) for this to work. If the language is not
installed the session will default to the default language of the 
server.

=item packetSize

Specify the network packet size that the connection should use. Using a
larger packet size can increase performance for certain types of queries.
See the Sybase documentation on how to enable this feature on the server.

     $dbh = DBI->connect("dbi:Sybase:packetSize=8192",
			 $user, $passwd);

=item interfaces

Specify the location of an alternate I<interfaces> file:

     $dbh = DBI->connect("dbi:Sybase:interfaces=/usr/local/sybase/interfaces",
			 $user, $passwd);

=item loginTimeout

Specify the number of seconds that DBI->connect() will wait for a 
response from the Sybase server. If the server fails to respond before the
specified number of seconds the DBI->connect() call fails with a timeout
error. The default value is 60 seconds, which is usually enough, but on a busy
server it is sometimes necessary to increase this value:

     $dbh = DBI->connect("dbi:Sybase:loginTimeout=240", # wait up to 4 minutes
			 $user, $passwd);


=item timeout

Specify the number of seconds after which any Open Client calls will timeout
the connection and mark it as dead. Once a timeout error has been received
on a connection it should be closed and re-opened for further processing.

Setting this value to 0 or a negative number will result in an unlimited
timeout value. See also the Open Client documentation on CS_TIMEOUT.

     $dbh = DBI->connect("dbi:Sybase:timeout=240", # wait up to 4 minutes
			 $user, $passwd);

=item scriptName

Specify the name for this connection that will be displayed in sp_who
(ie in the sysprocesses table in the I<program_name> column).

    $dbh=DBI->connect("dbi:Sybase:scriptName=myScript", $user, $password);

=item hostname

Specify the hostname that will be displayed by sp_who (and will be stored
in the hostname column of sysprocesses)..

    $dbh=DBI->connect("dbi:Sybase:hostname=kiruna", $user, $password);

=item tdsLevel

Specify the TDS protocol level to use when connecting to the server.
Valid values are CS_TDS_40, CS_TDS_42, CS_TDS_46, CS_TDS_495 and CS_TDS_50.
In general this is automatically negotiated between the client and the 
server, but in certain cases this may need to be forced to a lower level
by the client. 

    $dbh=DBI->connect("dbi:Sybase:tdsLevel=CS_TDS_42", $user, $password);

B<NOTE>: Setting the tdsLevel below CS_TDS_495 will disable a number of
features, ?-style placeholders and CHAINED non-AutoCommit mode, in particular.

=item encryptPassword

Specify the use of the client password encryption supported by CT-Lib.
Specify a value of 1 to use encrypted passwords.

    $dbh=DBI->connect("dbi:Sybase:encryptPassword=1", $user, $password);

=item kerberos

Note: Requires OpenClient 11.1.1 or later.

Sybase and OpenClient can use Kerberos to perform network-based login.
If you use Kerberos for authentication you can use this feature and pass
a kerberos serverprincipal using the C<kerberos=value> parameter:

    $dbh = DBI->connect("dbi:Sybase:kerberos=$serverprincipal", '', '');

In addition, if you have a system for retrieving Kerberos serverprincipals at
run-time you can tell DBD::Sybase to call a perl subroutine to get
the serverprincipal from connect():

    sub sybGetPrinc {
        my $srv = shift;
        return the serverprincipal...
    }
    $dbh = DBI->connect('dbi:Sybase:server=troll', '', '', { syb_kerberos_serverprincipal => \&sybGetPrinc });

The subroutine will be called with one argument (the server that we will
connect to, using the normal Sybase behavior of checking the DSQUERY
environment variable if no server is specified in the connect()) and is
expected to return a string (the Kerberos serverprincipal) to the caller.

=item sslCAFile

Specify the location of an alternate I<trusted.txt> file for SSL
connection negotiation:

  $dbh->DBI->connect("dbi:Sybase:sslCAFile=/usr/local/sybase/trusted.txt.ENGINEERING", $user, $password); 

=item bulkLogin

Set this to 1 if the connection is going to be used for a bulk-load
operation (see I<Experimental Bulk-Load functionality> elsewhere in this
document.)

  $dbh->DBI->connect("dbi:Sybase:bulkLogin=1", $user, $password);

=item serverType

Tell DBD::Sybase what the server type is. Defaults to ASE. Setting it to 
something else will prevent certain actions (such as setting options, 
fetching the ASE version via @@version, etc.) and avoid spurious errors.

=item tds_keepalive

Set this to 1 to tell OpenClient to enable the KEEP_ALIVE attribute on the 
connection. Default 1.

=back

These different parameters (as well as the server name) can be strung
together by separating each entry with a semi-colon:

    $dbh = DBI->connect("dbi:Sybase:server=ENGINEERING;packetSize=8192;language=us_english;charset=iso_1",
			$user, $pwd);

=head1 Handling Multiple Result Sets

Sybase's Transact SQL has the ability to return multiple result sets
from a single SQL statement. For example the query:

    select b.title, b.author, s.amount
      from books b, sales s
     where s.authorID = b.authorID
     order by b.author, b.title
    compute sum(s.amount) by b.author

which lists sales by author and title and also computes the total sales
by author returns two types of rows. The DBI spec doesn't really 
handle this situation, nor the more hairy

    exec my_proc @p1='this', @p2='that', @p3 out

where C<my_proc> could return any number of result sets (ie it could
perform an unknown number of C<select> statements.

I've decided to handle this by returning an empty row at the end
of each result set, and by setting a special Sybase attribute in $sth
which you can check to see if there is more data to be fetched. The 
attribute is B<syb_more_results> which you should check to see if you
need to re-start the C<fetch()> loop.

To make sure all results are fetched, the basic C<fetch> loop can be 
written like this:

     {
         while($d = $sth->fetch) {
            ... do something with the data
         }

         redo if $sth->{syb_more_results};
     }

You can get the type of the current result set with 
$sth->{syb_result_type}. This returns a numerical value, as defined in 
$SYBASE/$SYBASE_OCS/include/cspublic.h:

	#define CS_ROW_RESULT		(CS_INT)4040
	#define CS_CURSOR_RESULT	(CS_INT)4041
	#define CS_PARAM_RESULT		(CS_INT)4042
	#define CS_STATUS_RESULT	(CS_INT)4043
	#define CS_MSG_RESULT		(CS_INT)4044
	#define CS_COMPUTE_RESULT	(CS_INT)4045

In particular, the return status of a stored procedure is returned
as CS_STATUS_RESULT (4043), and is normally the last result set that is 
returned in a stored proc execution, but see the B<syb_do_proc_status> 
attribute for an alternative way of handling this result type. See B<Executing 
Stored Procedures> elsewhere in this document for more information.

If you add a 

    use DBD::Sybase;

to your script then you can use the symbolic values (CS_xxx_RESULT) 
instead of the numeric values in your programs, which should make them 
easier to read.

See also the C<$sth->syb_output_params> call to handle stored procedures 
that B<only> return B<OUTPUT> parameters.

=head1 $sth->execute() failure mode behavior

DBD::Sybase has the ability to handle multi-statement SQL commands
in a single batch. For example, you could insert several rows in 
a single batch like this:

   $sth = $dbh->prepare("
   insert foo(one, two, three) values(1, 2, 3)
   insert foo(one, two, three) values(4, 5, 6)
   insert foo(one, two, three) values(10, 11, 12)
   insert foo(one, two, three) values(11, 12, 13)
   ");
   $sth->execute;

If any one of the above inserts fails for any reason then $sth->execute
will return C<undef>, B<HOWEVER> the inserts that didn't fail will still
be in the database, unless C<AutoCommit> is off.

It's also possible to write a statement like this:

   $sth = $dbh->prepare("
   insert foo(one, two, three) values(1, 2, 3)
   select * from bar
   insert foo(one, two, three) values(10, 11, 12)
   ");
   $sth->execute;

If the second C<insert> is the one that fails, then $sth->execute will
B<NOT> return C<undef>. The error will get flagged after the rows
from C<bar> have been fetched.

I know that this is not as intuitive as it could be, but I am
constrained by the Sybase API here.

As an aside, I know that the example above doesn't really make sense, 
but I need to illustrate this particular sequence... You can also see the 
t/fail.t test script which shows this particular behavior.

=head1 Sybase Specific Attributes

There are a number of handle  attributes that are specific to this driver.
These attributes all start with B<syb_> so as to not clash with any
normal DBI attributes.

=head2 Database Handle Attributes

The following Sybase specific attributes can be set at the Database handle
level:

=over 4

=item syb_show_sql (bool)

If set then the current statement is included in the string returned by 
$dbh->errstr.

=item syb_show_eed (bool)

If set, then extended error information is included in the string returned 
by $dbh->errstr. Extended error information include the index causing a
duplicate insert to fail, for example.

=item syb_err_handler (subroutine ref)

This attribute is used to set an ad-hoc error handler callback (ie a
perl subroutine) that gets called before the normal error handler does
it's job.  If this subroutine returns 0 then the error is
ignored. This is useful for handling PRINT statements in Transact-SQL,
for handling messages from the Backup Server, showplan output, dbcc
output, etc.
 
The subroutine is called with nine parameters:
 
  o the Sybase error number
  o the severity
  o the state
  o the line number in the SQL batch
  o the server name (if available)
  o the stored procedure name (if available)
  o the message text
  o the current SQL command buffer
  o either of the strings "client" (for Client Library errors) or
    "server" (for server errors, such as SQL syntax errors, etc),
    allowing you to identify the error type.
  
As a contrived example, here is a port of the distinct error and
message handlers from the Sybase documentation:
  
  Example:
  
  sub err_handler {
      my($err, $sev, $state, $line, $server,
 	$proc, $msg, $sql, $err_type) = @_;
 
      my @msg = ();
      if($err_type eq 'server') {
 	 push @msg,
 	   ('',
 	    'Server message',
 	    sprintf('Message number: %ld, Severity %ld, State %ld, Line %ld',
 		    $err,$sev,$state,$line),
 	    (defined($server) ? "Server '$server' " : '') .
 	    (defined($proc) ? "Procedure '$proc'" : ''),
 	    "Message String:$msg");
      } else {
 	 push @msg,
 	   ('',
 	    'Open Client Message:',
 	    sprintf('Message number: SEVERITY = (%ld) NUMBER = (%ld)',
 		    $sev, $err),
 	    "Message String: $msg");
      }
      print STDERR join("\n",@msg);
      return 0; ## CS_SUCCEED
  }
 
In a simpler and more focused example, this error handler traps
showplan messages:
 
   %showplan_msgs = map { $_ => 1}  (3612 .. 3615, 6201 .. 6299, 10201 .. 10299);
   sub err_handler {
      my($err, $sev, $state, $line, $server,
 	$proc, $msg, $sql, $err_type) = @_;
  
       if($showplan_msgs{$err}) { # it's a showplan message
  	 print SHOWPLAN "$err - $msg\n";
  	 return 0;    # This is not an error
       }
       return 1;
   }
  
and this is how you would use it:
 
    $dbh = DBI->connect('dbi:Sybase:server=troll', 'sa', '');
    $dbh->{syb_err_handler} = \&err_handler;
    $dbh->do("set showplan on");
    open(SHOWPLAN, ">>/var/tmp/showplan.log") || die "Can't open showplan log: $!";
    $dbh->do("exec someproc");    # get the showplan trace for this proc.
    $dbh->disconnect;

B<NOTE> - if you set the error handler in the DBI->connect() call like this

    $dbh = DBI->connect('dbi:Sybase:server=troll', 'sa', '', 
		    { syb_err_handler => \&err_handler });

then the err_handler() routine will get called if there is an error during
       the connect itself. This is B<new> behavior in DBD::Sybase 0.95.


=item syb_flush_finish (bool)

If $dbh->{syb_flush_finish} is set then $dbh->finish will drain any
results remaining for the current command by actually fetching them.
The default behaviour is to issue a ct_cancel(CS_CANCEL_ALL), but this
I<appears> to cause connections to hang or to fail in certain cases
(although I've never witnessed this myself.)

=item syb_dynamic_supported (bool)

This is a read-only attribute that returns TRUE if the dataserver
you are connected to supports ?-style placeholders. Typically placeholders are
not supported when using DBD::Sybase to connect to a MS-SQL server.

=item syb_chained_txn (bool)

If set then we use CHAINED transactions when AutoCommit is off. 
Otherwise we issue an explicit BEGIN TRAN as needed. The default is on
if it is supported by the server.

This attribute should usually be used only during the connect() call:

    $dbh = DBI->connect('dbi:Sybase:', $user, $pwd, {syb_chained_txn => 1});

Using it at any other time with B<AutoCommit> turned B<off> will 
B<force a commit> on the current handle.

=item syb_quoted_identifier (bool)

If set, then identifiers that would normally clash with Sybase reserved
words can be quoted using C<"identifier">. In this case strings must
be quoted with the single quote.

This attribute can only be set if the database handle is idle (no
active statement handle.)

Default is for this attribute to be B<off>.

=item syb_rowcount (int)

Setting this attribute to non-0 will limit the number of rows returned by
a I<SELECT>, or affected by an I<UPDATE> or I<DELETE> statement to the
I<rowcount> value. Setting it back to 0 clears the limit.

This attribute can only be set if the database handle is idle.

Default is for this attribute to be B<0>.

=item syb_do_proc_status (bool)

Setting this attribute causes $sth->execute() to fetch the return status
of any executed stored procs in the SQL being executed. If the return
status is non-0 then $sth->execute() will report that the operation 
failed. 

B<NOTE> The result status is NOT the first result set that
is fetched from a stored proc execution. If the procedure includes
SELECT statements then these will be fetched first, which means that 
C<$sth->execute> will NOT return a failure in that case as DBD::Sybase
won't have seen the result status yet at that point.

The RaiseError will NOT be triggered by a non-0 return status if 
there isn't an associated error message either generated by Sybase
(duplicate insert error, etc) or generated in the procedure via a T-SQL
C<raiserror> statement.

Setting this attribute does B<NOT> affect existing $sth handles, only
those that are created after setting it. To change the behavior of 
an existing $sth handle use $sth->{syb_do_proc_status}.

The proc status is available in $sth->{syb_proc_status} after all the
result sets in the procedure have been processed.

The default is for this attribute to be B<off>.

=item syb_use_bin_0x

If set, BINARY and VARBINARY values are prefixed with '0x'
in the result. The default is off.

=item syb_binary_images

If set, IMAGE data is returned in raw binary format. Otherwise the data is
converted to a long hex string. The default is off.

=item syb_oc_version (string)

Returns the identification string of the version of Client Library that
this binary is currently using. This is a read-only attribute.

For example:

    troll (7:59AM):348 > perl -MDBI -e '$dbh = DBI->connect("dbi:Sybase:", "sa"); print "$dbh->{syb_oc_version}\n";' 
    Sybase Client-Library/11.1.1/P/Linux Intel/Linux 2.2.5 i586/1/OPT/Mon Jun  7 07:50:21 1999

This is very useful information to have when reporting a problem.

=item syb_server_version

=item syb_server_version_string

These two attributes return the Sybase server version, respectively
version string, and can be used to turn server-specific functionality
on or off.

Example:

    print "$dbh->{syb_server_version}\n$dbh->{syb_server_version_string}\n";

prints

    12.5.2
    Adaptive Server Enterprise/12.5.2/EBF 12061 ESD#2/P/Linux Intel/Enterprise Linux/ase1252/1844/32-bit/OPT/Wed Aug 11 21:36:26 2004

=item syb_failed_db_fatal (bool)

If this is set, then a connect() request where the I<database>
specified doesn't exist or is not accessible will fail. This needs
to be set in the attribute hash passed during the DBI->connect() call
to be effective.

Default: off

=item syb_no_child_con (bool)

If this attribute is set then DBD::Sybase will B<not> allow multiple
simultaneously active statement handles on one database handle (i.e.
multiple $dbh->prepare() calls without completely processing the
results from any existing statement handle). This can be used
to debug situations where incorrect or unexpected results are
found due to the creation of a sub-connection where the connection
attributes (in particular the current database) are different.

Default: off

=item syb_bind_empty_string_as_null (bool)

If this attribute is set then an empty string (i.e. "") passed as
a parameter to an $sth->execute() call will be converted to a NULL
value. If the attribute is not set then an empty string is converted to
a single space.

Default: off

=item syb_cancel_request_on_error (bool)

If this attribute is set then a failure in a multi-statement request
(for example, a stored procedure execution) will cause $sth->execute()
to return failure, and will cause any other results from this request to 
be discarded.

The default value (B<on>) changes the behavior that DBD::Sybase exhibited
up to version 0.94. 

Default: on

=item syb_date_fmt (string)

Defines the date/time conversion string when fetching data. See the 
entry for the C<syb_date_fmt()> method elsewhere in this document for a
description of the available formats.

=item syb_has_blk (bool)

This read-only attribute is set to TRUE if the BLK API is available in
this version of DBD::Sybase. 

=item syb_disconnect_in_child (bool)

Sybase client library allows using opened connections across a fork (i.e. the opened connection 
can be used in the child process). DBI by default will set flags such that this connection will 
be closed when the child process terminates. This is in most cases not what you want. DBI provides
the InactiveDestroy attribute to control this, but you have to set this attribute manually as it
defaults to False (i.e. when DESTROY is called for the handle the connection is closed).
The syb_disconnect_in_child attribute attempts to correct this - the default is for this 
attribute to be False - thereby inhibitting the closing of the connection(s) when 
the current process ID doesn't match the process ID that created the connection.

Default: off

=item syb_enable_utf8 (bool)

If this attribute is set then DBD::Sybase will convert UNIVARCHAR, UNICHAR,
and UNITEXT data to Perl's internal utf-8 encoding when they are
retrieved. Updating a unicode column will cause Sybase to convert any incoming
data from utf-8 to its internal utf-16 encoding.

This feature requires OpenClient 15.x to work.

Default: off

=back

=head2 Statement Handle Attributes

The following read-only attributes are available at the statement level:

=over 4

=item syb_more_results (bool)

See the discussion on handling multiple result sets above.

=item syb_result_type (int)

Returns the numeric result type of the current result set. Useful when 
executing stored procedurs to determine what type of information is
currently fetchable (normal select rows, output parameters, status results,
etc...).

=item syb_do_proc_status (bool)

See above (under Database Handle Attributes) for an explanation.

=item syb_proc_status (read-only)

If syb_do_proc_status is set, then the return status of stored procedures will
be available via $sth->{syb_proc_status}.

=item syb_no_bind_blob (bool)

If set then any IMAGE or TEXT columns in a query are B<NOT> returned
when calling $sth->fetch (or any variation).

Instead, you would use

    $sth->syb_ct_get_data($column, \$data, $size);

to retrieve the IMAGE or TEXT data. If $size is 0 then the entire item is
fetched, otherwis  you can call this in a loop to fetch chunks of data:

    while(1) {
        $sth->syb_ct_get_data($column, \$data, 1024);
	last unless $data;
	print OUT $data;
    }

The fetched data is still subject to Sybase's TEXTSIZE option (see the
SET command in the Sybase reference manual). This can be manipulated with
DBI's B<LongReadLen> attribute, but C<$dbh->{LongReadLen}> I<must> be 
set before $dbh->prepare() is called to take effect (this is a change
in 1.05 - previously you could call it after the prepare() but 
before the execute()). Note that LongReadLen
has no effect when using DBD::Sybase with an MS-SQL server.

B<Note>: The IMAGE or TEXT column that is to be fetched this way I<must> 
be I<last> in the select list.

See also the description of the ct_get_data() API call in the Sybase
OpenClient manual, and the "Working with TEXT/IMAGE columns" section
elsewhere in this document.

=back

=head1 Controlling DATETIME output formats

By default DBD::Sybase will return I<DATETIME> and I<SMALLDATETIME>
columns in the I<Nov 15 1998 11:13AM> format. This can be changed
via a private B<syb_date_fmt()> method.

The syntax is

    $dbh->syb_date_fmt($fmt);

where $fmt is a string representing the format that you want to apply.

Note that this requires DBI 1.37 or later.

The formats are based on Sybase's standard conversion routines. The following
subset of available formats has been implemented:

=over 4

=item LONG

Nov 15 1998 11:30:11:496AM

=item LONGMS

New with ASE 15.5 - for bigtime/bigdatetime datatypes, includes microseconds:

Apr  7 2010 10:40:33.532315PM

=item SHORT

Nov 15 1998 11:30AM

=item DMY4_YYYY

15 Nov 1998

=item MDY1_YYYY

11/15/1998

=item DMY1_YYYY

15/11/1998

=item DMY2_YYYY

15.11.1998

=item YMD3_YYYY

19981115

=item HMS

11:30:11

=item ISO

2004-08-21 14:36:48.080

=item ISO_strict

2004-08-21T14:36:48.080Z

Note that Sybase has no concept of a timezone, so the trailing "Z" is
really not correct (assumes that the time is in UTC). However, there
is no guarantee that the client and the server run in the same timezone,
so assuming the timezone of the client isn't really a valid option
either.

=back

=head1 Retrieving OUTPUT parameters from stored procedures

Sybase lets you pass define B<OUTPUT> parameters to stored procedures,
which are a little like parameters passed by reference in C (or perl.)

In Transact-SQL this is done like this

   declare @id_value int, @id_name char(10)
   exec my_proc @name = 'a string', @number = 1234, @id = @id_value OUTPUT, @out_name = @id_name OUTPUT
   -- Now @id_value and @id_name are set to whatever 'my_proc' set @id and @out_name to


So how can we get at @param using DBD::Sybase? 

If your stored procedure B<only> returns B<OUTPUT> parameters, then you
can use this shorthand:

    $sth = $dbh->prepare('...');
    $sth->execute;
    @results = $sth->syb_output_params();

This will return an array for all the OUTPUT parameters in the proc call,
and will ignore any other results. The array will be undefined if there are 
no OUTPUT params, or if the stored procedure failed for some reason.

The more generic way looks like this:

   $sth = $dbh->prepare("declare \@id_value int, \@id_name
      exec my_proc @name = 'a string', @number = 1234, @id = @id_value OUTPUT, @out_name = @id_name OUTPUT");
   $sth->execute;
   {
      while($d = $sth->fetch) {
         if($sth->{syb_result_type} == 4042) { # it's a PARAM result
            $id_value = $d->[0];
            $id_name  = $d->[1];
         }
      }

      redo if $sth->{syb_more_results};
   }

So the OUTPUT params are returned as one row in a special result set.


=head1 Multiple active statements on one $dbh

It is possible to open multiple active statements on a single database 
handle. This is done by opening a new physical connection in $dbh->prepare()
if there is already an active statement handle for this $dbh.

This feature has been implemented to improve compatibility with other
drivers, but should not be used if you are coding directly to the 
Sybase driver.

The C<syb_no_child_con> attribute controls whether this feature is 
turned on. If it is FALSE (the default), then multiple statement handles are
supported. If it is TRUE then multiple statements on the same database
handle are disabled. Also see below for interaction with AutoCommit.

If AutoCommit is B<OFF> then multiple statement handles on a single $dbh
is B<NOT> supported. This is to avoid various deadlock problems that
can crop up in this situation, and because you will not get real transactional
integrity using multiple statement handles simultaneously as these in 
reality refer to different physical connections.


=head1 Working with IMAGE and TEXT columns

DBD::Sybase can store and retrieve IMAGE or TEXT data (aka "blob" data)
via standard SQL statements. The B<LongReadLen> handle attribute controls
the maximum size of IMAGE or TEXT data being returned for each data 
element.

When using standard SQL the default for IMAGE data is to be converted
to a hex string, but you can use the I<syb_binary_images> handle attribute 
to change this behaviour. Alternatively you can use something like

    $binary = pack("H*", $hex_string);

to do the conversion.

IMAGE and TEXT datatypes can B<not> be passed as parameters using
?-style placeholders, and placeholders can't refer to IMAGE or TEXT 
columns (this is a limitation of the TDS protocol used by Sybase, not
a DBD::Sybase limitation.)

There is an alternative way to access and update IMAGE/TEXT data
using the natice OpenClient API. This is done via $h->func() calls,
and is, unfortunately, a little convoluted.

=head2 Handling IMAGE/TEXT data with syb_ct_get_data()/syb_ct_send_data()

With DBI 1.37 and later you can call all of these ct_xxx() calls directly
as statement handle methods by prefixing them with syb_, so for example

    $sth->func($col, $dataref, $numbytes, 'ct_fetch_data');

becomes

    $sth->syb_ct_fetch_data($col, $dataref, $numbytes);

=over 4

=item $len = ct_fetch_data($col, $dataref, $numbytes)

The ct_get_data() call allows you to fetch IMAGE/TEXT data in
raw format, either in one piece or in chunks. To use this function
you must set the I<syb_no_bind_blob> statement handle to I<TRUE>. 

ct_get_data() takes 3 parameters: The column number (starting at 1)
of the query, a scalar ref and a byte count. If the byte count is 0 
then we read as many bytes as possible.

Note that the IMAGE/TEXT column B<must> be B<last> in the select list
for this to work.

The call sequence is:

    $sth = $dbh->prepare("select id, img from some_table where id = 1");
    $sth->{syb_no_bind_blob} = 1;
    $sth->execute;
    while($d = $sth->fetchrow_arrayref) {
       # The data is in the second column
       $len = $sth->syb_ct_get_data(2, \$img, 0);
       # with DBI 1.33 and earlier, this would be
       # $len = $sth->func(2, \$img, 0, 'ct_get_data');
    }

ct_get_data() returns the number of bytes that were effectively fetched,
so that when fetching chunks you can do something like this:

   while(1) {
      $len = $sth->syb_ct_get_data(2, $imgchunk, 1024);
      ... do something with the $imgchunk ...
      last if $len != 1024;
   }

To explain further: Sybase stores IMAGE/TEXT data separately from 
normal table data, in a chain of pagesize blocks (a Sybase database page
is defined at the server level, and can be 2k, 4k, 8k or 16k in size.) To update an IMAGE/TEXT
column Sybase needs to find the head of this chain, which is known as
the "text pointer". As there is no I<where> clause when the ct_send_data()
API is used we need to retrieve the I<text pointer> for the correct
data item first, which is done via the ct_data_info(CS_GET) call. Subsequent
ct_send_data() calls will then know which data item to update.

=item $status = ct_data_info($action, $column, $attr)

ct_data_info() is used to fetch or update the CS_IODESC structure
for the IMAGE/TEXT data item that you wish to update. $action should be
one of "CS_SET" or "CS_GET", $column is the column number of the
active select statement (ignored for a CS_SET operation) and $attr is
a hash ref used to set the values in the struct.

ct_data_info() must be first called with CS_GET to fetch the CS_IODESC
structure for the IMAGE/TEXT data item that you wish to update. Then 
you must update the value of the I<total_txtlen> structure element
to the length (in bytes) of the IMAGE/TEXT data that you are going to
insert, and optionally set the I<log_on_update> to B<TRUE> to enable full 
logging of the operation.

ct_data_info(CS_GET) will I<fail> if the IMAGE/TEXT data for which the 
CS_IODESC is being fetched is NULL. If you have a NULL value that needs
updating you must first update it to some non-NULL value (for example
an empty string) using standard SQL before you can retrieve the CS_IODESC
entry. This actually makes sense because as long as the data item is NULL
there is B<no> I<text pointer> and no TEXT page chain for that item.

See the ct_send_data() entry below for an example.

=item ct_prepare_send()

ct_prepare_send() must be called to initialize a IMAGE/TEXT write operation.
See the ct_send_data() entry below for an example.

=item ct_finish_send()

ct_finish_send() is called to finish/commit an IMAGE/TEXT write operation.
See the ct_send_data() entry below for an example.

=item ct_send_data($image, $bytes)

Send $bytes bytes of $image to the database. The request must have been set
up via ct_prepare_send() and ct_data_info() for this to work. ct_send_data()
returns B<TRUE> on success, and B<FALSE> on failure.

In this example, we wish to update the data in the I<img> column
where the I<id> column is 1. We assume that DBI is at version 1.37 or
later and use the direct method calls:

  # first we need to find the CS_IODESC data for the data
  $sth = $dbh->prepare("select img from imgtable where id = 1");
  $sth->execute;
  while($sth->fetch) {    # don't care about the data!
      $sth->syb_ct_data_info('CS_GET', 1);
  }

  # OK - we have the CS_IODESC values, so do the update:
  $sth->syb_ct_prepare_send();
  # Set the size of the new data item (that we are inserting), and make
  # the operation unlogged
  $sth->syb_ct_data_info('CS_SET', 1, {total_txtlen => length($image), log_on_update => 0});
  # now transfer the data (in a single chunk, this time)
  $sth->syb_ct_send_data($image, length($image));
  # commit the operation
  $sth->syb_ct_finish_send();

The ct_send_data() call can also transfer the data in chunks, however you 
must know the total size of the image before you start the insert. For example:

  # update a database entry with a new version of a file:
  my $size = -s $file;
  # first we need to find the CS_IODESC data for the data
  $sth = $dbh->prepare("select img from imgtable where id = 1");
  $sth->execute;
  while($sth->fetch) {    # don't care about the data!
      $sth->syb_ct_data_info('CS_GET', 1);
  }

  # OK - we have the CS_IODESC values, so do the update:
  $sth->syb_ct_prepare_send();
  # Set the size of the new data item (that we are inserting), and make
  # the operation unlogged
  $sth->syb_ct_data_info('CS_SET', 1, {total_txtlen => $size, log_on_update => 0});

  # open the file, and store it in the db in 1024 byte chunks.
  open(IN, $file) || die "Can't open $file: $!";
  while($size) {
      $to_read = $size > 1024 ? 1024 : $size;
      $bytesread = read(IN, $buff, $to_read);
      $size -= $bytesread;

      $sth->syb_ct_send_data($buff, $bytesread);
  }
  close(IN);
  # commit the operation
  $sth->syb_ct_finish_send();
      

=back
       

=head1 AutoCommit, Transactions and Transact-SQL

When $h->{AutoCommit} is I<off> all data modification SQL statements
that you issue (insert/update/delete) will only take effect if you
call $dbh->commit.

DBD::Sybase implements this via two distinct methods, depending on 
the setting of the $h->{syb_chained_txn} attribute and the version of the
server that is being accessed.

If $h->{syb_chained_txn} is I<off>, then the DBD::Sybase driver
will send a B<BEGIN TRAN> before the first $dbh->prepare(), and
after each call to $dbh->commit() or $dbh->rollback(). This works
fine, but will cause any SQL that contains any I<CREATE TABLE>
(or other DDL) statements to fail. These I<CREATE TABLE> statements can be
burried in a stored procedure somewhere (for example,
C<sp_helprotect> creates two temp tables when it is run). 
You I<can> get around this limit by setting the C<ddl in tran> option
(at the database level, via C<sp_dboption>.) You should be aware that
this can have serious effects on performance as this causes locks to
be held on certain system tables for the duration of the transaction.

If $h->{syb_chained_txn} is I<on>, then DBD::Sybase sets the
I<CHAINED> option, which tells Sybase not to commit anything automatically.
Again, you will need to call $dbh->commit() to make any changes to the data
permanent. 

=head1 Behavior of $dbh->last_insert_id

This version of DBD::Sybase includes support for the last_insert_id() call,
with the following caveats:

The last_insert_id() call is simply a wrapper around a "select @@identity"
query. To be successful (i.e. to return the correct value) this must
be executed on the same connection as the INSERT that generated the
new IDENTITY value. Therefore the statement handle that was used to
perform the insert B<must> have been closed/freed before last_insert_id()
can be called. Otherwise last_insert_id() will be forced to open a different
connection to perform the query, and will return an invalid value (usually
in this case it will return 0).

last_insert_id() ignores any parameters passed to it, and will NOT return
the last @@identity value generated in the case where placeholders were used,
or where the insert was encapsulated in a stored procedure.

=head1 Using ? Placeholders & bind parameters to $sth->execute

DBD::Sybase supports the use of ? placeholders in SQL statements as long
as the underlying library and database engine supports it. It does 
this by using what Sybase calls I<Dynamic SQL>. The ? placeholders allow
you to write something like:

	$sth = $dbh->prepare("select * from employee where empno = ?");

        # Retrieve rows from employee where empno == 1024:
	$sth->execute(1024);
	while($data = $sth->fetch) {
	    print "@$data\n";
	}

       # Now get rows where empno = 2000:
	
	$sth->execute(2000);
	while($data = $sth->fetch) {
	    print "@$data\n";
	}

When you use ? placeholders Sybase goes and creates a temporary stored 
procedure that corresponds to your SQL statement. You then pass variables
to $sth->execute or $dbh->do, which get inserted in the query, and any rows
are returned.

DBD::Sybase uses the underlying Sybase API calls to handle ?-style 
placeholders. For select/insert/update/delete statements DBD::Sybase
calls the ct_dynamic() family of Client Library functions, which gives
DBD::Sybase data type information for each parameter to the query.

You can only use ?-style placeholders for statements that return a single
result set, and the ? placeholders can only appear in a 
B<WHERE> clause, in the B<SET> clause of an B<UPDATE> statement, or in the
B<VALUES> list of an B<INSERT> statement. 

The DBI docs mention the following regarding NULL values and placeholders:

=over 4

       Binding an `undef' (NULL) to the placeholder will not
       select rows which have a NULL `product_code'! Refer to the
       SQL manual for your database engine or any SQL book for
       the reasons for this.  To explicitly select NULLs you have
       to say "`WHERE product_code IS NULL'" and to make that
       general you have to say:

         ... WHERE (product_code = ? OR (? IS NULL AND product_code IS NULL))

       and bind the same value to both placeholders.

=back

This will I<not> work with a Sybase database server. If you attempt the 
above construct you will get the following error:

=over 4

The datatype of a parameter marker used in the dynamic prepare statement could not be resolved.

=back

The specific problem here is that when using ? placeholders the prepare()
operation is sent to the database server for parameter resoltion. This extracts
the datatypes for each of the placeholders. Unfortunately the C<? is null>
construct doesn't tie the ? placeholder with an existing table column, so
the database server can't find the data type. As this entire operation happens
inside the Sybase libraries there is no easy way for DBD::Sybase to work around
it.

Note that Sybase will normally handle the C<foo = NULL> construct the same way
that other systems handle C<foo is NULL>, so the convoluted construct that
is described above is not necessary to obtain the correct results when
querying a Sybase database.


The underlying API does not support ?-style placeholders for stored 
procedures, but see the section on titled B<Stored Procedures and Placeholders>
elsewhere in this document.

?-style placeholders can B<NOT> be used to pass TEXT or IMAGE data
items to the server. This is a limitation of the TDS protocol, not of
DBD::Sybase.

There is also a performance issue: OpenClient creates stored procedures in
tempdb for each prepare() call that includes ? placeholders. Creating
these objects requires updating system tables in the tempdb database, and
can therefore create a performance hotspot if a lot of prepare() statements
from multiple clients are executed simultaneously. This problem
has been corrected for Sybase 11.9.x and later servers, as they create
"lightweight" temporary stored procs which are held in the server memory
cache and don't affect the system tables at all. 

In general however I find that if your application is going to run 
against Sybase it is better to write ad-hoc
stored procedures rather than use the ? placeholders in embedded SQL.

Out of curiosity I did some simple timings to see what the overhead
of doing a prepare with ? placehoders is vs. a straight SQL prepare and
vs. a stored procedure prepare. Against an 11.0.3.3 server (linux) the
placeholder prepare is significantly slower, and you need to do ~30
execute() calls on the prepared statement to make up for the overhead.
Against a 12.0 server (solaris) however the situation was very different,
with placeholder prepare() calls I<slightly> faster than straight SQL
prepare(). This is something that I I<really> don't understand, but
the numbers were pretty clear.

In all cases stored proc prepare() calls were I<clearly> faster, and 
consistently so.

This test did not try to gauge concurrency issues, however.

It is not possible to retrieve the last I<IDENTITY> value
after an insert done with ?-style placeholders. This is a Sybase
limitation/bug, not a DBD::Sybase problem. For example, assuming table
I<foo> has an identity column:

  $dbh->do("insert foo(col1, col2) values(?, ?)", undef, "string1", "string2");
  $sth = $dbh->prepare('select @@identity') 
    || die "Can't prepare the SQL statement: $DBI::errstr";
  $sth->execute || die "Can't execute the SQL statement: $DBI::errstr";

  #Get the data back.
  while (my $row = $sth->fetchrow_arrayref()) {
    print "IDENTITY value = $row->[0]\n";
  }

will always return an identity value of 0, which is obviously incorrect.
This behaviour is due to the fact that the handling of ?-style placeholders
is implemented using temporary stored procedures in Sybase, and the value
of C<@@identity> is reset when the stored procedure has executed. Using an 
explicit stored procedure to do the insert and trying to retrieve
C<@@identity> after it has executed results in the same behaviour.


Please see the discussion on Dynamic SQL in the 
OpenClient C Programmer's Guide for details. The guide is available on-line
at http://sybooks.sybase.com/

=head1 Calling Stored Procedures

DBD::Sybase handles stored procedures in the same way as any other
Transact-SQL statement. The only real difference is that Sybase stored 
procedures always return an extra result set with the I<return status>
from the proc which corresponds to the I<return> statement in the stored
procedure code. This result set with a single row is always returned last
and has a result type of CS_STATUS_RESULT (4043).

By default this result set is returned like any other, but you can ask 
DBD::Sybase to process it under the covers via the $h->{syb_do_proc_status}
attribute. If this attribute is set then DBD::Sybase will process the 
CS_STATUS_RESULT result set itself, place the return status value in 
$sth->{syb_proc_status}, and possibly raise an error if the result set 
is different from 0. Note that a non-0 return status will B<NOT> cause 
$sth->execute to return a failure code if the proc has at least one other 
result set that returned rows (reason: the rows are returned and fetched 
before the return status is seen).


=head2 Stored Procedures and Placeholders

DBD::Sybase has the ability to use ?-style
placeholders as parameters to stored proc calls. The requirements are
that the stored procedure call be initiated with an "exec" and that it be
the only statement in the batch that is being prepared():

For example, this prepares a stored proc call with named parameters:

    my $sth = $dbh->prepare("exec my_proc \@p1 = ?, \@p2 = ?");
    $sth->execute('one', 'two');

You can also use positional parameters:

    my $sth = $dbh->prepare("exec my_proc ?, ?");
    $sth->execute('one', 'two');

You may I<not> mix positional and named parameter in the same prepare.

You I<can't> mix placeholder parameters and hard coded parameters. For example

    $sth = $dbh->prepare("exec my_proc \@p1 = 1, \@p2 = ?");

will I<not> work - because the @p1 parameter isn't parsed correctly
and won't be sent to the server.

You can specify I<OUTPUT> parameters in the usual way, but you can B<NOT>
use bind_param_inout() to get the output result - instead you have to call
fetch() and/or $sth->func('syb_output_params'):

    my $sth = $dbh->prepare("exec my_proc \@p1 = ?, \@p2 = ?, \@p3 = ? OUTPUT ");
    $sth->execute('one', 'two', 'three');
    my (@data) = $sth->syb_output_params();

DBD::Sybase does not attempt to figure out the correct parameter type
for each parameter (it would be possible to do this for most cases, but
there are enough exceptions that I preferred to avoid the issue for the 
time being). DBD::Sybase defaults all the parameters to SQL_CHAR, and
you have to use bind_param() with an explicit type value to set this to
something different. The type is then remembered, so you only need to 
use the explicit call once for each parameter:

    my $sth = $dbh->prepare("exec my_proc \@p1 = ?, \@p2 = ?");
    $sth->bind_param(1, 'one', SQL_CHAR);
    $sth->bind_param(2, 2.34, SQL_FLOAT);
    $sth->execute;
    ....
    $sth->execute('two', 3.456);
    etc...

Note that once a type has been defined for a parameter you can't change
it.

When binding SQL_NUMERIC or SQL_DECIMAL data you may get fatal conversion
errors if the scale or the precision exceeds the size of the target
parameter definition.

For example, consider the following stored proc definition:

    declare proc my_proc @p1 numeric(5,2) as...

and the following prepare/execute snippet:

    my $sth = $dbh->prepare("exec my_proc \@p1 = ?");
    $sth->bind_param(1, 3.456, SQL_NUMERIC);

This generates the following error:

DBD::Sybase::st execute failed: Server message number=241 severity=16 state=2 line=0 procedure=dbitest text=Scale error during implicit conversion of NUMERIC value '3.456' to a NUMERIC field.

You can tell Sybase (and DBD::Sybase) to ignore these sorts of errors by
setting the I<arithabort> option:

    $dbh->do("set arithabort off");

See the I<set> command in the Sybase Adaptive Server Enterprise Reference 
Manual for more information on the set command and on the arithabort option.

=head1 Other Private Methods

=head2 DBD::Sybase private Database Handle Methods

=over 4

=item $bool = $dbh->syb_isdead

Tests the connection to see if the connection has been marked DEAD by OpenClient.
The connection can get marked DEAD if an error occurs on the connection, or the connection fails.

=back

=head2 DBD::Sybase private Statement Handle Methods

=over 4

=item @data = $sth->syb_describe([$assoc])

Retrieves the description of each of the output columns of the current 
result set. Each element of the returned array is a reference
to a hash that describes the column. The following fields are set:
NAME, TYPE, SYBTYPE, MAXLENGTH, SCALE, PRECISION, STATUS.

You could use it like this:

   my $sth = $dbh->prepare("select name, uid from sysusers");
   $sth->execute;
   my @description = $sth->syb_describe;
   print "$description[0]->{NAME}\n";         # prints name
   print "$description[0]->{MAXLENGTH}\n";    # prints 30
   ....

   while(my $row = $sth->fetch) {
      ....
   }

The STATUS field is a string which can be tested for the following
values: CS_CANBENULL, CS_HIDDEN, CS_IDENTITY, CS_KEY, CS_VERSION_KEY, 
CS_TIMESTAMP and CS_UPDATABLE. See table 3-46 of the Open Client Client 
Library Reference Manual for a description of each of these values.

The TYPE field is the data type that Sybase::CTlib converts the
column to when retrieving the data, so a DATETIME column will be
returned as a CS_CHAR_TYPE column.

The SYBTYPE field is the real Sybase data type for this column.

I<Note that the symbolic values of the CS_xxx symbols isn't available
yet in DBD::Sybase.>


=back

=head1 Experimental Bulk-Load Functionality

B<NOTE>: This feature requires that the I<libblk.a> library be available
at build time. This is not always the case if the Sybase SDK isn't
installed. You can test the $dbh->{syb_has_blk} attribute to
see if the BLK api calls are available in your copy of DBD::Sybase.

Starting with release 1.04.2 DBD::Sybase has the ability to use Sybase's
BLK (bulk-loading) API to perform fast data loads. Basic usage is as follows:

  my $dbh = DBI->connect('dbi:Sybase:server=MY_SERVER;bulkLogin=1', $user, $pwd);

  $dbh->begin_work;  # optional.
  my $sth = $dbh->prepare("insert the_table values(?, ?, ?, ?, ?)",
                          {syb_bcp_attribs => { identity_flag => 0,
                                               identity_column => 0 }}});
  while(<DATA>) {
    chomp;
    my @row = split(/\|/, $_);   # assume a pipe-delimited file...
    $sth->execute(@row);
  }
  $dbh->commit;
  print "Sent ", $sth->rows, " to the server\n";
  $sth->finish;

First, you need to specify the new I<bulkLogin> attribute in the connection
string, which turns on the CS_BULK_LOGIN property for the connection. Without
this property the BLK api will not be functional.

You call $dbh->prepare() with a regular INSERT statement and the 
special I<syb_bcp_attribs> attribute to turn on BLK handling of the data.
The I<identity_flag> sub-attribute can be set to 1 if your source data
includes the values for the target table's IDENTITY column. If the
target table has an IDENTITY column but you want the insert operation to
generate a new value for each row then leave I<identity_flag> at 0, but set
I<identity_col> to the column number of the identity column (it's usually
the first column in the table, but not always.)

The number of placeholders in the INSERT statement I<must> correspond to
the number of columns in the table, and the input data I<must> be in the
same order as the table's physical column order. Any column list in the
INSERT statement (i.e. I<insert table(a, b, c,...) values(...)> is ignored.

The value of AutoCommit is ignored for BLK operations - rows are only 
commited when you call $dbh->commit.

You can call $dbh->rollback to cancel any uncommited rows, but this I<also>
cancels the rest of the BLK operation: any attempt to load rows to the
server after a call to $dbh->rollback() will fail.

If a row fails to load due to a CLIENT side error (such as a data conversion
error) then $sth->execute() will return a failure (i.e. false) and
$sth->errstr will have the reason for the error.

If a row fails on the SERVER side (for example due to a duplicate row
error) then the entire batch (i.e. between two $dbh->commit() calls) 
will fail. This is normal behavior for BLK/bcp.

The Bulk-Load API is very sensitive to data conversion issues, as all the
conversions are handled on the client side, and the row is pre-formatted
before being sent to the server. By default any conversion that is flagged
by Sybase's cs_convert() call will result in a failed row. Some of these
conversion errors are patently fatal (e.g. converting 'Feb 30 2001' to a
DATETIME value...), while others are debatable (e.g. converting 123.456 to
a NUMERIC(6,2) which results in a loss of precision). The default behavior
of failing any row that has a conversion error in it can be modified by 
using a special error handler. Returning 0 from this handler
tells DBD::Sybase to fail this row, and returning 1 means that we still
want to try to send the row to the server (obviously Sybase's internal
code can still fail the row at that point.)
You set the handler like this:

    DBD::Sybase::syb_set_cslib_cb(\&handler);

and a sample handler:

   sub cslib_handler {
     my ($layer, $origin, $severity, $errno, $errmsg, $osmsg, $blkmsg) = @_;
     
     print "Layer: $layer, Origin: $origin, Severity: $severity, Error: $errno\n";
     print $msg;
     print $osmsg if($osmsg);
     print $blkmsg if $blkmsg;

     return 1 if($errno == 36)

     return 0;
   }

Please see the t/xblk.t test script for some examples.

Reminder - this is an I<experimental> implementation. It may change
in the future, and it could be buggy.

=head1 Using DBD::Sybase with MS-SQL 

MS-SQL started out as Sybase 4.2, and there are still a lot of similarities
between Sybase and MS-SQL which makes it possible to use DBD::Sybase
to query a MS-SQL dataserver using either the Sybase OpenClient libraries
or the FreeTDS libraries (see http://www.freetds.org).

However, using the Sybase libraries to query an MS-SQL server has
certain limitations. In particular ?-style placeholders are not 
supported (although support when using the FreeTDS libraries is
possible in a future release of the libraries), and certain B<syb_> 
attributes may not be supported.

Sybase defaults the TEXTSIZE attribute (aka B<LongReadLen>) to
32k, but MS-SQL 7 doesn't seem to do that correctly, resulting in
very large memory requests when querying tables with TEXT/IMAGE 
data columns. The work-around is to set TEXTSIZE to some decent value
via $dbh->{LongReadLen} (if that works - I haven't had any confirmation
that it does) or via $dbh->do("set textsize <somesize>");

=head1 nsql

The nsql() call is a direct port of the function of the same name that
exists in Sybase::DBlib. From 1.08 it has been extended to offer new 
functionality.

Usage:

   @data = $dbh->func($sql, $type, $callback, $options, 'nsql');

If the DBI version is 1.37 or later, then you can also call it this way:

   @data = $dbh->syb_nsql($sql, $type, $callback, $options);

This executes the query in $sql, and returns all the data in @data. The 
$type parameter can be used to specify that each returned row be in array
form (i.e. $type passed as 'ARRAY', which is the default) or in hash form 
($type passed as 'HASH') with column names as keys.

If $callback is specified it is taken as a reference to a perl sub, and
each row returned by the query is passed to this subroutine I<instead> of
being returned by the routine (to allow processing of large result sets, 
for example).

If $options is specified and is a HASH ref, the following keys affect the
value returned by nsql():

=over 4

=item oktypes => [...]

This generalises I<syb_nsql_nostatus> (see below) by ignoring any result sets 
which are of a type not listed.

=item bytype => 0|1|'merge'

If this option is set to a true value, each result set will be returned as the
value of a hash, the key of which is the result type of this result set as defined
by the CS_*_TYPE values described above. If the special value 'merge' is used,
result sets of the same type will be catenated (as nsql() does by default) into
a single array of results and the result of the nsql() call will be a single hash
keyed by result type. Usage is better written %data = $dbh->syb_nsql(...) in this
case.

=item arglist => [...]

This option provides support for placeholders in the SQL query passed to nsql().
Each time the SQL statement is executed the array value of this option will be
passed as the parameter list to the execute() method.

=back

Note that if $callback is omitted, a hash reference in that parameter position
will be interpreted as an option hash if no hash reference is found in the 
$options parameter position.

C<nsql> also checks three special attributes to enable deadlock retry logic
(I<Note> none of these attributes have any effect anywhere else at the moment):

=over 4

=item syb_deadlock_retry I<count>

Set this to a non-0 value to enable deadlock detection and retry logic within
nsql(). If a deadlock error is detected (error code 1205) then the entire
batch is re-submitted up to I<syb_deadlock_retry> times. Default is 0 (off).

=item syb_deadlock_sleep I<seconds>

Number of seconds to sleep between deadlock retries. Default is 60.

=item syb_deadlock_verbose (bool)

Enable verbose logging of deadlock retry logic. Default is off.

=item syb_nsql_nostatus (bool)

If true then stored procedure return status values (i.e. results of type
CS_STATUS_RESULT) are ignored.

=back

Deadlock detection will be added to the $dbh->do() method in a future
version of DBD::Sybase. 

=head1 Multi-Threading

DBD::Sybase is thread-safe (i.e. can be used in a multi-threaded
perl application where more than one thread accesses the database
server) with the following restrictions:

=over 4

=item * perl version >= 5.8

DBD::Sybase requires the use of I<ithreads>, available in the perl 5.8.0
release. It will not work with the older 5.005 threading model.

=item * Sybase thread-safe libraries

Sybase's Client Library comes in two flavors. DBD::Sybase must find the
thread-safe version of the libraries (ending in _r on Unix/linux). This 
means Open Client 11.1.1 or later. In particular this means that you can't
use the 10.0.4 libraries from the free 11.0.3.3 release on linux if you
want to use multi-threading.

Note: when using perl >= 5.8 with the thread-safe libraries (libct_r.so, etc)
then signal handling is broken and any signal delivered to the perl process
will result in a segmentation fault. It is recommended in that case to 
link with the non-threadsafe libraries.

=item * use DBD::Sybase

You I<must> include the C<use DBD::Sybase;> line in your program. This
is needed because DBD::Sybase needs to do some setup I<before> the first
thread is started.

=back

You can check to see if your version of DBD::Sybase is thread-safe at
run-time by calling DBD::Sybase::thread_enabled(). This will return
I<true> if multi-threading is available.

See t/thread.t for a simple example.

=head1 BUGS

You can run out of space in the tempdb database if you use a lot of
calls with bind variables (ie ?-style placeholders) without closing the
connection and Sybase 11.5.x or older. This is because
Sybase creates stored procedures for each prepare() call. 
In 11.9.x and later Sybase will create "light-weight" stored procedures
which don't use up any space in the tempdb database.

The primary_key_info() method will only return data for tables 
where a declarative "primary key" constraint was included when the table
was created.

I have a simple bug tracking database at http://www.peppler.org/bugdb/ .
You can use it to view known problems, or to report new ones. 


=head1 SEE ALSO

L<DBI>

Sybase OpenClient C manuals.

Sybase Transact SQL manuals.

=head1 AUTHOR

DBD::Sybase by Michael Peppler

=head1 COPYRIGHT

The DBD::Sybase module is Copyright (c) 1996-2007 Michael Peppler.
The DBD::Sybase module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Tim Bunce for DBI, obviously!

See also L<DBI/ACKNOWLEDGEMENTS>.

=cut
