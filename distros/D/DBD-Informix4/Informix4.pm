#---------------------------------------------------------
#
#  Portions Copyright (c) 1994,1995,1996,1997 Tim Bunce
#  Portions Copyright (c) 1997                Edmund Mergl
#  Portions Copyright (c) 1997                Göran Thyni
#
#---------------------------------------------------------

require 5.003;

{
    package DBD::Informix4;

    use DBI ();
    use DynaLoader ();
    @ISA = qw(DynaLoader);

    $VERSION = '0.23';

    require_version DBI 0.85;

    bootstrap DBD::Informix4 $VERSION;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errst
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'Informix4',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::Informix4::err,
	    'Errstr' => \$DBD::Informix4::errstr,
	    'Attribution' => 'PostgreSQL DBD by Edmund Mergl',
	});

	$drh;
    }

    1;
}


{   package DBD::Informix4::dr; # ====== DRIVER ======
    use strict;

    sub errstr {
	return $DBD::Informix4::errstr;
    }

    sub connect {
	my($drh, $dbname, $user, $auth)= @_;

	# create a 'blank' dbh

	my $this = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'User' => $user,
	});

        # Connect to the database..
	DBD::Informix4::db::_login($this, $dbname, $user, $auth)
	    or return undef;

	$this;
    }

}


{   package DBD::Informix4::db; # ====== DATABASE ======
    use strict;

    sub errstr {
	return $DBD::Informix4::errstr;
    }

    sub do {
        my($dbh, $statement, @attribs) = @_;#
	    push(@attribs, "") unless scalar @attribs;
        DBD::Informix4::db::_do($dbh, $statement, @attribs);
    }

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' sth

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	});

	DBD::Informix4::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }

    sub tables {
	my($dbh) = @_;
	my $sth = $dbh->prepare("
            select usename, relname, relkind, relhasrules 
	    from pg_class, pg_user 
	    where ( relkind = 'r' or relkind = 'i' or relkind = 'S' ) 
	    and relname !~ '^pg_' 
	    and relname !~ '^xin[vx][0-9]+' 
	    and usesysid = relowner 
	    ORDER BY relname 
        ");
	$sth->execute or return undef;
	$sth;
    }

}


{   package DBD::Informix4::st; # ====== STATEMENT ======
    use strict;

    sub errstr {
	return $DBD::Informix4::errstr;
    }

}

1;

__END__


