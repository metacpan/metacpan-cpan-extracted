#
# testenv.pm
#
# environment for DBD::Solid tests
#

{
package testenv;
use strict;
require Exporter;

use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(soluser);

sub soluser
    {
    my ($user, $pass, $dsn, $dbh);

    unless (defined($ENV{'DBI_DSN'}))
    	{
	my $x = $ENV{'SOLID_DSN'} || '';
        $dsn = 'dbi:Solid:' . $x;
	}

    unless (($user, $pass) = ($ENV{'DBI_USER'},  $ENV{'DBI_PASS'}))
    	{
	$user = $ENV{'SOLID_USER'} or $user = '';

	# test user-supplied data.
	($user, $pass) = split(/\W/, $user);
	$user = uc($user);
	unless ($user && $pass)
	    {
	    print STDERR 
		"DBI_USER/DBI_PASS undefined and SOLID_USER not found\n";
	    exit(0);
	    }
	}

    ($dsn, $user, $pass);
    }
1;
}
