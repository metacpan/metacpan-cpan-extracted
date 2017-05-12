# ***************************************************************************
# Copyright (c) 2015 SAP SE or an SAP affiliate company. All rights reserved.
# ***************************************************************************
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#   While not a requirement of the license, if you do modify this file, we
#   would appreciate hearing about it. Please email
#   sqlany_interfaces@sybase.com
#
#====================================================
require 5.002;
use strict;
use warnings;
{
    package DBD::SQLAnywhere;

    use DBI ();
    use DynaLoader ();
    use Exporter ();

    our $VERSION = '2.13';
    our @ISA = qw(DynaLoader Exporter);
    our %EXPORT_TAGS = (
	asa_types => [ qw(
	    ASA_SMALLINT ASA_INT ASA_DECIMAL ASA_FLOAT ASA_DOUBLE ASA_DATE
	    ASA_STRING ASA_FIXCHAR ASA_VARCHAR ASA_LONGVARCHAR ASA_TIME
	    ASA_TIMESTAMP ASA_TIMESTAMP_STRUCT ASA_BINARY ASA_LONGBINARY
	    ASA_VARIABLE ASA_TINYINT ASA_BIGINT ASA_UNSINT ASA_UNSSMALLINT
	    ASA_UNSBIGINT ASA_BIT ) ],
    );
    Exporter::export_ok_tags( 'asa_types' );

    my $Revision = substr(q$Revision: 1.57 $, 10);

    require_version DBI 1.51;

    bootstrap DBD::SQLAnywhere $VERSION;

    our $err = 0;		# holds error code   for DBI::err    (XXX SHARED!)
    our $errstr = "";	# holds error string for DBI::errstr (XXX SHARED!)
    our $drh = undef;	# holds driver handle once initialised

    sub CLONE {
	$drh = undef;
    }

    sub driver {
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'SQLAnywhere',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::SQLAnywhere::err,
	    'Errstr' => \$DBD::SQLAnywhere::errstr,
	    'Attribution' => 'SQLAnywhere DBD by John Smirnios',
	    });

	if( !DBD::SQLAnywhere::dr::driver_init( $drh ) ) {
	    undef( $drh );
	}

	$drh;
    }

    1;
}


{   package DBD::SQLAnywhere::dr; # ====== DRIVER ======
    use strict;

    sub connect {
	my($drh, $dbname, $user, $auth, $attr)= @_;

	# NOTE!
	# 
	# For SQLAnywhere, $dbname and $user are appended to form an
	# SQLAnywhere connection string. 'UID=' is prefixed onto $user
	# if necessary. If $auth is nonempty, 'PWD=' is prefixed.
	# If dbname starts with something that doesn't look like
	# a connect string parameter ('label=value;' format) then
	# 'ENG=' is prefixed.
	my $conn_str;
	my $sqlcap;

	if( defined( $dbname ) ) {
	    $conn_str = $dbname;
	    $conn_str =~ s/^[\s;]*//;
	    $conn_str =~ s/[\s;]*$//;
	    if( $conn_str =~ /^[^=;]+($|;)/ ) {
		$conn_str = 'ENG=' . $conn_str;
	    }
	    
	    # look for undocumented option indicating the sqlca to use for
	    # server-side perl
	    if( $conn_str =~ /^ENG=saperl;sa_perl_sqlca=(0x)?([0-9a-fA-F]*)$/ ) {
	    	$sqlcap = $2;
	    }
	} else {
	    $conn_str = '';
	}
	if( defined( $user ) && ($user ne '') ) {
	    if( $user =~ /=/ ) {
		$conn_str .= ';' . $user;
	    } else {
		$conn_str .= ';UID=' . $user;
	    }
	}
	if( defined( $auth ) && ($auth ne '') ) {
	    $conn_str .= ';PWD=' . $auth;
	}

	# create a 'blank' dbh
	my $dbh = DBI::_new_dbh($drh, {
	    'Name' => $conn_str,
	    'USER' => $user, 'CURRENT_USER' => $user,
	    });

	# Call SQLAnywhere connect func in SQLAnywhere.xs file
	# and populate internal handle data.

	if( !DBD::SQLAnywhere::db::_login($dbh, $conn_str, 
					  (defined $sqlcap) ? $sqlcap : '', '', $attr) ) {
	    return undef;
	}

	$dbh;
    }
}


