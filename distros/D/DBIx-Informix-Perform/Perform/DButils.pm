
package DBIx::Informix::Perform::DButils;
use strict;
use base 'Exporter';

our @EXPORT_OK = qw(&open_db);

use DBI;

our %DB_MARKERS =
    ( Pg => { dbname => 'dbname=',
	      host => 'host=',
	  },
      mysql => { dbname => 'database=',
		 host => 'host=',
	     },
      );

sub open_db
{
    my $dbname = shift;		# May be a connect arg.

    my $connect_arg = $dbname;
    if ($connect_arg !~ /^dbi:/) { # not already a DBI connect-arg...
	my $dbtype = $ENV{DB_CLASS} || 'Pg';
	$connect_arg = "dbi:$dbtype:";
	my $specifics = $DB_MARKERS{$dbtype};
	$connect_arg .= $$specifics{'dbname'} . $dbname . ";";
	my $host = $ENV{DB_HOST};
	$connect_arg .= $$specifics{'host'} . $host . ";"
	    if ($host);
    }
    my $dbuser = $ENV{DB_USER};
    my $dbpass = $ENV{DB_PASSWORD};
    my $dbh = DBI->connect($connect_arg, $dbuser, $dbpass)
	or die "Unable to connect to '$connect_arg' as user '$dbuser'";
    return $dbh;
}

1;
