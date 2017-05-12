{
    package DBD::NoConnect;

    require DBI;
    require Carp;

    @EXPORT = qw(); # Do NOT @EXPORT anything.

    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;
	$class .= "::dr";
	($drh) = DBI::_new_drh($class, { 'Name' => 'NoConnect', 'Version' => '1' });
	$drh;
    }

    sub CLONE { undef $drh; }
}


{   package DBD::NoConnect::dr; # ====== DRIVER ======
    $imp_data_size = 0;
    use strict;

    sub connect { # normally overridden, but a handy default
        my ($drh, $dsn, $user, $pass, $attr) = @_;

        return $drh->set_err(42, "no_connect countdown")
            if $attr->{no_connect}{countdown}-- >= 1;

        my $dbh = $drh->SUPER::connect($dsn, $user, $pass, $attr)
            or return;
        $dbh->STORE(Active => 1);
        $dbh;
    }


    sub DESTROY { undef }
}


{   package DBD::NoConnect::db; # ====== DATABASE ======
    $imp_data_size = 0;
    use strict;
    use Carp qw(croak);

    sub prepare {
	my ($dbh, $statement)= @_;

	my ($outer, $sth) = DBI::_new_sth($dbh, {
	    'Statement'     => $statement,
        });

	return $outer;
    }

    sub STORE {
        my ($dbh, $attrib, $value) = @_;
        # would normally validate and only store known attributes
        # else pass up to DBI to handle
        if ($attrib eq 'AutoCommit') {
            Carp::croak("Can't disable AutoCommit") unless $value;
            # convert AutoCommit values to magic ones to let DBI
            # know that the driver has 'handled' the AutoCommit attribute
            $value = ($value) ? -901 : -900;
        }
        return $dbh->SUPER::STORE($attrib, $value);
    }

}


{   package DBD::NoConnect::st; # ====== STATEMENT ======
    $imp_data_size = 0;
    use strict;

}

1;
