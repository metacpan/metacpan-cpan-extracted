#   $Id: Informix.pm,v 1.18 1995/08/15 05:31:30 timbo Rel $
#
#   Copyright (c) 1994,1995 Tim Bunce
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
	package DBD::NET;

	require DBI;

	require DynaLoader;
	@ISA = qw(DynaLoader);

	$VERSION = "0.24";

	bootstrap DBD::NET;

	$err = 0;		# holds error code   for DBI::err
	$errstr = "";	# holds error string for DBI::errstr
	$drh = undef;	# holds driver handle once initialised

	sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'NET',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::NET::err,
	    'Errstr' => \$DBD::NET::errstr,
	    'Attribution' => 'NET DBD by Alligator Descartes',
	    });

	$drh;
	}

	1;
}


{   package DBD::NET::dr; # ====== DRIVER ======
	use strict;

	sub errstr {
	DBD::NET::errstr(@_);
	}

	sub connect {
	my($drh, $host, $dbname, $user, $pass)= @_;

	# create a 'blank' dbh

	my $this = DBI::_new_dbh($drh, {
	    'Host' => $host,
	    'Name' => $dbname,
	    'User' => $user,
	    'Pass' => $pass
	    });

	# Call NET login func in the NET.xs file
	# and populate internal handle data.

	DBD::NET::db::_login($this, $host, $dbname, $user, $pass)
	    or return undef;

	$this;
	}

}


{   package DBD::NET::db; # ====== DATABASE ======
	use strict;

	sub errstr {
	DBD::NET::errstr(@_);
	}

	sub prepare {
	my($dbh, $statement)= @_;

	# create a 'blank' dbh

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call NET OCI oparse func in NET.xs file.
	# (This will actually also call oopen for you.)
	# and populate internal handle data.

	DBD::NET::st::_prepare($sth, $statement)
	    or return undef;

	$sth;
	}

}


{   package DBD::NET::st; # ====== STATEMENT ======
	use strict;

	sub errstr {
	DBD::NET::errstr(@_);
	}
}

1;
