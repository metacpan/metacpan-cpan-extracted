#!
#  @file           MaxDB.pm
#  @author         MarcoP, ThomasS
#  @ingroup        dbd::MaxDB
#  @brief
#
#\if EMIT_LICENCE
#
#    ========== licence begin  GPL
#    Copyright (c) 2001-2005 SAP AG
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    as published by the Free Software Foundation; either version 2
#    of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#    ========== licence end

#\endif
#*/

require 5.004;

$DBD::MaxDB::VERSION = '7.6.00.16';

{
    package DBD::MaxDB;

    use DBI ();
    use DynaLoader ();
    use Exporter ();

    @ISA = qw(Exporter DynaLoader);

    my $Revision = substr(q$Revision: 1.12 $, 10);

    require_version DBI 1.21;

    bootstrap DBD::MaxDB $VERSION;

    $err = 0;           # holds error code   for DBI::err
    $errstr = "";       # holds error string for DBI::errstr
    $sqlstate = "00000";
    $drh = undef;       # holds driver handle once initialised
    
    my $tmp = "constant default paramater, can be used for prepared statements";
    $DEFAULT_PARAMETER =  \*{"DBD::MaxDB::". $tmp};

    sub driver{
        return $drh if $drh;
        my($class, $attr) = @_;

        $class .= "::dr";

        $drh = DBI::_new_drh($class, {
            'Name' => 'MaxDB',
            'Version' => $VERSION,
            'Err'    => \$DBD::MaxDB::err,
            'Errstr' => \$DBD::MaxDB::errstr,
            'State' => \$DBD::MaxDB::sqlstate,
            'Attribution' => 'MaxDB DBD by SAP AG',
            });

        $drh;
    }

    sub CLONE { undef $drh }
    1;
}


{   package DBD::MaxDB::dr; # ====== DRIVER ======
    use strict;
    
    my $db_info = undef;

    sub data_sources {
      unless ($db_info) {
        $db_info = DBD::MaxDB::InstInfo::new();
      }  
      my @db_enum = sort  keys %{$db_info->{'database'}};
      my @data_src = map { $_ ? ("dbi:MaxDB:$_") : () } @db_enum;
      return @data_src;
    }

    sub connect {
        my $drh = shift;
        my($url, $user, $auth, $attr)= @_;
        $user = '' unless defined $user;
        $auth = '' unless defined $auth;
        $attr = undef unless(defined $attr && ref $attr eq "HASH");

          $url=~/(([^:^\/]*(?::.+)?)(?:\/))?([^\?.]*)?(?:\?(.*))?/;
          if (defined $1){
      if (defined $2){
              $attr->{"HOST"}=$2;
            } else {
              $attr->{"HOST"}="";
            }
      } else {
            $attr->{"HOST"}="";
          }
          if (defined $3){
            $attr->{"DBNAME"}=$3;
          } else {
            $attr->{"DBNAME"}="";
          }
          if (defined $4){
            foreach (split(/&/,$4)){
              $_=~/(.*)=(.*)/;
              $attr->{uc ($1)}=$2;
            }
          }
        # create a 'blank' dbh
        my $this = DBI::_new_dbh($drh, {
            'Name' => $url,
            'USER' => $user,
            'CURRENT_USER' => $user,
            });

        # Call SQLDBC logon func in MaxDB.xs file
        # and populate internal handle data.

        DBD::MaxDB::db::_login($this, $url, $user, $auth, $attr) or return undef;
        $this;
    }

}


