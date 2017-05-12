package Data::Package::SQLite;

=pod

=head1 NAME

Data::Package::SQLite - A data package for a SQLite database

=head1 SYNOPSIS

  ### Creating a SQLite data package
  
  package My::Data;
  
  use strict;
  use base 'Data::Package::SQLite';
  
  sub sqlite_locate { file => '/var/cache/mydata.sqlite' }
  
  1;
  
  ### Using your SQLite data package
  
  use My::Data;
  
  # Default data access
  $dbh = My::Data->get;
  
  # ... or if you want to be explicit
  $dbh = My::Data->get('DBI::db');

=head1 DESCRIPTION

One of the best ways to distribute medium-sized (100k - 100meg) packages
containing datasets is using L<SQLite> databases.

It allows you to have full SQL access to your data, and you can still
provide the data as a single file that does not need user/password access
and provides it's own security model (tied to filesystem access).

C<Data::Package::SQLite> is a L<Data::Package> sub-class for providing
simplified read-only access to these databases in the form of a L<DBI>
connection handle, without the caller needing to know anything about
where the data is actually stored.

=head1 METHODS

Although the primary interface when using a C<Data::Package::SQLite>
module should be the same as for any other L<Data::Package> module,
some additional methods are defined for people creating their own
sub-classes of C<Data::Package::SQLite>.

=cut

use 5.005;
use strict;
use base 'Data::Package';
use Carp           ();
use File::ShareDir ();
use Params::Util   qw{_STRING _CLASS};
use DBI;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.01';
}

# Check the SQLite driver is available
unless ( grep { $_ eq 'SQLite' } DBI->available_drivers ) {
	Carp::croak("SQLite DBI driver is not installed");
}

# This class only provides a database handle
sub _provides { 'DBI::db' }

# Load the database handle
sub __as_DBI_db {
	my $self = shift;

	# Create the database handle
	my $dbh = DBI->connect( $self->sqlite_dsn, "", "" );
	unless ( $dbh ) {
		Carp::croak("SQLite connection failed: $DBI::errstr");
	}

	return $dbh;	
}

=pod

=head2 sqlite_dsn

The C<sqlite_dsn> method return a valid L<DBI> dsn for the creation
of the database handle. For any C<Data::Package::SQLite> package that
you C<get> a database handle from, the C<sqlite_dsn> method will
always return the location of the database that was loaded.

When creating a sub-class, you should not return this directly, but
are encouraged to instead define your own C<sqlite_file> or even better
your own C<sqlite_location>.

Returns a DSN string, or throws an exception on error.

=cut

sub sqlite_dsn {
	my $self   = shift;
	my $dbfile = $self->sqlite_file;
	unless ( _STRING($dbfile) ) {
		Carp::croak("SQLite file name not provided, or not a string");
	}
	unless ( -f $dbfile ) {
		Carp::croak("SQLite file '$dbfile' does not exist");
	}
	unless ( -r $dbfile ) {
		Carp::croak("SQLite file '$dbfile' cannot be read");
	}
	return "dbi:SQLite:dbname=$dbfile";	
}

=pod

=head2 sqlite_file

  sub sqlite_file { '/var/cache/my_class/data.sqlite' }

The C<sqlite_file> method returns the location of the SQLite file to
be loaded.

Please note that the fact a file name is returned by this method does
not necesarily mean it exists, because in some cases incorrect file
names can be generated, or a sub-class might defined this method
(incorrectly) directly.

Returns a file path string, or throws an exception in some error
situations.

=cut

sub sqlite_file {
	my $self     = shift;
	my @location = $self->sqlite_location;
	my $type     = _STRING(shift @location)
		or Carp::croak('No or bad SQLite location type provided');

	if ( $type eq 'file' ) {
		return shift @location;

	} elsif ( $type eq 'dist_file' ) {
		my $dist = _STRING(shift @location)
			or Carp::croak('No dist_file distribution provided');
		my $file = _STRING(shift @location) || 'data.sqlite';
		return File::ShareDir::dist_file( $dist, $file );

	} elsif ( $type eq 'module_file' ) {
		my $module = _CLASS(shift @location)
			or Carp::croak('Invalid or no module name provided');
		my $file = _STRING(shift @location) || 'data.sqlite';
		return File::ShareDir::module_file( $module, $file );

	} else {
		Carp::croak("Unknown or unsupported location type '$type'");
	}
}

=pod

=head2 sqlite_location

  # A general file location somewhere
  sub sqlite_location { file => '/var/cache/my_class/data.sqlite' }
  
  # The default data.sqlite for a distribution
  sub sqlite_location { dist_file => 'My-Dist' }
  
  # A specific file for a distribution
  sub sqlite_location { dist_file => 'My-Dist', 'sqlite.db' }
  
  # The default data.sqlite for a module
  sub sqlite_location { module_file => 'My::Module' }
  
  # A specific file for a module
  sub sqlite_location { module_file => 'My::Module', 'sqlite.db' }

The C<sqlite_location> method is the primary method for sub-classes to
specify the location of the SQLite database file.

It should return a simple 2-3 element list, consisting of a location
type and 1 or more location values.

The C<sqlite_location> method currently accepts 3 location types.

=over 4

=item file

Mostly provides a direct pass-through to C<sqlite_file>.

Takes a second param of the location of the file as a simple string.

=item dist_file

The C<dist_file> option provides access to the functionality provided
by the L<File::ShareDir> function C<dist_file>.

It takes two additional values, the name of the distribution and the
name of the file within the dist dir.

If the file name is not provided, a default value of F<data.sqlite>
is used.

=item module_file

The C<module_file> option provides access to the functionality provided
by the L<File::ShareDir> function C<module_file>.

It takes two additional values, the name of the module and the
name of the file within the dist dir.

If the file name is not provided, a default value of F<data.sqlite>
is used.

=back

If not provided, the default implementation of C<sqlite_location> will
return C<( module_file =E<gt> $class )>, where C<$class> is the name
of the L<Data::Package::SQLite> sub-class.

=cut

sub sqlite_location {
	my $class = ref($_[0]) || "$_[0]";

	# We don't know for sure that the class actually has
	# a data.sqlite file, but it is the best guess.
	return ( 'module_file' => $class );
}

1;

=pod

=head1 SUPPORT

Bugs should be B<always> be reported via the CPAN bug tracker at:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Package-SQLite>

For other issues, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Package>, L<DBD::SQLite>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
