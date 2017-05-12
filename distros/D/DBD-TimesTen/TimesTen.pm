# $Id: TimesTen.pm 568 2006-12-02 01:31:48Z wagnerch $
#
# Copyright (c) 1994,1995,1996,1998  Tim Bunce
# portions Copyright (c) 1997-2004  Jeff Urlwin
# portions Copyright (c) 1997  Thomas K. Wenrich
# portions Copyright (c) 2006  Chad Wagner
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

require 5.004;

$DBD::TimesTen::VERSION = '0.06';

{
    package DBD::TimesTen;

    use DBI ();
    use DynaLoader ();
    use Exporter ();
    
    @ISA = qw(Exporter DynaLoader);
    %EXPORT_TAGS = (
       sql_isolation_options => [ qw(
          SQL_TXN_READ_COMMITTED SQL_TXN_SERIALIZABLE
       ) ],
       sql_getinfo_options => [ qw(
          SQL_INFO_FIRST SQL_ACTIVE_CONNECTIONS SQL_ACTIVE_STATEMENTS
          SQL_DATA_SOURCE_NAME SQL_DRIVER_HDBC SQL_DRIVER_HENV SQL_DRIVER_HSTMT
          SQL_DRIVER_NAME SQL_DRIVER_VER SQL_FETCH_DIRECTION
          SQL_ODBC_API_CONFORMANCE SQL_ODBC_VER SQL_ROW_UPDATES
          SQL_ODBC_SAG_CLI_CONFORMANCE SQL_SERVER_NAME
          SQL_SEARCH_PATTERN_ESCAPE SQL_ODBC_SQL_CONFORMANCE SQL_DBMS_NAME
          SQL_DBMS_VER SQL_ACCESSIBLE_TABLES SQL_ACCESSIBLE_PROCEDURES
          SQL_PROCEDURES SQL_CONCAT_NULL_BEHAVIOR SQL_CURSOR_COMMIT_BEHAVIOR
          SQL_CURSOR_ROLLBACK_BEHAVIOR SQL_DATA_SOURCE_READ_ONLY
          SQL_DEFAULT_TXN_ISOLATION SQL_EXPRESSIONS_IN_ORDERBY
          SQL_IDENTIFIER_CASE SQL_IDENTIFIER_QUOTE_CHAR
          SQL_MAX_COLUMN_NAME_LEN SQL_MAX_CURSOR_NAME_LEN
          SQL_MAX_OWNER_NAME_LEN SQL_MAX_PROCEDURE_NAME_LEN
          SQL_MAX_QUALIFIER_NAME_LEN SQL_MAX_TABLE_NAME_LEN
          SQL_MULT_RESULT_SETS SQL_MULTIPLE_ACTIVE_TXN SQL_OUTER_JOINS
          SQL_OWNER_TERM SQL_PROCEDURE_TERM SQL_QUALIFIER_NAME_SEPARATOR
          SQL_QUALIFIER_TERM SQL_SCROLL_CONCURRENCY SQL_SCROLL_OPTIONS
          SQL_TABLE_TERM SQL_TXN_CAPABLE SQL_USER_NAME SQL_CONVERT_FUNCTIONS
          SQL_NUMERIC_FUNCTIONS SQL_STRING_FUNCTIONS SQL_SYSTEM_FUNCTIONS
          SQL_TIMEDATE_FUNCTIONS SQL_CONVERT_BIGINT SQL_CONVERT_BINARY
          SQL_CONVERT_BIT SQL_CONVERT_CHAR SQL_CONVERT_DATE SQL_CONVERT_DECIMAL
          SQL_CONVERT_DOUBLE SQL_CONVERT_FLOAT SQL_CONVERT_INTEGER
          SQL_CONVERT_LONGVARCHAR SQL_CONVERT_NUMERIC SQL_CONVERT_REAL
          SQL_CONVERT_SMALLINT SQL_CONVERT_TIME SQL_CONVERT_TIMESTAMP
          SQL_CONVERT_TINYINT SQL_CONVERT_VARBINARY SQL_CONVERT_VARCHAR
          SQL_CONVERT_LONGVARBINARY SQL_TXN_ISOLATION_OPTION
          SQL_ODBC_SQL_OPT_IEF SQL_CORRELATION_NAME SQL_NON_NULLABLE_COLUMNS
          SQL_DRIVER_HLIB SQL_DRIVER_ODBC_VER SQL_LOCK_TYPES SQL_POS_OPERATIONS
          SQL_POSITIONED_STATEMENTS SQL_GETDATA_EXTENSIONS
          SQL_BOOKMARK_PERSISTENCE SQL_STATIC_SENSITIVITY SQL_FILE_USAGE
          SQL_NULL_COLLATION SQL_ALTER_TABLE SQL_COLUMN_ALIAS SQL_GROUP_BY
          SQL_KEYWORDS SQL_ORDER_BY_COLUMNS_IN_SELECT SQL_OWNER_USAGE
          SQL_QUALIFIER_USAGE SQL_QUOTED_IDENTIFIER_CASE SQL_SPECIAL_CHARACTERS
          SQL_SUBQUERIES SQL_UNION SQL_MAX_COLUMNS_IN_GROUP_BY
          SQL_MAX_COLUMNS_IN_INDEX SQL_MAX_COLUMNS_IN_ORDER_BY
          SQL_MAX_COLUMNS_IN_SELECT SQL_MAX_COLUMNS_IN_TABLE SQL_MAX_INDEX_SIZE
          SQL_MAX_ROW_SIZE_INCLUDES_LONG SQL_MAX_ROW_SIZE SQL_MAX_STATEMENT_LEN
          SQL_MAX_TABLES_IN_SELECT SQL_MAX_USER_NAME_LEN
          SQL_MAX_CHAR_LITERAL_LEN SQL_TIMEDATE_ADD_INTERVALS
          SQL_TIMEDATE_DIFF_INTERVALS SQL_NEED_LONG_DATA_LEN
          SQL_MAX_BINARY_LITERAL_LEN SQL_LIKE_ESCAPE_CLAUSE
          SQL_QUALIFIER_LOCATION SQL_INFO_LAST
       ) ],
    );
    Exporter::export_ok_tags(qw(sql_isolation_options sql_getinfo_options));

    require_version DBI 1.21;

    bootstrap DBD::TimesTen $VERSION;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $sqlstate = "00000";
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'TimesTen',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::TimesTen::err,
	    'Errstr' => \$DBD::TimesTen::errstr,
	    'State' => \$DBD::TimesTen::sqlstate,
	    'Attribution' => 'TimesTen DBD by Chad Wagner',
	    });

	$drh;
    }

    sub CLONE { undef $drh }

    sub AUTOLOAD {
        (my $constname = $AUTOLOAD) =~ s/.*:://;
        my $val = constant($constname); 
        *$AUTOLOAD = sub { $val };
        goto &$AUTOLOAD;
    }

    1;
}


