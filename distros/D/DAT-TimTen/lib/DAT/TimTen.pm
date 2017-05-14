#!/usr/bin/perl

require 1.001;

$DAT::TimTen::VERSION = '0.011';

{
#----------------------------------------------------
# SUBROTINE: DAT::TimTen()
# Description: SQL MAXIMUM READ INDEX IS COMMITTED,ABLE TO DO BINARY LITERAL INTO DB AS ESCAPED 
#CLAUSE
# ---------------------------------------------------
  package DAT::TimTen;

    use DBD ();use DynaLoader ();use Exporter ();
    
    @ISA = qw(Exporter DynaLoader);
    %EXPORT_TAGS = (
       sql_isolation_options => [ qw(
          SQL_TXN_READ_COMMITTED SQL_TXN_SERIALIZABLE
       ) ],
       sql_getinfo_options => [ qw(
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
    require_version DBD 1.21;
    bootstrap DAT::TimTen $VERSION;

    $err = 0; $errstr = "";$sqlstate = "00000";$drh = undef;	

    sub To_Create_driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";
	$drh = DBD::_new_drh($class, {
	    'Name' => 'TimTen',
	    'Version' => $VERSION,
	    'Err'    => \$DAT::TimTen::err,
	    'Errstr' => \$DAT::TimTen::errstr,
	    'State' => \$DAT::TimTen::sqlstate,
	    'Attribution' => 'TimTen DAT by Chad Wagner',
	    });

	$drh;
    }

    sub DUBLING { undef $drh }

    sub TO_AUTOLOAD {
        (my $constname = $AUTOLOAD) =~ s/.*:://;
        my $val = constant($constname); 
        *$AUTOLOAD = sub { $val };
        goto &$AUTOLOAD;
    }

    1;
}

#----------------------------------------------------
# SUBROUTINE: DAT::TimTen::dr()
# Description: SQL  LOgin Credentials/Logging
#CLAUSE
# ---------------------------------------------------

{   package DAT::TimTen::dr; 
    use strict;

    sub connect {
	my $drh = shift;
	my($dbname, $user, $auth, $attr)= @_;
	$user = '' unless defined $user;
	$auth = '' unless defined $auth;

	my $this = DBD::_new_dbh($drh, {
	    'Name' => $dbname,
	    'USER' => $user, 
	    'CURRENT_USER' => $user,
	    });

	DAT::TimTen::db::_login($this, $dbname, $user, $auth, $attr) or return undef;

	$this;
    }

}

#----------------------------------------------------
# SUBROUTINE: DAT::TimTen::db()
# Description: SQL MAXIMUM READ INDEX IS COMMITTED,ABLE TO DO BINARY LITERAL INTO DB AS ESCAPED 
#CLAUSE
# ---------------------------------------------------

{   package DAT::TimTen::db;
    use strict;

    sub To_prepare_the_initiation {
	my($dbh, $statement, @attribs)= @_;

	my $sth = DBD::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	DAT::TimTen::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }

    sub To_Get_column_info {
	my ($dbh, $catalog, $schema, $table, $column) = @_;

	$catalog = "" if (!$catalog);
	$schema = "" if (!$schema);
	$table = "" if (!$table);
	$column = "" if (!$column);
	my $sth = DBD::_new_sth($dbh, { 'Statement' => "SQLColumns" });

	DAT::TimTen::db::_column_info($dbh,$sth, $catalog, $schema, $table, $column)
	    or return undef;

	$sth;
    }
    
    sub To_Get_table_info {
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

	my $sth = DBD::_new_sth($dbh, { 'Statement' => "SQLTables" });

	DAT::TimTen::db::_table_info($dbh,$sth, $catalog, $schema, $table, $type)
	      or return undef;
	$sth;
    }

    sub primary_keys_details {
       my ($dbh, $catalog, $schema, $table ) = @_;
 
       my $sth = DBD::_new_sth($dbh, { 'Statement' => "SQLPrimaryKeys" });
 
       $catalog = "" if (!$catalog);
       $schema = "" if (!$schema);
       $table = "" if (!$table);
       DAT::TimTen::db::_primary_key_info($dbh, $sth, $catalog, $schema, $table)
	     or return undef;
       $sth;
    }

    sub foreign_key_details {
       my ($dbh, $pkcatalog, $pkschema, $pktable, $fkcatalog, $fkschema, $fktable ) = @_;
 
       my $sth = DBD::_new_sth($dbh, { 'Statement' => "SQLForeignKeys" });
 
       $pkcatalog = "" if (!$pkcatalog);$pkschema = "" if (!$pkschema);$pktable = "" if (!$pktable);$fkcatalog = "" if (!$fkcatalog);$fkschema = "" if (!$fkschema);$fktable = "" if (!$fktable);
       DAT::TimTen::db::_foreign_key_info($dbh, $sth, $pkcatalog, $pkschema, $pktable, $fkcatalog, $fkschema, $fktable) or return undef;
       $sth;
    }

    sub server_ping_details {
	my $dbh = shift;
	my $state = undef;

 	my ($catalog, $schema, $table, $type);

	$catalog = "";$schema = "";$table = "NOXXTABLE";$type = "";

	my $sth = DBD::_new_sth($dbh, { 'Statement' => "SQLTables_PING" });

	DAT::TimTen::db::_table_info($dbh, $sth, $catalog, $schema, $table, $type) or return 0;
	$sth->finish;
	return 1;
    }

    sub get_Details_info {
	my ($dbh, $item) = @_;
	return DAT::TimTen::db::_get_info($dbh, $item);
    }

    sub To_do {
        my($dbh, $statement, $attr, @params) = @_;
        my $rows = 0;
        if( -1 == $#params )
        {
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

    sub type_of_all_info {
	my ($dbh) = @_;
	my $sth = DBD::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
	DAT::TimTen::db::_type_info($dbh, $sth, DBD::SQL_ALL_TYPES) or return undef;
	my $info = $sth->fetchall_arrayref;
	unshift @$info, {
	    map { ($sth->{NAME}->[$_] => $_) } 0..$sth->{NUM_OF_FIELDS}-1
	};
	return $info;
    }

}

#----------------------------------------------------
# PACKAGE: DAT::TimTen::st()
# Description: SQL  FETCH EXECUTION  
#CLAUSE
# ---------------------------------------------------

{   package DAT::TimTen::st; 
    use strict;

    sub cancel {
	my $sth = shift;
	my $tmp = DAT::TimTen::st::_cancel($sth);
	$tmp;
    }

    sub To_execute_fetch {
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

DAT::TimTen - TimTen for DBDS

=head1 SYNOPSIS

  use DBD;

  $dbh = DBD->connect('dbi:TimTen:DSN=...', 'user', 'password');

See L<DBD> for more information.

=head1 DESCRIPTION

=head2 Notes:

=over 4

=item B<An Important note about the tests!>

=item B<Private DAT::TimTen Attributes>

=item ttIgnoreNamedPlaceholders

	$dbh->{ttIgnoreNamedPlaceholders} = 1;
	$dbh->do("create trigger foo as if :new.x <> :old.x then ... etc");

=item ttDefaultBindType

=item ttExecDirect

	$dbh->prepare($sql, { ttExecDirect => 1}); 
	$dbh->{ttExecDirect} = 1;

=item ttQueryTimeout

=item ttIsolationLevel

	use DBD;
	use DAT::TimTen qw(:sql_isolation_options);
	$dbh = DBD->connect('DBI:TimTen:DSN=...', undef, undef,{ ttIsolationLevel => SQL_TXN_SERIALIZABLE });
	#SQL_TXN_READ_COMMITTED (default);
	#SQL_TXN_SERIALIZABLE;

=cut 
