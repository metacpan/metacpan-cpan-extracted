package DBIx::Export;

=pod

=head1 NAME

DBIx::Export - Export data from DBI as a SQLite database

=head1 SYNOPSIS

  my $export = DBIx::Export->new(
      file   => 'publish.sqlite',
      source => DBI->connect($dsn, $user, $pass),
  );
  
  $export->table( 'table1',
      'select * from foo where this < 10',
  );
  
  $export->finish;

=head1 DESCRIPTION

B<THIS MODULE IS EXPERIMENTAL>

This is an experimental module that automates the exporting of data from
arbitrary DBI handles to a SQLite file suitable for publishing online
for others to download.

It takes a set of queries, analyses the data returned by the query,
then creates a table in the output SQLite database.

In the process, it also ensures all the optimal pragmas are set,
an index is places on every column in every table, and the database
is fully vacuumed.

As a result, you should be able to connect to any arbitrary datasource
using any arbitrary DBI driver and then map an arbitrary series of 
SQL queries like views into the published SQLite database.

=cut

use 5.006;
use strict;
use warnings;
use bytes             ();
use Carp              'croak';
use Params::Util 0.33 ();
use DBI          1.57 ();
use DBD::SQLite  1.21 ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

use Object::Tiny 1.06 qw{
	file
	source
	dbh
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Connect to the SQLite database
	my $dsn = "DBI:SQLite:" . $self->file;
	$self->{dbh} = DBI->connect( $dsn, '', '', {
		PrintError => 1,
		RaiseError => 1,
	} );

	# Maximise compatibility
	$self->sqlite('PRAGMA legacy_file_format = 1');

	# Turn on all the go-faster pragmas
	$self->sqlite('PRAGMA synchronous = 0');
	$self->sqlite('PRAGMA temp_store = 2');
	$self->sqlite('PRAGMA journal_mode = OFF');
	$self->sqlite('PRAGMA locking_mode = EXCLUSIVE');

	# Disable auto-vacuuming because we'll only fill this once.
	# Do a one-time vacuum so we start with a clean empty database.
	$self->sqlite('PRAGMA auto_vacuum = 0');
	$self->sqlite('VACUUM');

	return $self;
}

# Execute a query on the sqlite database
sub sqlite {
	shift->{dbh}->do(@_);
}

# Clean up the SQLite database
sub finish {
	my $self = shift;

	# Tidy up the database
	$self->sqlite('PRAGMA synchronous = NORMAL');
	$self->sqlite('PRAGMA temp_store = 0');
	$self->sqlite('PRAGMA locking_mode = NORMAL');
	$self->sqlite('VACUUM');

	# Disconnect
	$self->{dbh}->disconnect;

	return 1;
}





#####################################################################
# Methods to populate the database

sub table {
	my $self   = shift;
	my $table  = shift;
	my $sql    = shift;
	my @params = @_;

	# Make an initial scan pass over the query and do a content-based
	# classification of the data in each column.
	my $rows  = 0;
	my %type  = ();
	my @names = ();
	SCOPE: {
		my $sth = $self->source->prepare($sql) or croak($DBI::errstr);
		$sth->execute( @params );
		@names = @{$sth->{NAME}};
		while ( my $row = $sth->fetchrow_hashref ) {
			$rows++;
			foreach my $key ( sort keys %$row ) {
				my $value = $row->{$key};
				my $hash  = $type{$key} ||= {
					NULL      => 0,
					POSINT    => 0,
					NONNEGINT => 0,
					NUMBER    => 0,
					STRING    => {},
				};
				unless ( defined $value ) {
					$hash->{NULL}++;
					next;
				}
				$hash->{STRING}->{bytes::length($value)}++;
				next unless Params::Util::_POSINT($value);
				$hash->{POSINT}++;
				next unless Params::Util::_NONNEGINT($value);
				$hash->{NONNEGINT}++;
				next unless Params::Util::_NUMBER($value);
				$hash->{NUMBER}++;
			}
		}
		$sth->finish;
		foreach my $key ( sort keys %type ) {
			my $hash    = $type{$key};
			my $notnull = $hash->{NULL} ? 'NULL' : 'NOT NULL';
			if ( $hash->{NULL} == $rows or $hash->{NONNEGINT} == $rows ) {
				$type{$key} = "INTEGER $notnull";
				next;
			}
			if ( $hash->{NUMBER} == $rows ) {
				$type{$key} = "REAL $notnull";
				next;
			}

			# Look for various string types
			my $string  = $hash->{STRING};
			my @lengths = sort { $a <=> $b } keys %$string;
			if ( scalar(@lengths) == 1) {
				# Fixed width non-numeric field
				$type{$key} = "CHAR($lengths[0]) $notnull";
				next;
			}
			if ( $lengths[-1] <= 10 ) {
				# Short string
				$type{$key} = "VARCHAR(10) $notnull";
				next;
			}
			if ( $lengths[-1] <= 32 ) {
				# Medium string
				$type{$key} = "VARCHAR(32) $notnull";
				next;
			}
			if ( $lengths[-1] <= 255 ) {
				# Short string
				$type{$key} = "VARCHAR(255) $notnull";
				next;
			}

			# For now lets assume this is a blob
			$type{$key} = "BLOB $notnull";
		}
	}

	# Prepare the CREATE and INSERT queries
	my $columns = join ",\n", map { "\t$_ $type{$_}" } @names;
	my $place   = join ", ",  map { '?' } @names;
	my $create  = "CREATE TABLE $table (\n$columns\n)";
	my $insert  = "INSERT INTO $table values ( $place )";

	# Create the table
	$self->sqlite($create);

	# Do a second pass and fill the destination table
	SCOPE: {
		my $sth = $self->source->prepare($sql) or croak($DBI::errstr);
		$sth->execute( @params );
		while ( my $row = $sth->fetchrow_hashref ) {
			$self->sqlite($insert, {}, @$row{@names});
		}
		$sth->finish;
	}

	# Add an index on all of the columns
	foreach my $col ( @names ) {
		$self->sqlite("CREATE INDEX idx__${table}__${col} ON ${table} ( ${col} )");
	}

	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Export>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<DBI>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
