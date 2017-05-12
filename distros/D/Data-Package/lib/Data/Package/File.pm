package Data::Package::File;

=pod

=head1 NAME

Data::Package::File - Data::Package base class for data stored in a local file

=head1 DESCRIPTION

The B<Data::Package::File> base class provides a series of additional
methods that ease the development of L<Data::Package> classes that source
their data from files on the local filesystem.

=head1 METHODS

B<Data::Package::File> extends the interface of L<Data::Package> with a few
additional methods.

=cut

use 5.005;
use strict;
use Data::Package    ();
use File::Spec       ();
use IO::File         ();
use Params::Util     qw{ _STRING };
use Class::Inspector ();
use File::ShareDir   ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.05';
	@ISA     = 'Data::Package';
}





#####################################################################
# Data::File::Package Methods

# Apply checks to the class
sub import {
	my $class = shift;

	# The method should give us a file name as a string
	my $file  = $class->file;
	unless ( defined _STRING($file) ) {
		die "The ->file method for data package $class did not return a string";
	}

	# Check that the file is absolute, exists and is readable
	unless ( File::Spec->file_name_is_absolute($file) ) {
		die "The data file path for $class is not an absolute path ($file)";
	}
	unless ( -f $file ) {
		die "The data file for $class does not exist ($file)";
	}
	unless ( -r $file ) {
		die "The data file for $class does not have read permissions ($file)";
	}

	return 1;
}

=pod

=head1 file

  my $to_load = My::Data:Class->file;

The C<file> method can be defined by a L<Data::Package::File> subclass,
and should return an absolute path for a file reable by the current user,
in the form of a simple scalar string.

At load-time, this value will be checked for correctness, and if the value
returned is invalid, loading of the file will fail.

=cut

sub file {
	my $class = ref($_[0]) || $_[0];

	# Support the dist_file method
	my @dist_file = $class->dist_file;
	if ( @dist_file ) {
		return File::Spec->rel2abs(
			File::ShareDir::dist_file( @dist_file )
		)
	}

	# Support the module_file method
	my @module_file = $class->module_file;
	if ( @module_file ) {
		if ( @module_file == 1 ) {
			unshift @module_file, $class;
		}
		return File::Spec->rel2abs(
			File::ShareDir::module_file( @module_file )
		)
	}

	return undef;
}

=pod

=head2 dist_file

  package My::Dist::DataSubclass;
  
  sub dist_file {
      return ( 'My-Dist', 'data.txt' );
  }

The C<dist_file> method is one of two that provide integration with
L<File::ShareDir>. Instead of defining a C<file> method, you can
instead define C<dist_file>.

If C<dist_file> exists, and any values are returned, those values
will be passed through to the C<File::ShareDir::dist_file> function,
with the resulting value converted to an absolute path (if needed)
and used to provide the appropriate object to the caller.

Should return a list with two values, the name of the distribution
the package is in, and the file path within the package's F<share>
directory.

=cut

sub dist_file {
	return ();
}


=pod

=head2 module_file

  package My::DataClass;
  
  # Get a file from this module
  sub module_file {
      return 'data.txt';
  }
  
  # Get a file for another (loaded) module
  sub module_file {
      return ( 'My::RelatedClass', 'data.txt' );
  }

The C<dist_file> method is one of two that provide integration with
L<File::ShareDir>. Instead of defining a C<file> method, you can
instead define C<module_file>.

If C<module_file> exists, and any values are returned, those values
will be passed through to the C<File::ShareDir::module_file> function,
with the resulting value converted to an absolute path (if needed)
and used to provide the appropriate object to the caller.

Should return a list with two values, the module to get the shared files
for, and the the file path within the module's F<share> directory.

If C<module_file> returns a single value, the name of the class will
be automatically prepended as the module name.

=cut

sub module_file {
	return ();
}





#####################################################################
# Add support for IO::File, Path::Class and URI

sub __as_IO_File {
	IO::File->new( $_[0]->file );
}

sub __as_Path_Class_File {
	require Path::Class;
	Path::Class::file( $_[0]->file );
}

sub __as_URI_file {
	require URI::file;
	URI::file->new( $_[0]->file );
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Package>

For other issues, contact the maintainer

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
