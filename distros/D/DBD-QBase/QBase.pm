#   $Id: QBase.pm,v 0.03 10/07/95 $
#
#   Copyright (c) 1995 What Software, INC
#   Programmed: Ben Lindstrom
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
    package DBD::QBase;

    require DBI;

    require DynaLoader;
    @ISA = qw(DynaLoader);

    $VERSION = substr(q$Revision: 0.03 $, 10);

    bootstrap DBD::QBase;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

# Umm...Not needed right?
#
#	unless ($ENV{'QBase_HOME'}){
#	    foreach(qw(/usr/QBase /opt/QBase /usr/soft/QBase)){
#		$ENV{'QBase_HOME'}=$_,last if -d "$_/rdbms/lib";
#	    }
#	    my $msg = ($ENV{QBase_HOME}) ? "set to $ENV{QBase_HOME}" : "not set!";
#	    warn "QBase_HOME $msg\n";
#	}

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'QBase',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::QBase::err,
	    'Errstr' => \$DBD::QBase::errstr,
	    'Attribution' => 'QuickBase DBD by Ben Lindstrom',
	    });

	$drh;
    }

    1;
}


{   package DBD::QBase::dr; # ====== DRIVER ======
    use strict;

    sub errstr {
	DBD::QBase::errstr(@_);
    }

    sub connect {
	my($drh, $dbname, $user, $auth)= @_;

	if ($dbname){	# application is asking for specific database

	    if ($dbname =~ /:/){	# Implies an Sql*NET connection

		# We can use the 'user/passwd@machine' form of user:
		$user .= '@'.$dbname;
		# $TWO_TASK and $QBase_SID will be ignored

	    } else {

		# Is this a NON-Sql*NET connection (QBase_SID)?
		# Or is it an alias for an Sql*NET connection (TWO_TASK)?
		# Sadly the 'user/passwd@machine' form only works
		# for Sql*NET connections.

		# We need a solution to this problem!
		# Perhaps we need to read and parse QBase
		# alias files like /etc/tnsnames.ora (/etc/sqlnet)

		$ENV{QBase_SID} = $dbname;
		delete $ENV{TWO_TASK};
	    }
	}

	# create a 'blank' dbh

	my $this = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'USER' => $user, 'CURRENT_USER' => $user,
	    });

	# Call QBase func in QBase.xs file and populate internal handle data.

	DBD::QBase::db::_login($this, $dbname, $user, $auth)
	    or return undef;

	$this;
    }

}


{   package DBD::QBase::db; # ====== DATABASE ======
    use strict;

    sub errstr {
	DBD::QBase::errstr(@_);
    }

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' dbh

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call QBase OCI oparse func in QBase.xs file.
	# (This will actually also call oopen for you.)
	# and populate internal handle data.

	DBD::QBase::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }

}


{   package DBD::QBase::st; # ====== STATEMENT ======
    use strict;

    sub errstr {
	DBD::QBase::errstr(@_);
    }
}

1;