{   package DBD::SQLAnywhere::db; # ====== DATABASE ======
    use strict;

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' sth

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call SQLAnywhere OCI oparse func in SQLAnywhere.xs file.
	# (This will actually also call oopen for you.)
	# and populate internal handle data.

	DBD::SQLAnywhere::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }

    sub ping {
	my( $dbh ) = @_;

	# Doing a prepare() will actually talk to the server and so this
	# is a cheap test.
	# Strictly speaking, the prepare() could fail due to an error
	# reported from the server (eg. if we exceed the prepared statement
	# limit) but we don't have access to the ping facility through DBCAPI
	# so this is usually a valid test.
	my $rv = eval { $dbh->prepare( "select 1" ); };
	my $alive = ( defined( $rv ) ? 1 : 0 );

	# Suppress the error for ping() -- it should just return a boolean without reporting error
	$dbh->set_err( undef, undef );

	return( $alive );
    }


# Use the DBI-provided quote routine
#    sub quote {
#	my($dbh, $value) = @_;
#	return $value;
#    }


#    sub quote_identifier {
#	my($dbh, $name) = @_;
#	return "\"".$name."\"";
#    }


    sub table_info {
	my($dbh,$catalogue,$schema,$table,$type)       = @_;		# XXX add qualification

	if ( !defined($schema) || $schema eq "" ) {
	    $schema = '%';
	}

	if ( !defined($table) || $table eq "" ) {
	    $table = '%';
	}

	if ( !defined($type) || $type eq "" ) {
	    # $type = 'TABLE,VIEW,SYSTEM TABLE,GLOBAL TEMPORARY,LOCAL TEMPORARY,ALIAS,SYNONYM';
	    $type = '%';
	}

	my $sth = $dbh->prepare("
        select
	    NULL as TABLE_CAT,
	    u.user_name as TABLE_SCHEM,
	    t.table_name as TABLE_NAME,
	    (if t.table_type = 'BASE' then (if t.creator = 0 then 'SYSTEM ' else '' endif) ||'TABLE'
		else (if t.table_type = 'GBL TEMP' then 'GLOBAL TEMPORARY' 
		      else t.table_type
		      endif)
		endif) as TABLE_TYPE,
	    t.remarks as REMARKS
	from SYS.SYSTABLE t, SYS.SYSUSER u
	where t.creator = u.user_id
	  and u.user_name  like ?
 	  and t.table_name like ?
	  and TABLE_TYPE   like ?
	order by u.user_name, t.table_name
	") or return undef;
# and TABLE_TYPE  IN (?)
	$sth->bind_param( 1, $schema );
	$sth->bind_param( 2, $table );
	$sth->bind_param( 3, $type );
	$sth->execute or return undef;
	$sth;
    }


    sub type_info_all {
	my ($dbh) = @_;
	my $names = {
	    TYPE_NAME		=> 0,
	    DATA_TYPE		=> 1,
	    COLUMN_SIZE		=> 2,
	    LITERAL_PREFIX	=> 3,
	    LITERAL_SUFFIX	=> 4,
	    CREATE_PARAMS	=> 5,
	    NULLABLE		=> 6,
	    CASE_SENSITIVE	=> 7,
	    SEARCHABLE		=> 8,

	    UNSIGNED_ATTRIBUTE	=> 9,
	    FIXED_PREC_SCALE	=>10,
	    AUTO_UNIQUE_VALUE	=>11,
	    LOCAL_TYPE_NAME	=>12,
	    MINIMUM_SCALE	=>13,
	    MAXIMUM_SCALE	=>14,
	    SQL_DATA_TYPE	=>15,
	    SQL_DATETIME_SUB	=>16,
	    NUM_PREC_RADIX	=>17,
	};
	my $ti = [
	  $names,
	    [ 'bit', -7, 1, undef, undef, undef, 1, 0, 3,
	      1, undef, 0, undef, undef, undef, -7, undef, undef
	    ],
	    [ 'tinyint', -6, 4, undef, undef, undef, 1, 0, 3,
	      0, undef, 0, undef, undef, undef, -6, undef, undef
	    ],
	    [ 'bigint', -5, 20, undef, undef, undef, 1, 0, 3,
	      0, undef, 0, undef, undef, undef, -5, undef, undef
	    ],
	    [ 'unsigned bigint', -5, 20, undef, undef, undef, 1, 0, 3,
	      1, undef, 0, undef, undef, undef, -5, undef, undef
	    ],
	    [ 'long binary', -4, 2147483647, '\'', '\'', undef, 1, 0, 3,
	      undef, undef, undef, undef, undef, undef, -4, undef, undef
	    ],
	    [ 'binary', -2, 65535, '\'', '\'', 'max length', 1, 0, 3,
	      undef, undef, undef, undef, undef, undef, -2, undef, undef
	    ],
	    [ 'varbinary', -2, 65535, '\'', '\'', 'max length', 1, 0, 3,
	      undef, undef, undef, undef, undef, undef, -2, undef, undef
	    ],
	    [ 'long varchar', -1, 2147483647, '\'', '\'', undef, 1, 0, 3,
	      undef, undef, undef, undef, undef, undef, -1, undef, undef
	    ],
	    [ 'char', 1, 65535, '\'', '\'', 'max length', 1, 0, 3,
	      undef, undef, undef, undef, undef, undef, 1, undef, undef
	    ],
	    [ 'decimal', 2, 127, undef, undef, 'precision, scale', 1, 0, 3,
	      0, 0, 0, undef, 0, 127, 2, undef, 10
	    ],
	    [ 'numeric', 2, 127, undef, undef, 'precision, scale', 1, 0, 3,
	      0, 0, 0, undef, 0, 127, 2, undef, 10
	    ],
	    [ 'money', 3, 4, undef, undef, undef, 1, 0, 3,
	      0, 1, 0, undef, 4, 4, 3, undef, 10
	    ],
	    [ 'smallmoney', 3, 4, undef, undef, undef, 1, 0, 3,
	      0, 1, 0, undef, 4, 4, 3, undef, 10
	    ],
	    [ 'integer', 4, 10, undef, undef, undef, 1, 0, 3,
	      0, undef, 0, undef, 0, 0, 4, undef, undef
	    ],
	    [ 'unsigned int', 4, 10, undef, undef, undef, 1, 0, 3,
	      1, undef, 0, undef, undef, undef, 4, undef, undef
	    ],
	    [ 'smallint', 5, 6, undef, undef, undef, 1, 0, 3,
	      0, undef, 0, undef, 0, 0, 5, undef, undef
	    ],
	    [ 'unsigned smallint', 5, 5, undef, undef, undef, 1, 0, 3,
	      1, undef, 0, undef, undef, undef, 5, undef, undef
	    ],
	    [ 'double', 6, 64, undef, undef, undef, 1, 0, 3,
	      0, undef, 0, undef, undef, undef, 6, undef, 2
	    ],
	    [ 'float', 7, undef, undef, undef, undef, 1, 0, 3,
	      0, undef, 0, undef, undef, undef, 7, undef, 32
	    ],
	    [ 'double', 8, 64, undef, undef, undef, 1, 0, 3,
	      0, undef, 0, undef, undef, undef, 8, undef, 2
	    ],
	    [ 'varchar', 12, 65535, '\'', '\'', 'max length', 1, 0, 3,
	      undef, undef, undef, undef, undef, undef, 12, undef, undef
	    ]
        ];
	return $ti;
    }


    sub column_info {
	my($dbh,$catalogue,$schema,$table,$column)       = @_;		# XXX add qualification

	if( !defined($schema) || $schema eq "" ) {
	    $schema = '%';
	}

	if( !defined($table) || $table eq "" ) {
	    $table = '%';
	}

	if( !defined($column) || $column eq "" ) {
	    $column = '%';
	}

	my $sth = $dbh->prepare("
        select
	    NULL as TABLE_CAT,
	    u.user_name as TABLE_SCHEM,
	    t.table_name as TABLE_NAME,
	    c.column_name as COLUMN_NAME,
	    d.domain_id as DATA_TYPE, 
            d.domain_name AS TYPE_NAME,
	    c.width AS COLUMN_SIZE,
	    c.width AS BUFFER_LENGTH,
            c.width AS DECIMAL_DIGITS, 
	    c.scale AS NUM_PREC_RADIX,
	    IF c.nulls = 'Y' THEN 1 ELSE 0 ENDIF AS NULLABLE,
	    c.remarks AS REMARKS,
            c.\"default\" AS COLUMN_DEF, 
            d.domain_name AS SQL_DATA_TYPE,
            NULL AS SQL_DATETIME_SUB,
	    c.width AS CHAR_OCTET_LENGTH,
	    c.column_id AS ORDINAL_POSITION,
	    c.nulls AS IS_NULLABLE,
            NULL AS CHAR_SET_CAT,
	    NULL AS CHAR_SET_SCHEM,
	    NULL AS CHAR_SET_NAME,
	    NULL AS COLLATION_CAT,
	    NULL AS COLLATION_SCHEM,
	    NULL AS COLLATION_NAME,
	    NULL AS UDT_CAT,
	    NULL AS UDT_SCHEM,
	    NULL AS UDT_NAME,
	    NULL AS DOMAIN_CAT,
	    NULL AS DOMAIN_SCHEM,
	    NULL AS DOMAIN_NAME,
	    NULL AS SCOPE_CAT,
	    NULL AS SCOPE_SCHEM,
	    NULL AS SCOPE_NAME,
	    NULL AS MAX_CARDINALITY,
	    NULL AS DTD_IDENTIFIER,
	    NULL AS IS_SELF_REF
	    from SYS.SYSTABLE t
	   , SYS.SYSUSER u
	   , SYS.SYSCOLUMN c
	   , SYS.SYSDOMAIN d
	where t.creator     = u.user_id
	  and t.table_id    = c.table_id
	  and c.domain_id   = d.domain_id
	  and u.user_name   like ?
	  and t.table_name  like ?
	  and c.column_name like ?
	order by c.column_id
	") or return undef;
	$sth->bind_param(1, $schema); 
	$sth->bind_param(2, $table); 
	$sth->bind_param(3, $column); 
	$sth->execute or return undef;
	$sth;
    }


    sub primary_key_info {
	my($dbh,$catalogue,$schema,$table,$column)       = @_;		# XXX add qualification

	if ( !defined($schema) || $schema eq "" ) {
	    $schema = '%';
	}

	if ( !defined($table) || $table eq "" ) {
	    $table = '%';
	}

	if ( !defined($column) || $column eq "" ) {
	    $column = '%';
	}

	my $sth = $dbh->prepare("
        select
	    NULL as TABLE_CAT,
	    u.user_name as TABLE_SCHEM,
	    t.table_name as TABLE_NAME,
	    c.column_name as COLUMN_NAME,
	    c.column_id AS KEY_SEQ,
	    i.index_name as PK_NAME
	from SYS.SYSTABLE t
       , SYS.SYSUSER u
       , SYS.SYSCOLUMN c
       , SYS.SYSIDX i
	where t.creator     = u.user_id
	  and t.table_id    = c.table_id
	  and t.table_id    = i.table_id
	  and i.index_id    = 0
      and c.pkey        = 'Y'
      and u.user_name   like ?
      and t.table_name  like ?
      and c.column_name like ?
    order by c.column_id
	") or return undef;
	$sth->bind_param(1, $schema); 
	$sth->bind_param(2, $table); 
	$sth->bind_param(3, $column); 
	$sth->execute or return undef;
	$sth;
    }

    sub get_info {
        my($dbh, $info_type) = @_;
        require DBD::SQLAnywhere::GetInfo;
        my $v = $DBD::SQLAnywhere::GetInfo::info{int($info_type)};
        $v = $v->($dbh) if ref $v eq 'CODE';
        return $v;
    }

    sub statistics_info {
	my($dbh,$catalogue,$schema,$table,$unique_only,$quick) = @_;	# XXX add qualification

	if ( !defined($schema) || $schema eq "" ) {
	    $schema = '%';
	}

	if ( !defined($table) || $table eq "" ) {
	    $table = '%';
	}

	if ( defined($unique_only) && $unique_only == 1 ) {
	    $unique_only = 2;
	}

        # quick ignored for now
	if ( !defined($quick) || $quick eq "" || $quick != 1 ) {
	    $quick = 0;
	}

	my $sth = $dbh->prepare("
        select
	    NULL as TABLE_CAT,
	    u.user_name as TABLE_SCHEM,
	    t.table_name as TABLE_NAME,
	    IF i.\"unique\" = '1' THEN 1 ELSE 0 ENDIF as NON_UNIQUE,
	    t.table_name ||'.'|| i.index_name as INDEX_QUALIFIER,
	    i.index_name as INDEX_NAME,
	    'table' as TYPE,
	    NULL as ORDINAL_POSITION,
	    NULL as COLUMN_NAME,
	    NULL as ASC_OR_DESC,
	    NULL as CARDINALITY,
	    NULL as PAGES,
	    NULL as FILTER_CONDITION
	from SYS.SYSTABLE t
	, SYS.SYSUSER u
	, SYS.SYSIDX i
	where t.creator  = u.user_id
	  and t.table_id = i.table_id
	  and u.user_name  like ?
 	  and t.table_name like ?
 	  and i.\"unique\"     like ?
	order by u.user_name, t.table_name
	") or return undef;
	$sth->bind_param( 1, $schema );
	$sth->bind_param( 2, $table );
	$sth->bind_param( 3, $unique_only );
#	$sth->bind_param( 4, $quick );
	$sth->execute or return undef;
	$sth;
    }

    sub last_insert_rowid {
	my($dbh,$source,$col) = @_;

	my $sth = $dbh->prepare("
         select \@\@IDENTITY
	") or return undef;
	$sth->execute or return undef;
        my @ida = $sth->fetchrow_array();
        return @ida ? $ida[0] : undef;
    }


}   # end of package DBD::SQLAnywhere::db


{   package DBD::SQLAnywhere::st; # ====== STATEMENT ======

    # all done in XS
}

1;

__END__

=head1 NAME

DBD::SQLAnywhere - SQLAnywhere database driver for DBI

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect( "dbi:SQLAnywhere:ENG=demo;UID=$userid;PWD=$passwd", '', '' );

  $dbh = DBI->connect( 'dbi:SQLAnywhere:ENG=demo', $userid, $passwd );

  # Use 'perldoc DBI' for detailed information about DBI.

=head1 DESCRIPTION

DBD::SQLAnywhere is a Perl database driver (DBD) module that works
with the L<DBI> module to provide access to Sybase SQL Anywhere
databases.

=head2 Connecting to SQL Anywhere

If you are not already familiar with SQL Anywhere connection
parameters, please refer to the SQL Anywhere documentation.

SQL Anywhere connection parameters can be passed to DBD::SQLAnywhere
by placing the list of parameters after 'dbi:SQLAnywhere:' in the
first parameter to connect(). The connection parameters are specified
as a list of LABEL=value pairs that are delimited by semicolons.

Example:

    $dbh = DBI->connect( 'dbi:SQLAnywhere:ENG=demo;UID=dba;PWD=sql', '', '' );

If the second argument to connect() is nonblank, it is assumed to be a
user name and UID=argument2 will be appended to the SQL Anywhere
connection string.

Similarly, if the third argument is nonblank, it is assumed to be a
password and PWD=argument3 will be appended to the SQL Anywhere
connection string.

The following is equivalent to the example above:

    $dbh = DBI->connect( 'dbi:SQLAnywhere:ENG=demo', 'dba', 'sql' );

=head2 Prepared Statement and Cursor Limits

To help detect handle leaks in client applications, SQL Anywhere
defaults to limiting the number of prepared statements and open
cursors that any connection can hold at one time to 50 of each. If
that limit is exceeded, a "Resource governor ... exceeded" error is
reported. If you encounter this error, make sure you are dropping all
of your statement handles and, if so, consult the SQL Anywhere
documentation for the MAX_CURSOR_COUNT and MAX_STATEMENT_COUNT
options.

Note that prepared statements are not dropped from the SQL Anywhere
server until the statement handle is destroyed in the perl
script. Calling finish() is not sufficient to drop the handle that the
server is holding onto: use "undef" instead or reuse the same perl
variable for another handle.

Be careful when using prepare_cached() since the cache will
hold onto statement handles.

=head1 REQUIREMENTS

As of version 2.0, DBD::SQLAnywhere can be built (but not used)
without SQL Anywhere installed. To use DBD::SQLAnywhere, an
installation of the SQL Anywhere client software is required and must
include the "dbcapi" component (dbcapi.dll on Windows and
libdbcapi.so/libdbcapi_r.so on UNIX). Dbcapi is included in the client
installation of SQL Anywhere 11.0.0 and later. To use SQL Anywhere
version 10.0.0 or 10.0.1 with this DBD driver, download and
install a current EBF for your version of SQL Anywhere from
www.sybase.com.

=head1 DEPENDENCIES

L<DBI>

L<Test::Simple>

=head1 AUTHOR

John Smirnios (john.smirnios@sap.com).

Based on a driver written by Tim Bunce.

=head1 COPYRIGHT

Portions Copyright (c) 1994,1995,1996           Tim Bunce
Portions Copyright (c) 2015			SAP SE or an SAP affiliate company

For license information, please see license.txt included in this
distribution.

=cut
