
package DBIx::Romani::Driver::sqlite;
use base qw(DBIx::Romani::Driver);

use DBIx::Romani::Driver::sqlite::IdGenerator;
use strict;

# TODO: this function will take a "Roma-style" DSN or hash, and make
# a DBI connection returning a dbh.
sub connect_dbi
{
	die "Unimplemented.";
}

sub apply_limit
{
	my ($self, $sql, $offset, $limit) = @_;

	if ( $limit > 0 )
	{
		$sql .= " LIMIT " . $limit;
		if ( $offset > 0 )
		{
			$sql .= " OFFSET " . $offset;
		}
	}
	elsif ( $offset > 0 )
	{
		$sql .= " LIMIT -1 OFFSET " . $offset;
	}

	return $sql;
}

sub create_id_generator
{
	my ($self, $conn) = @_;
	return DBIx::Romani::Driver::sqlite::IdGenerator->new( $conn );
}

1;