{   package DBD::MaxDB::db; # ====== DATABASE ======
    use strict;

    sub prepare {
        my($dbh, $statement, @attribs)= @_;

        # create a 'blank' dbh
        my $sth = DBI::_new_sth($dbh, {
            'Statement' => $statement,
            });

        DBD::MaxDB::st::_prepare($sth, $statement, @attribs)
            or return undef;

        $sth;
    }

    sub column_info {
        my ($dbh, $catalog, $schema, $table, $column) = @_;

        if ($#_ == 1) {
           my $attrs = $_[1];
           $catalog = $attrs->{TABLE_CAT};
           $schema = $attrs->{TABLE_SCHEM};
           $table = $attrs->{TABLE_NAME};
           $column = $attrs->{TABLE_COLUMN};
        }

        my $DataTypeSuffix_C = <<'EOF';
          'CHAR','CHAR()',
          'VARCHAR','VARCHAR()',
          'LONG','LONG',
          'LONG RAW','LONG',
          datatype
EOF

        my $typename2odbc_C = <<'EOF';
          'CHAR', 1,
          'CHAR() ASCII', 1,
          'CHAR() EBCDIC', 1,
          'CHAR() UNICODE', 1,
          'CHAR() BYTE', -2,
          'VARCHAR', 12,
          'VARCHAR() ASCII', 12,
          'VARCHAR() EBCDIC', 12,
          'VARCHAR() UNICODE', 12,
          'VARCHAR() BYTE', -3,
          'LONG', -1,
          'LONG ASCII', -1,
          'LONG EBCDIC', -1,
          'LONG UNICODE', -1,
          'LONG BYTE', -4,
          'LONG RAW', -4,
          'FIXED', 3,
          'DECIMAL', 3,
          'REAL', 7,
          'FLOAT', 6,
          'DOUBLE PRECISION', 8,
          'SMALLINT', 5,
          'INTEGER', 4,
          'BOOLEAN', -7,
          'TIME', 92,
          'DATE', 91,
          'TIMESTAMP', 93,
          'NUMBER', 2,
          1111
EOF
        my $stmt = "SELECT NULL TABLE_CAT, owner TABLE_SCHEM, tablename TABLE_NAME, columnname COLUMN_NAME, ";
        $stmt .= "decode (((decode (datatype,$DataTypeSuffix_C))|| (' ' || (codetype))), ";
        $stmt .= " $typename2odbc_C ) DATA_TYPE, ";
        $stmt .= "(decode(datatype, $DataTypeSuffix_C))|| (' ' || (codetype)) TYPE_NAME, ";
        $stmt .= "len COLUMN_SIZE, NULL BUFFER_LENGTH, dec DECIMAL_DIGITS, 10 NUM_PREC_RADIX, decode (mode, 'OPT', 1, 0) NULLABLE, comment REMARKS, \"DEFAULT\" COLUMN_DEF, NULL SQL_DATA_TYPE, NULL SQL_DATETIME_SUB, len CHAR_OCTET_LENGTH, ";
        if (DBD::MaxDB::db::_getSQLMode($dbh)=~/oracle/i){
          $stmt .= "ROWNUM ORDINAL_POSITION, ";
        } else {
          $stmt .= "ROWNO ORDINAL_POSITION, ";
        }
        $stmt .= "decode (mode, 'OPT', 'YES', 'NO') IS_NULLABLE FROM domain.columns WHERE TABLETYPE <> 'RESULT' ";
        $stmt .= "AND owner LIKE '$schema' " if ($schema);
        $stmt .= "AND tablename LIKE '$table' " if ($table);
        $stmt .= "AND columnname LIKE '$column' " if ($column);
        $stmt .= " ORDER BY owner, tablename, pos ";

        my $sth = DBI::_new_sth($dbh, { 'Statement' => $stmt });
        $sth->{'LongTruncOk'} = 1;

        my $res = DBD::MaxDB::st::_executeInternal($dbh, $sth, $stmt);
        return undef if (!$res && $res != '0E0');
        $sth;
    }


    sub table_info {
        my($dbh, $catalog, $schema, $table, $type) = @_;

        if ($#_ == 1) {
           my $attrs = $_[1];
           $catalog = $attrs->{TABLE_CAT};
           $schema = $attrs->{TABLE_SCHEM};
           $table = $attrs->{TABLE_NAME};
           $type = $attrs->{TABLE_TYPE};
        }

        my $stmt = "SELECT NULL TABLE_CAT, owner TABLE_SCHEM, tablename TABLE_NAME, type TABLE_TYPE, comment REMARKS from domain.tables WHERE 1 = 1 ";
        $stmt .= "AND owner LIKE '$schema' " if ($schema);
        $stmt .= "AND tablename LIKE '$table' " if ($table);
        if ($type){
          my $sep = "";
          $stmt .= "AND type IN (";
          foreach (split(/,/,$type)){
            $stmt .= "$sep'$_'";
            $sep = ", ";
          }
          $stmt .= ") ";
        } else {
          $stmt .= "AND type <> 'RESULT' ";
        }
        $stmt .= "ORDER BY TABLE_TYPE, TABLE_SCHEM, TABLE_NAME";

        my $sth = DBI::_new_sth($dbh, { 'Statement' => $stmt });
        $sth->{'LongTruncOk'} = 1;

        my $res = DBD::MaxDB::st::_executeInternal($dbh, $sth, $stmt);
        return undef if (!$res && $res != '0E0');
        $sth;
    }

    sub primary_key_info {
       my ($dbh, $catalog, $schema, $table ) = @_;

       # create a "blank" statement handle
       my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLPrimaryKeys" });

       $catalog = "" if (!$catalog);
       $schema = "" if (!$schema);
       $table = "" if (!$table);
       DBD::MaxDB::st::_primary_keys($dbh,$sth, $catalog, $schema, $table )
             or return undef;
       $sth;
    }

    sub foreign_key_info {
       my ($dbh, $pkcatalog, $pkschema, $pktable, $fkcatalog, $fkschema, $fktable ) = @_;

       # create a "blank" statement handle
       my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLForeignKeys" });

       $pkcatalog = "" if (!$pkcatalog);
       $pkschema = "" if (!$pkschema);
       $pktable = "" if (!$pktable);
       $fkcatalog = "" if (!$fkcatalog);
       $fkschema = "" if (!$fkschema);
       $fktable = "" if (!$fktable);
       _GetForeignKeys($dbh, $sth, $pkcatalog, $pkschema, $pktable, $fkcatalog, $fkschema, $fktable) or return undef;
       $sth;
    }

    sub ping {
        my $dbh = shift;
    my $erg = DBD::MaxDB::db::_ping($dbh);
    return $erg;
    }

    # New support for the next DBI which will have a get_info command.
    # leaving support for ->func(xxx, GetInfo) (above) for a period of time
    # to support older applications which used this.
    sub get_info {
        my($dbh, $info_type) = @_;
        require DBD::MaxDB::GetInfo;
        my $v = $DBD::MaxDB::GetInfo::info{int($info_type)};
        $v = $v->($dbh) if ref $v eq 'CODE';
        return $v;
    }

    # use SQLDBC_Statement for a faster version of do statements without parameters.
    sub do {
        my($dbh, $stmt, $attr, @params) = @_;
        my $rescnt = 0;

        if( -1 == $#params )
        {
          # No parameters, use SQLDBC_Statement
          $rescnt = executeUpdate( $dbh, $stmt );
          if( 0 == $rescnt )
          {
            $rescnt = "0E0";
          }
          elsif( $rescnt < -1 && $rescnt >= -4 )
          {
            $rescnt = -1;
          }
          elsif( $rescnt < -4 )
          {
            undef $rescnt;
          }
        }
        else
        {
          $rescnt = $dbh->SUPER::do( $stmt, $attr, @params );
        }
        return $rescnt
    }

    #
    # executes a simple command without parameters
    # and which doesn't return a resultset
    sub executeUpdate {
       my ($dbh, $sql) = @_;
       _executeUpdate($dbh, $sql);
    }

    # Call the MaxDB function SQLGetInfo
    # Args are:
    #   $dbh - the database handle
    #   $item: the requested item.  For example, pass 6 for SQL_DRIVER_NAME
    # See the ODBC documentation for more information about this call.
    #
    sub GetInfo {
        my ($dbh, $item) = @_;
        get_info($dbh, $item);
    }

    sub GetTypeInfo {
        my ($dbh, $sqltype) = @_;
        # create a "blank" statement handle
        my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
        # print "SQL Type is $sqltype\n";
        _GetTypeInfo($dbh, $sth, $sqltype) or return undef;
        $sth;
    }

    sub type_info_all {
        my ($dbh) = @_;
  my $res = DBD::MaxDB::db::_isunicode($dbh);
        if ($res) {
    require DBD::MaxDB::TypeInfoUnicode;
    return $DBD::MaxDB::TypeInfoUnicode::type_info_all;
  } else {
    require DBD::MaxDB::TypeInfoAscii;
    return $DBD::MaxDB::TypeInfoAscii::type_info_all;
  }
    }

}


{   package DBD::MaxDB::st; # ====== STATEMENT ======
    use strict;

    sub cancel {
        my $sth = shift;
        my $tmp = _Cancel($sth);
        $tmp;
    }
}

1;
__END__


=head1 NAME

DBD::MaxDB - MySQL MaxDB database driver for the DBI module
version 7.6.0    BUILD 016-121-109-428

=head1 SYNOPSIS

  use DBI;
  $dbh = DBI->connect("dbi:MaxDB:$hostname/$dbname", "$user", "$password")
           or die "Can't connect $DBI::err $DBI::errstr\n";
  $sth = $dbh->prepare("SELECT 'Hello World' as WELCOME from dual")
           or die "Can't prepare statement $DBI::err $DBI::errstr\n";
  $res = $sth->execute()
           or die "Can't execute statement $DBI::err $DBI::errstr\n";
  @row = $sth->fetchrow_array();
  ...

See the L<DBI> module documentation for full details.

=head1 DESCRIPTION

DBD::MaxDB is a Perl module which provides access to the
MySQL MaxDB databases using the DBI module. It is an
interface between the Perl programming language and the MaxDB
programming API SQLDBC that comes with the MySQL MaxDB relational
database management system.

The DBD::MaxDB module needs to link with MaxDB's common database interface
SQLDBC which is not included in this distribution. You can download it from the
MySQL homepage at:
L<http://www.mysql.com/maxdb>

=head1 MODULE DOCUMENTATION

This section describes the driver specific behavior and restrictions. It does
not describe the DBI interface in general. For this purpose please consult the
L<DBI> documentation.

=head2 Connect

To connect to a database with a minimum of parameters, use the following syntax:

C<< $dbh = DBI->connect($url, $user, $password); >>

The URL contains the name of the database instance, and, if you are connecting
to a remote computer, the name of this computer. Additionally the URL may
contain some other connection options described below.

=over 4

=item B<Define the connection URL>

Use the following format:

C<< dbi:MaxDB:/<database_server>[:<port>]/<database_name>[?<options>] >>

  Parameter            Description
  ----------------------------------------------------
  <database_server>    Name of the database computer
                       (default localhost)

  <port>               Socket port to which you want
                       to connect. Specify this port
                       only if the X Server (MaxDB 
                       remote communication server) 
                       has been configured with a port 
                       that is not the system default 
                       port.

  <database_name>      Name of the database instance

  <options>            See the following section
                       Connection Options

=item B<Connection Options>

You can use connection options to define the properties of a database instance
connection. You can specify these options as part of the connection URL. In this
case, you must specify them with the following format:

C<< <name>=<value>[&<name>=<value>...] >>

You can define the following options:

  Option              Description
  -------------------------------------------------------
  user                Name of the database user

  password            User password

  sqlmode             SQL mode, possible values are
                      ORACLE | INTERNAL.The system
                      default is INTERNAL.

  timeout             Command timeout of the connection
                      (in seconds)

  isolationlevel      Isolation level of the connection

  statementcachesize  The number of prepared statements
                      to be cached for the connection
                      for re-use. Possible values are:
                      <n>: desired number of statements,
                      0: no statements are cached,
                      UNLIMITED: unlimited number of
                      statements are cached.

  unicode             The user name, password and SQL
                      statements are sent to the database
                      in UNICODE.

=item B<Examples>

Definition of the parameter url for a connection to the database TST on the
computer REMOTESERVER

C< dbi:MaxDB:REMOTESERVER/TST >

Definition of the parameter url for a connection to the database TST on the
remote computer REMOTESERVER using the port 7673. (This definition requires
the X Server to be configured with the same port.)

C< dbi:MaxDB:servermachine:7673/TST >

Definition of the parameter url for a connection to the database TST on the
local computer

C< dbi:MaxDB:TST >

Definition of the parameter url for a connection to the database TST on the
local computer; the SQL mode is ORACLE and a command timeout of 120 seconds
is defined:

C< dbi:MaxDB:TST?sqlmode=ORACLE&timeout=120 >

=back

=head2 Datasources

C<< @data_sources = DBI->data_sources('MaxDB'); >>

The driver supports this method. Note that only data sources on the local
computer will be listed.

=head2 Error messages

In case of an error the driver returns an error code, an error text and if
appropriate an error state. Details concerning the meaning of an error can
be found in the database messages reference at
L<http://www.mysql.com/products/maxdb/docs.html>

C<< $errcode = $h->err; >>
Returns the error code.

C<< $errstr = $h->errstr; >>
Returns the error text.

C<< $sqlstate = $h->state; >>
Returns the sql state.


=head1 DBI HANDLE ATTRIBUTES

Example:

  ... = $h->{<attribute>};         # get/read
  $h->{<attribute>} = <value> ;    # set/write

=head2 Attributes common to all handles

The driver supports all of the general DBI handle attributes provided by DBI.
Differences from standard behaviour are listed below.

=over 4

=item C<ChopBlanks (boolean, inherited)>

Supported by the driver as proposed by DBI, but due to the fact that MaxDB
cannot handle trailing blanks the driver will always chop blanks for
C<CHAR/VARCHAR> columns.

=back

=head2 Database Handle Attributes

The driver supports all of the DBI database handle attributes provided by DBI.
Additionally the driver provides some MaxDB specific database handle attributes.

=over 4

=item C<maxdb_isolationlevel (integer)>

Gets/Sets the isolation level of the current connection.

=item C<maxdb_kernelversion (string, read-only)>

Gets the version of the database instance used at the current connection.

=item C<maxdb_sdkversion (string, read-only)>

Gets the version of the MaxDB SQLDBC software development kit used by the driver.

=item C<maxdb_sqlmode (string)>

Gets/Sets the SQL mode of the current connection. Possible values are
C<ORACLE | INTERNAL>.

=item C<maxdb_unicode (boolean, read-only)>

Indicates whether the current connection supports unicode (true) or not (false)

=back

=head2 Statement Handle Attributes

The driver supports all of the DBI statement handle attributes provided by DBI.
Additionally the driver provides some MaxDB specific statement handle attributes.

=over 4

=item C<maxdb_fetchSize (integer)>

Gets/Sets the maximum number of rows that can be fetched at once. Use this to
manipulate the number of rows fetched in one chunk via the order interface.
Use a value > 0 to set the maximum number of rows. Use a value <= 0 to reset
this limit to the default value. The default value is 'unlimited' (32767).
Setting this value does not affect an already executed SQL statement.

=item C<maxdb_maxrows (integer)>

Gets/Sets the number of rows of a ResultSet. The number of rows of the result
set is truncated if the result of a query statement is larger than this limit.
The default setting is 'unlimited' (0). Setting this limit does not affect an
already executed SQL statement.

=item C<maxdb_resultsetconcurrency (string)>

Gets/Sets the type of the result set concurrency. There are two kinds of
concurrency:

=over 8

=item C<CONCUR_UPDATABLE>

The result set can be updated.

=item C<CONCUR_READ_ONLY>

The result set is read-only.

=back

The default setting for the concurrency is C<CONCUR_READ_ONLY>


=item C<maxdb_resultsettype (string)>

Sets the type of a result set. A result set is only created by a query command.
There are three kinds of result sets:

=over 8

=item C<FORWARD_ONLY>

The result set can only be scrolled forward.

=item C<SCROLL_SENSITIVE>

The result set is scrollable but may change.

=item C<SCROLL_INSENSITIVE>

The result set is scrollable and not change.

=back

The default for the result set type is C<SCROLL_INSENSITIVE>

=item C<maxdb_rowsaffected (integer, read-only)>

Returns the number of rows affected by the executed SQL statement. This method
returns a non-zero value if more than one row was addressed by the SQL statement.
If the return value is lower than zero, more than one rows was addressed but the
exact number of addressed rows cannot be determined.

=item C<maxdb_tablename (integer, read-only)>

Retrieves the table name (for C<SELECT FOR UPDATE> commands only).

=back

=head1 METADATA SUPPORT

=over 4

=item C<get_info()> and C<type_info_all()>

Supported by the driver as proposed by DBI.

=item C<table_info()>

The driver supports parameters for C<table_info()>. Currently is in MaxDB
(like in Oracle) the concept of user and schema the same. Because database
objects are owned by an user, the owner names in the data dictionary views
correspond to schema names. This may be changed in future releases when real
schema support is added.

MaxDB also does not support catalogs so the parameter C<TABLE_CAT> is ignored as
a selection criterion.

Search patterns are supported for C<TABLE_SCHEM> and C<TABLE_NAME>.

C<TABLE_TYPE> may contain a comma-separated list of table types.
The following table types are supported: C<TABLE, VIEW, RESULT, SYNONYM,
SEQUENCE>

The result set is ordered by C<TABLE_TYPE, TABLE_SCHEM, TABLE_NAME>.

=item C<tables()>

Supported by the driver as proposed by DBI. Since MaxDB does not support
catalogs so far the parameter C<TABLE_CAT> is ignored  as a selection criterion.

=item C<primary_key_info()>

Supported by the driver as proposed by DBI. Since MaxDB does not support
catalogs so far the parameter C<TABLE_CAT> is ignored  as a selection criterion and
the C<TABLE_CAT> field of a fetched row is always C<NULL>.

=item C<foreign_key_info()>

Supported by the driver as proposed by DBI. Since MaxDB does not support
catalogs so far the parameter C<TABLE_CAT> is ignored  as a selection criterion and
the C<TABLE_CAT> field of a fetched row is always C<NULL>.

=item C<column_info()>

Supported by the driver as proposed by DBI. Since MaxDB does not support
catalogs so far the parameter C<TABLE_CAT> is ignored as a selection criterion and
the C<TABLE_CAT> field of a fetched row is always C<NULL>.

=back

=head1 SPECIAL FEATURES

=head2 Binding of default values as parameter

The driver supports to bind a special default parameter C<$DBD::MaxDB::DEFAULT_PARAMETER> 
to set the default value as parameter of a prepared statement. 

  use DBI;
  $dbh->do("CREATE TABLE defaultvalues (ID INT NOT NULL DEFAULT 42)") 
           or die "Can't create table $DBI::err $DBI::errstr\n";
  $sth = $dbh->prepare("INSERT INTO defaultvalues (ID) values (?)")
           or die "Can't prepare statement $DBI::err $DBI::errstr\n";

  $res = $sth->execute($DBD::MaxDB::DEFAULT_PARAMETER)
           or die "Can't execute statement $DBI::err $DBI::errstr\n";
  ...


=head1 INSTALLATION

Please see the README file which comes with the module distribution.

=head1 MAILING LIST SUPPORT

This module is maintained and supported on a mailing list,

C<maxdb@lists.mysql.com>

To subscribe to this list, send a mail to

C<maxdb-subscribe@lists.mysql.com>

or

C<maxdb-digest-subscribe@lists.mysql.com>

Mailing list archives are available at

L<http://lists.mysql.com/maxdb>

Additionally you might try the dbi-user mailing list for questions about
DBI and its modules in general.

=head1 COPYRIGHT

Copyright 2000-2005 by SAP AG

This program is free software; you can redistribute it and/or
modify it under the terms of either the Artistic License, as
specified in the Perl README file or the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=head1 ADDITIONAL INFORMATION

Additional information on the DBI project can be found at the following URL:

L<http://dbi.perl.org>

where documentation, links to the mailing lists and mailing list
archives and links to the most current versions of the modules can
be used.

Information on the DBI interface itself can be gained by typing:

C<perldoc DBI>

Information on the MySQL MaxDB database can be found on the WWW at

L<http://www.mysql.com/maxdb>

=cut