{   package DBD::TimesTen::dr; # ====== DRIVER ======
    use strict;

    sub connect {
	my $drh = shift;
	my($dbname, $user, $auth, $attr)= @_;
	$user = '' unless defined $user;
	$auth = '' unless defined $auth;

	# create a 'blank' dbh
	my $this = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'USER' => $user, 
	    'CURRENT_USER' => $user,
	    });

	DBD::TimesTen::db::_login($this, $dbname, $user, $auth, $attr) or return undef;

	$this;
    }

}


{   package DBD::TimesTen::db; # ====== DATABASE ======
    use strict;

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	DBD::TimesTen::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }

    sub column_info {
	my ($dbh, $catalog, $schema, $table, $column) = @_;

	$catalog = "" if (!$catalog);
	$schema = "" if (!$schema);
	$table = "" if (!$table);
	$column = "" if (!$column);
	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLColumns" });

	DBD::TimesTen::db::_column_info($dbh,$sth, $catalog, $schema, $table, $column)
	    or return undef;

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

	$catalog = "" if (!$catalog);
	$schema = "" if (!$schema);
	$table = "" if (!$table);
	$type = "" if (!$type);

	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLTables" });

	DBD::TimesTen::db::_table_info($dbh,$sth, $catalog, $schema, $table, $type)
	      or return undef;
	$sth;
    }

    sub primary_key_info {
       my ($dbh, $catalog, $schema, $table ) = @_;
 
       # create a "blank" statement handle
       my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLPrimaryKeys" });
 
       $catalog = "" if (!$catalog);
       $schema = "" if (!$schema);
       $table = "" if (!$table);
       DBD::TimesTen::db::_primary_key_info($dbh, $sth, $catalog, $schema, $table)
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
       DBD::TimesTen::db::_foreign_key_info($dbh, $sth, $pkcatalog, $pkschema, $pktable, $fkcatalog, $fkschema, $fktable) or return undef;
       $sth;
    }

    sub ping {
	my $dbh = shift;
	my $state = undef;

 	my ($catalog, $schema, $table, $type);

	$catalog = "";
	$schema = "";
	$table = "NOXXTABLE";
	$type = "";

	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLTables_PING" });

	DBD::TimesTen::db::_table_info($dbh, $sth, $catalog, $schema, $table, $type)
	      or return 0;
	$sth->finish;
	return 1;

    }

    # New support for the next DBI which will have a get_info command.
    sub get_info {
	my ($dbh, $item) = @_;
	return DBD::TimesTen::db::_get_info($dbh, $item);
    }

    # new override of do method provided by Merijn Broeren
    # this optimizes "do" to use SQLExecDirect for simple
    # do statements without parameters.
    sub do {
        my($dbh, $statement, $attr, @params) = @_;
        my $rows = 0;
        if( -1 == $#params )
        {
          # No parameters, use execute immediate
          $rows = _ExecDirect( $dbh, $statement );
          if( 0 == $rows )
          {
            $rows = "0E0";
          }
          elsif( $rows < -1 )
          {
            undef $rows;
          }
        }
        else
        {
          $rows = $dbh->SUPER::do( $statement, $attr, @params );
        }
        return $rows
    }

    sub type_info_all {
	my ($dbh) = @_;
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
	DBD::TimesTen::db::_type_info($dbh, $sth, DBI::SQL_ALL_TYPES) or return undef;
	my $info = $sth->fetchall_arrayref;
	unshift @$info, {
	    map { ($sth->{NAME}->[$_] => $_) } 0..$sth->{NUM_OF_FIELDS}-1
	};
	return $info;
    }

}


