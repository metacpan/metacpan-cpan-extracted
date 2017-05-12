#
#   engn/perldb2/DB2.pm, engn_perldb2, db2_v82fp9, 1.10 04/09/19 17:17:44
#
#   Copyright (c) 1995-2004  International Business Machines Corp.
#

{
    package DBD::DB2;

    use DBI;

    use DynaLoader;
    @ISA = qw(Exporter DynaLoader);

    @EXPORT_OK = qw( $attrib_dec
                     $attrib_int
                     $attrib_char
                     $attrib_float
                     $attrib_date
                     $attrib_ts
                     $attrib_binary
                     $attrib_blobfile
                     $attrib_clobfile
                     $attrib_dbclobfile );

    $VERSION = '1.85';
    require_version DBI 1.41;

    bootstrap DBD::DB2;

    use DBD::DB2::Constants;

    $err = 0;             # holds error code   for DBI::err
    $errstr = "";         # holds error string for DBI::errstr
    $state = "";          # holds SQL state for    DBI::state
    $drh = undef;         # holds driver handle once initialised

    $warn_success = $ENV{'WARNING_OK'};

    $attrib_dec = {
                    'db2_param_type' => SQL_PARAM_INPUT_OUTPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_DECIMAL,
                    'PRECISION'      => 31,
                    'SCALE'          => 4,
                  };
    $attrib_int = {
                    'db2_param_type' => SQL_PARAM_INPUT_OUTPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_INTEGER,
                    'PRECISION'      => 10,
                  };
    $attrib_char = {
                    'db2_param_type' => SQL_PARAM_INPUT_OUTPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_CHAR,
                    'PRECISION'      => 0,
                  };
    $attrib_float = {
                    'db2_param_type' => SQL_PARAM_INPUT_OUTPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_FLOAT,
                    'PRECISION'      => 15,
                    'SCALE'          => 6,
                  };
    $attrib_date = {
                    'db2_param_type' => SQL_PARAM_INPUT_OUTPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_DATE,
                    'PRECISION'      => 10,
                  };
    $attrib_ts = {
                    'db2_param_type' => SQL_PARAM_INPUT_OUTPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_TIMESTAMP,
                    'PRECISION'      => 26,
                    'SCALE'          => 11,
                  };
    $attrib_binary = {
                    'db2_param_type' => SQL_PARAM_INPUT_OUTPUT,
                    'db2_c_type'     => SQL_C_BINARY,
                    'db2_type'       => SQL_BINARY,
                    'PRECISION'      => 0,
                  };
    $attrib_blobfile = {
                    'db2_param_type' => SQL_PARAM_INPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_BLOB,
                    'db2_file'       => 1,
                  };
    $attrib_clobfile = {
                    'db2_param_type' => SQL_PARAM_INPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_CLOB,
                    'db2_file'       => 1,
                  };
    $attrib_dbclobfile = {
                    'db2_param_type' => SQL_PARAM_INPUT,
                    'db2_c_type'     => SQL_C_CHAR,
                    'db2_type'       => SQL_DBCLOB,
                    'db2_file'       => 1,
                  };

    sub driver{
        return $drh if $drh;
        my($class, $attr) = @_;

        $class .= "::dr";

        # not a 'my' since we use it above to prevent multiple drivers

        $drh = DBI::_new_drh($class, {
            'Name' => 'DB2',
            'Version' => $VERSION,
            'Err'    => \$DBD::DB2::err,
            'Errstr' => \$DBD::DB2::errstr,
            'State'  => \$DBD::DB2::state,
            'Attribution' => 'DB2 DBD by IBM',
            });

        $drh;
    }

    sub CLONE{
        undef $drh;
    }

    1;
}


{   package DBD::DB2::dr; # ====== DRIVER ======
    use strict;

    sub connect {

        my($drh, $dbname, $user, $auth, $attr)= @_;

        # create a 'blank' dbh

        my $this = DBI::_new_dbh($drh, {
            'Name' => $dbname,
            'USER' => $user, 'CURRENT_USER' => $user
            });

        DBD::DB2::db::_login($this, $dbname, $user, $auth, $attr)
            or return undef;

        $this;
    }

    sub data_sources {
        my ($drh, $attr) = @_;
        my $dsref = DBD::DB2::dr::_data_sources( $drh, $attr );
        if( defined( $dsref ) &&
            ref( $dsref ) eq "ARRAY" )
        {
          return @$dsref;
        }
        return ();  # Return empty array
    }
}


