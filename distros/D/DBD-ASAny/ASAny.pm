require 5.002;


$DBD::ASAny::VERSION = '1.14';

{
    package DBD::ASAny;

    use DBI ();
    use DynaLoader ();
    use Exporter ();
    @ISA = qw(DynaLoader Exporter);
    %EXPORT_TAGS = (
	asa_types => [ qw(
	    ASA_SMALLINT ASA_INT ASA_DECIMAL ASA_FLOAT ASA_DOUBLE ASA_DATE
	    ASA_STRING ASA_FIXCHAR ASA_VARCHAR ASA_LONGVARCHAR ASA_TIME
	    ASA_TIMESTAMP ASA_TIMESTAMP_STRUCT ASA_BINARY ASA_LONGBINARY
	    ASA_VARIABLE ASA_TINYINT ASA_BIGINT ASA_UNSINT ASA_UNSSMALLINT
	    ASA_UNSBIGINT ASA_BIT ) ],
    );
    Exporter::export_ok_tags( 'asa_types' );

    my $Revision = substr(q$Revision: 1.57 $, 10);

    require_version DBI 1.02;

    bootstrap DBD::ASAny $VERSION;

    $err = 0;		# holds error code   for DBI::err    (XXX SHARED!)
    $errstr = "";	# holds error string for DBI::errstr (XXX SHARED!)
    $drh = undef;	# holds driver handle once initialised

    sub CLONE {
	$drh = undef;
    }

    sub driver {
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'ASAny',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::ASAny::err,
	    'Errstr' => \$DBD::ASAny::errstr,
	    'Attribution' => 'ASAny DBD by John Smirnios',
	    });

	$drh;
    }

    1;
}


{   package DBD::ASAny::dr; # ====== DRIVER ======
    use strict;

    sub connect {
	my($drh, $dbname, $user, $auth)= @_;

	# NOTE!
	# 
	# For ASA, $dbname and $user are appended to form an
	# ASA connection string. 'UID=' is prefixed onto $user
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
	    if( $conn_str =~ /^ENG=saperl;sa_perl_sqlca=([0-9a-fA-F]*)$/ ) {
	    	$sqlcap = $1;
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

	# Call ASAny connect func in ASAny.xs file
	# and populate internal handle data.

	DBD::ASAny::db::_login($dbh, $conn_str, 
			       (defined $sqlcap) ? $sqlcap : '', '')
	    or return undef;

	$dbh;
    }
}


{   package DBD::ASAny::db; # ====== DATABASE ======
    use strict;

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' sth

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call ASAny OCI oparse func in ASAny.xs file.
	# (This will actually also call oopen for you.)
	# and populate internal handle data.

	DBD::ASAny::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }


    sub ping {
	my($dbh) = @_;
	# we know that DBD::ASAny prepare does a describe so this will
	# actually talk to the server and is a valid and cheap test.
	return 1 if $dbh->prepare("select 1");
	return 0;
    }


    sub table_info {
	my($dbh) = @_;		# XXX add qualification

	my $sth = $dbh->prepare("select
	    NULL as TABLE_CAT,
	    u.user_name as TABLE_SCHEM,
	    t.table_name as TABLE_NAME,
	    (if t.table_type = 'BASE' then (if t.creator = 0 then 'SYSTEM ' else '' endif) ||'TABLE'
		else (if t.table_type = 'GBL TEMP' then 'GLOBAL TEMPORARY' 
		      else t.table_type
		      endif)
		endif) as TABLE_TYPE,
	    t.remarks as REMARKS
	from SYSTABLE t, SYSUSERPERM u
	where t.creator = u.user_id
	") or return undef;
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
}   # end of package DBD::ASAny::db


{   package DBD::ASAny::st; # ====== STATEMENT ======

    # all done in XS
}

1;

__END__

