#   $Id: Empress.pm, Empress 0.52
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

# =========================================================================
# DBENGINE DB Initialization package
# DBD::Empress
# =========================================================================

BEGIN {
}

{
    package DBD::Empress;

    use DBI ();
    use DynaLoader ();

    @ISA = qw(DynaLoader);

    $VERSION ='0.52';

    bootstrap DBD::Empress $VERSION;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $state = "00000";	# holds DB state string for DBI::state
    $debug = 0;		# holds debug level code for DBI::debug
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	# if MSPATH is not set, then try to set it.

# NOT required for ODBC. But needed for DSQL: will need to fix SGW
#	unless ($ENV{'MSPATH'}){

	    # set DBPATH if not already set

#	    $ENV{'PATH'}='/bin:/usr/bin' unless ($ENV{'PATH'}) ;

#	    $DBPATH=$ENV{'PATH'} . ':' . '/usr/empress' ;

	    # get elements of DBPATH and search them

#	    @PathList=split( /:/ , $DBPATH );
#	    foreach( @PathList ){
#		$ENV{'MSPATH'}=$1, last if /^(.*)\/bin$/ && -d "$_/../custom" && -f "$_/../custom/initfile" && -f "$_/../custom/tabzero" ;
#	    }

	    # print a message about what MSPATH was found

#	    die "MSPATH not set!" unless $ENV{'MSPATH'};
#	    warn "MSPATH set to $ENV{'MSPATH'}" 
#	}

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'Empress',
	    'Version' => 0.52,
	    'Err'    => \$DBD::Empress::err,
	    'Errstr' => \$DBD::Empress::errstr,
	    'State ' => \$DBD::Empress::state,
	    # 'Debug' => \$DBD::Empress::debug,
	    'Attribution' => 'Empress DBD by Empress Software Inc. Fri Apr 11 14:56:47 EDT 1997.',
	    });

	$drh;
    }

    # package returns 'true'

    1;
}

# =========================================================================
# driver package
# DBD::Empress::dr
# =========================================================================

{   package DBD::Empress::dr;	# ====== DRIVER ======
    use strict;

#    sub errstr {
#	DBD::Empress::errstr(@_);
#    }

    sub connect {
	my($drh, $dbname, $user, $pass)= @_;

	# create a 'blank' dbh

	my $dbh = DBI::_new_dbh($drh, {
				    'Name' => $dbname,
				    'User' => $user, 
				    'Pass' => $pass
	    			});

	# Call function in Empress.xs file
	# and populate internal handle data.
	# Note: $dbname=[$host:]$db

	DBD::Empress::db::_login($dbh, $dbname, $user, $pass)
	    or return undef;

	$dbh;
    }
}

# =========================================================================
# database package
# DBD::Empress::db
# =========================================================================

{   package DBD::Empress::db; # ====== DATABASE ======
    use strict;

#    sub errstr {
#	DBD::Empress::errstr(@_);
#    }

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' dbh

	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call function in Empress.xs file.
	# and populate internal handle data.

	DBD::Empress::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }

# ------------------------------------------------------------------
# the 'tables' subroutine should probably be handled in the .xs code
#
#     sub tables {
# 	my($dbh) = @_;
# 	my $sth = $dbh->prepare("select
# 		tab_name,
# 		tab_type,
# 		tab_comment
# 	    from sys_tables
# 	");
# 	$sth->execute or return undef;
# 	$sth;
#     }
# ------------------------------------------------------------------

}

# =========================================================================
# statement package
# DBD::Empress::st
# =========================================================================

{   package DBD::Empress::st; # ====== STATEMENT ======
    use strict;

#    sub errstr {
#	DBD::Empress::errstr(@_);
#    }
}

1;