{   package DBD::DB2::db; # ====== DATABASE ======
    use strict;

    sub do {
        my($dbh, $statement, $attr, @params) = @_;
        my $rows = 0;

        if( -1 == $#params )
        {
          # No parameters, use execute immediate
          $rows = DBD::DB2::db::_do( $dbh, $statement );
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

    sub prepare {
        my($dbh, $statement)= @_;

        # create a 'blank' dbh

        my $sth = DBI::_new_sth($dbh, {
            'Statement' => $statement,
            });

        DBD::DB2::st::_prepare($sth, $statement)
            or return undef;

        $sth;
    }

    sub ping {
        my($dbh) = @_;
        DBD::DB2::db::_ping( $dbh );
    }

    sub table_info {
        my( $dbh, $ctlg, $schema, $table, $type ) = @_;
        my $attr = {};

        if(ref($ctlg) eq "HASH") {
          $attr = $ctlg;
        } else {
          $attr = {'TABLE_SCHEM' => $schema,
                   'TABLE_TYPE' => $type,
                   'TABLE_NAME' => $table};
        }

        my $sth = DBI::_new_sth($dbh, {});
        DBD::DB2::st::_table_info( $sth, $attr )
           or return undef;

        $sth;
    }

    sub primary_key_info
    {
       my( $dbh, $catalog, $schema, $table ) = @_;
       my $sth = DBI::_new_sth( $dbh, {} );
       DBD::DB2::st::_primary_key_info( $sth, $catalog, $schema, $table )
          or return undef;

       $sth;
    }

    sub foreign_key_info
    {
       my( $dbh, $pkcat, $pkschema, $pktable, $fkcat, $fkschema, $fktable ) = @_;
       my $sth = DBI::_new_sth( $dbh, {} );
       DBD::DB2::st::_foreign_key_info( $sth, $pkcat, $pkschema, $pktable,
                                              $fkcat, $fkschema, $fktable )
          or return undef;

       $sth;
    }

    sub column_info
    {
       my( $dbh, $cat, $schema, $table, $column ) = @_;
       my $sth = DBI::_new_sth( $dbh, {} );

       # Applications can use undef instead of NULL, and they are not the same
       # We have to map undef to "match all" here before going into C code

       if( !defined($cat) )
       {
          $cat = "";
       }

       if( !defined($schema) )
       {
          $schema = "%";
       }

       if( !defined($table) )
       {
          $table = "%";
       }

       if( !defined($column) )
       {
          $column = "%";
       }

       DBD::DB2::st::_column_info( $sth, $cat, $schema, $table, $column )
          or return undef;

       $sth;
    }

    sub type_info_all
    {
       my( $dbh ) = @_;

       my $cols =
       {
          TYPE_NAME          => 0,
          DATA_TYPE          => 1,
          COLUMN_SIZE        => 2,
          LITERAL_PREFIX     => 3,
          LITERAL_SUFFIX     => 4,
          CREATE_PARAMS      => 5,
          NULLABLE           => 6,
          CASE_SENSITIVE     => 7,
          SEARCHABLE         => 8,
          UNSIGNED_ATTRIBUTE => 9,
          FIXED_PREC_SCALE   => 10,
          AUTO_UNIQUE_VALUE  => 11,
          LOCAL_TYPE_NAME    => 12,
          MINIMUM_SCALE      => 13,
          MAXIMUM_SCALE      => 14,
          SQL_DATA_TYPE      => 15,
          SQL_DATETIME_SUB   => 16,
          NUM_PREC_RADIX     => 17,
          INTERVAL_PRECISION => 18
       };

       my $type_info_all = [ $cols ];

       my $sth = DBI::_new_sth( $dbh, {} );
       DBD::DB2::st::_type_info_all( $sth ) or return undef;
       push( @$type_info_all, @{$sth->fetchall_arrayref} );
       $sth->finish;

       return $type_info_all;
    }

    sub get_info
    {
      my( $dbh, $infotype ) = @_;
      my $v = DBD::DB2::db::_get_info( $dbh, $infotype );
      return $v;
    }

}


{   package DBD::DB2::st; # ====== STATEMENT ======
    use strict;

}

1;