{   package DBD::TimesTen::st; # ====== STATEMENT ======
    use strict;

    sub cancel {
	my $sth = shift;
	my $tmp = DBD::TimesTen::st::_cancel($sth);
	$tmp;
    }

    sub execute_for_fetch {
       my ($sth, $fetch_tuple_sub, $tuple_status) = @_;
       my $row_count = 0;
       my $tuple_count=0;
       my $tuple_batch_status;
       my $dbh = $sth->{Database};
       my $batch_size = ($dbh->{'tt_array_chunk_size'}||= 1000);

       if(defined($tuple_status)) {
           @$tuple_status = ();
           $tuple_batch_status = [ ];
       }

       while (1) {
           my @tuple_batch;
           for (my $i = 0; $i < $batch_size; $i++) {
                push @tuple_batch, [ @{$fetch_tuple_sub->() || last} ];
           }
           last unless @tuple_batch;
           my $res = _execute_array($sth,
                                    \@tuple_batch,
                                    scalar(@tuple_batch),
                                    $tuple_batch_status);
           if(defined($res) && defined($row_count)) {
                $row_count += $res;
           } else {
                $row_count = undef;
           }
           $tuple_count+=@$tuple_batch_status;
           push @$tuple_status, @$tuple_batch_status
           if defined($tuple_status);
       }
       if (!wantarray) {
           return undef if !defined $row_count;
           return $tuple_count;
       }
       return (defined $row_count ? $tuple_count : undef, $row_count);
    }
}

1;
__END__

=head1 NAME

DBD::TimesTen - TimesTen Driver for DBI

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect('dbi:TimesTen:DSN=...', 'user', 'password');

See L<DBI> for more information.

=head1 DESCRIPTION

=head2 Notes:

=over 4

=item B<An Important note about the tests!>

 Please note that some tests may fail or report they are
 unsupported on this platform.
   
=item B<Private DBD::TimesTen Attributes>

=item ttIgnoreNamedPlaceholders

Use this if you have special needs where :new or :name mean something
special and are not just placeholder names.  You I<must> then use ? for
binding parameters.  Example:

	$dbh->{ttIgnoreNamedPlaceholders} = 1;
	$dbh->do("create trigger foo as if :new.x <> :old.x then ... etc");

Without this, DBD::TimesTen will think :new and :old are placeholders for
binding and get confused.
 
=item ttDefaultBindType

This value defaults to 0, which means that DBD::TimesTen will attempt to
query the driver via SQLDescribeParam to determine the correct type.  This
parameter is overridden if you supply a data type with the bind_param() call.

=item ttExecDirect

Force DBD::TimesTen to use SQLExecDirect instead of SQLPrepare() then SQLExecute.
There are drivers that only support SQLExecDirect and the DBD::TimesTen
do() override doesn't allow returning result sets.  Therefore, the
way to do this now is to set the attributed ttExecDirect.

There are currently two ways to get this:
	$dbh->prepare($sql, { ttExecDirect => 1}); 
 and
	$dbh->{ttExecDirect} = 1;

When $dbh->prepare() is called with the attribute "ExecDirect" set to a
non-zero value dbd_st_prepare do NOT call SQLPrepare, but set the sth flag
ttExecDirect to 1.
 
=item ttQueryTimeout

This allows the end user to set a timeout for queries.  You can either set
this via the attributes parameter during the connect call, or you can directly
modify the attribute using $dbh->{ttQueryTimeout} = 30 after you have already
connected.

=item ttIsolationLevel

This allows the end user to set the isolation level.  You may need to
commit if you are changing isolation levels.  You can either set this via
the attributes parameter during the connect call, or you can directly
modify the attribute using $dbh->{ttIsolationLevel} after you have already
connected.  You must export the symbols using as follows:

	use DBI;
	use DBD::TimesTen qw(:sql_isolation_options);

	$dbh = DBI->connect('DBI:TimesTen:DSN=...', undef, undef,
	   { ttIsolationLevel => SQL_TXN_SERIALIZABLE });

The valid isolation levels are:

	SQL_TXN_READ_COMMITTED (default)
	SQL_TXN_SERIALIZABLE

   
=head2 Frequently Asked Questions

Answers to common DBI and DBD::TimesTen questions:

=over 4
 
=item Almost all of my tests for DBD::TimesTen fail.  They complain about
not being able to connect or the DSN is not found.  

Verify that you set DBI_DSN, DBI_USER, and DBI_PASS.

=cut
