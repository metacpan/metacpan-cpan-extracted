package Archive::Builder;

# This packages provides a simplified object for a collection of generated
# files, and ways to then distribute the files.

use 5.005;
use strict;
use Scalar::Util          ();
use List::Util       1.15 ();
use File::Spec       0.80 ();
use File::Spec::Unix      ();
use Params::Util     0.22 ('_INSTANCE', '_STRING');
use Class::Inspector 1.12 ();
use IO::String       1.08 ();
use Class::Autouse   1.27 ('File::Flat');

# Load the rest of the classes;
use Archive::Builder::Section    ();
use Archive::Builder::File       ();
use Archive::Builder::Archive    ();
use Archive::Builder::Generators ();

# Version
use vars qw{$VERSION $errstr};
BEGIN {
	$VERSION = '1.16';
	$errstr  = '';
}





#####################################################################
# Main Interface Methods

# Constructor
sub new { bless { sections => {} }, shift }

# Test generate and cache all files.
sub test { foreach ( $_[0]->section_list ) { $_->test or return undef } 1 }

# Save all files to disk
sub save {
	my $self = shift;
	my $base = shift || '.';

	# Check we can write to the location
	unless ( File::Flat->canWrite( $base ) ) {
		return $self->_error( "Insufficient permissions to write to '$base'" );
	}

	# Process each of the sections
	foreach my $Section ( $self->section_list ) {
		my $subdir = File::Spec->catdir( $base, $Section->path );
		unless ( $Section->save( $subdir ) ) {
			return $self->_error( "Failed to save Archive::Builder to '$base'" );
		}
	}

	1;
}

# Explicitly delete Archive.
# Just pass the call down to the sections.
sub delete { foreach ( $_[0]->section_list ) { $_->delete } 1 }

# If any files have been generated, flush the content cache
# so they will be generated again.
# Just pass the call down to the sections.
sub reset { foreach ( $_[0]->section_list ) { $_->reset } 1 }

# Create a new archive for the Builder
sub archive { Archive::Builder::Archive->new( $_[1], $_[0] ) }

# Create a more shorthand set of data, keying path against content ref
sub _archive_content {
	my $self = shift;

	# Get and merge the _archive_content()s for each section
	my %tree = ();
	foreach my $Section ( $self->section_list ) {
		my $subtree = $Section->_archive_content or return undef;
		my $path = $Section->path;
		foreach ( keys %$subtree ) {
			my $full = File::Spec::Unix->catfile( $path, $_ );
			$tree{$full} = $subtree->{$_};
		}
	}

	\%tree;
}

sub _archive_mode {
	my $self = shift;

	# Collect a list of permission modes to apply
	my %tree = ();
	foreach my $Section ( $self->section_list ) {
		my $subtree = $Section->_archive_mode or return undef;
		my $path    = $Section->path;
		foreach ( keys %$subtree ) {
			my $full = File::Spec::Unix->catfile( $path, $_ );
			$tree{$full} = $subtree->{$_};
		}
	}

	\%tree;
}





#########################################################################
# Working with sections

# Add an existing section
sub add_section {
	my $self    = shift;
	my $Section = _INSTANCE(shift, 'Archive::Builder::Section') or return undef;

	# Does a section with the name already exists?
	my $name = $Section->name;
	if ( exists $self->{sections}->{$name} ) {
		return $self->_error( 'A section with that name already exists' );
	}

	# Add the section
	$Archive::Builder::Section::_PARENT{Scalar::Util::refaddr($Section)} = $self;
	$self->{sections}->{$name} = $Section;
}

# Add a new section and return it
sub new_section {
	my $self = shift;

	# Create the section with the arguments
	my $Section = Archive::Builder::Section->new( @_ ) or return undef;
	$self->add_section($Section);
}

# Add a number of new sections
sub new_sections {
	my $self = shift;
	my %sections = (ref $_[0] eq 'HASH') ? %{$_[0]}
		: map { $_ => $_ } @_;

	# Add each of the sections
	foreach my $name ( sort keys %sections ) {
		my $Section = $self->new_section($name) or return undef;
		if ( $sections{$name} ne $name ) {
			$Section->path($sections{$name}) or return undef;
		}
	}

	1;
}

# Get the hash of sections
sub sections { %{$_[0]->{sections}} ? { %{$_[0]->{sections}} } : 0 }

# Get the sections as a list
sub section_list {
	my $sections = $_[0]->{sections};
	map { $sections->{$_} } sort keys %$sections;
}

# Get a section by name
sub section { defined $_[1] ? $_[0]->{sections}->{$_[1]} : undef }

# Remove a section, by name
sub remove_section {
	my $self = shift;
	my $name = defined $_[0] ? shift : return undef;
	my $Section = $self->{sections}->{$name} or return undef;

	# Delete from our sections
	delete $self->{sections}->{$name};

	# Remove the parent link
	delete $Archive::Builder::Section::_PARENT{Scalar::Util::refaddr($Section)};

	1;
}

# Returns the number of files in the Builder, by totalling
# all it's sections
sub file_count {
	List::Util::sum map { $_->file_count } $_[0]->section_list or 0;
}

# Get a hash of files
sub files {
	my $self  = shift;
	my %files = ();
	foreach my $Section ( values %{$self->{sections}} ) {
		foreach my $File ( $Section->file_list ) {
			my $path = File::Spec::Unix->catfile( $Section->path, $File->path );
			$files{$path} = $File;
		}
	}

	\%files;
}





#####################################################################
# Utility methods

sub _check {
	my $either = shift;
	my $type = shift;
	my $string = shift;

	if ( $type eq 'name' ) {
		return '' unless defined $string;
		return $string =~ /^\w{1,31}$/ ? 1 : '';
	}

	if ( $type eq 'relative path' ) {
		# This makes sure a directory isn't bad
		return $either->_relative_path($string);
	}

	if ( $type eq 'generator' ) {
		return $either->_error( 'No generator defined' ) unless defined $string;

		# Look for illegal characters
		unless ( $string =~ /^\w+(::\w+)*$/ ) {
			return $either->_error( 'Invalid function name format' );
		}

		# Is it a valid alias
		$string = "Archive::Builder::Generators::$string" unless $string =~ /::/;

		# All is good if the function is already loaded
		SCOPE: { no strict 'refs';
			return 1 if defined *{"$string"}{CODE};
		}

		# Does the class exist?
		my ($module) = $string =~ m/^(.*)::.*$/;
		unless ( Class::Inspector->installed( $module ) ) {
			return $either->_error( "Package '$module' does not appear to be present" );
		}

		return 1;
	}

	undef;
}

sub _relative_path {
	my $either = shift;
	my $string = _STRING(shift) or return '';

	# Get the canonical version of the path
	my $canon = File::Spec::Unix->canonpath( $string );

	# Does the path contain escaping forward slashes
	return '' if $string =~ /\\/;

	# We allow one specific exception to the upwards rules.
	# That is in the case where we want to put the content from
	# section into the root of the Builder tree.
	return $string if $string eq '.';

	# Does the path contain upwards stuff?
	return '' unless File::Spec::Unix->no_upwards( $string );
	return '' if $string =~ /\.\./;

	# Is the path absolute
	! File::Spec::Unix->file_name_is_absolute( $string );
}

# Error handling
sub errstr { $errstr }
sub _error { $errstr = $_[1]; undef }
sub _clear { $errstr = '' }

1;

__END__

=pod

=head1 NAME

Archive::Builder - File generation and archiving framework

=head1 SYNOPSIS

  # Make a builder with one section, and some files
  my $Builder = Archive::Builder->new;
  my $Section = $Builder->new_section( 'html' );
  $Section->add_file( 'one.html', 'string', qq~<html><body>
  	Hello World!
  	</body></html>~ );
  $Section->add_file( 'two.html', 'file', './source/file.html' );
  $Section->add_file( 'three.html', 'Custom::function', @args );

  # Generate and save to disk
  $Builder->save( './somewhere' );

  # Create an zip file from it and save it.
  my $Archive = $Builder->archive( 'zip' ).
  $Archive->save( 'foo.zip' );

  # Create a tar.gz file of just one section
  my $Tar = $Section->archive( 'tar.gz' );

=head1 DESCRIPTION

Perl is often used for applications that generate large numbers of files,
and Archive::Builder is designed to assist in these sorts of tasks.

It provides a framework for defining a set of files, and how they will be
generated, and a series of methods for turning them into an Archive of
varying types, or saving directly to disk.

=head2 Structure

Each C<Archive::Builder> object consists of one or more
C<Archive::Builder::Section>s, which contain one or more
C<Archive::Builder::File>s. Each of these files know their location
within the section, and are given a generation function, with a set of
arguments specific to each generator. Some simple generators are
provided built-in, or you can provide an function name as the generator.

=head2 Generating Archives

Once a Archive::Builder is fully defined, you can C<save> it to disk,
or get an C<archive>, containing the generated files, in one of several
formats. You can also C<save> and get the C<archive> any of the individual
sections within the builder.

During the generation process for an entire C<Archive::Builder> a subdirectory
is created for each section matching the name of the section. So, for a
builder with a Section name 'one', containing a single file 'two.txt', and a
section 'three', containing files 'four.html' and 'five.dat', the following
file structure would result

  one/two.txt
  three/four.html
  three/five.dat

=head2 Caching

Caching is dont of the generated files on a per-file basis. Two calls to the
C<content()> method of an C<Archive::Builder::File> object will only result in
the file being generated once, and the same contents returned twice.

=head2 Generation on Demand Caveats

During an output action, such as a C<save()> or C<archive()> method call, the
contents of each file are generated only as needed. This means that if the
generation of a file fails, an action may have already been taken ( especially
in the case of C<save()>, where you may end up with only part of the files
written to disk.

To avoid this, in most cases you should C<test()> the Archive or Section 
first. This will generate all of the files, and cache them. A C<save()> or 
C<archive()> done after this will be done with the cached generated content.

This should be done whenever you have a large of complex generation tree, 
that you consider has a non-zero chance of one of the files failing to
generate correctly.

=head1 METHODS

The methods for the three main classes involved in generation trees,
C<Archive::Builder>, C<Archive::Builder::Section> and
C<Archive::Builder::File> are documented below. For the archive handlers the
builders generate, see L<Archive::Builder::Archive>. For information on the
built-in generators, and how to write your own generators, see
L<Archive::Builder::Generators>.

=head2 Common Error Handlers

Errors from any object of any type below Archive::Builder are set in the
global C<$Archive::Builder::errstr> variable. They can also be retrieved
from the C<errstr()> method called on any object.

=head1 Archive::Builder

=head2 new

The C<new()> constructor takes no arguments, and returns a new
C<Archive::Builder> object.

=head2 add_section $Archive::Builder::Section

The C<add_section> method takes as an argument an C<Archive::Builder::Section>
object, and adds it to the builder.

Returns true if the section is added successfully. Returns C<undef> on error,
for example if another Section with the same name has already been added.

=head2 new_section $name

Creates a new C<Archive::Builder::Section> object with the name provided, and
immediately adds it to the builder. Returns the Section created.

Returns the new Section object on success. Returns undef on error.

=head2 new_sections $name [, $name, ... ]

=head2 new_sections \%names_to_paths

Primarily used for initial set up of Builder objects, the C<new_sections>
method adds a number of sections at the same time.

It accepts as argument either the names of the section to be created, with
the paths of them to be the same as their names, or alternatively, a
reference to a HASH with the keys as section names, and the values as
section paths.

=head2 section $name

Finds and returns a C<Archive::Builder::Section> object with the provided
name within the builder and returns it. Returns undef if passed name does
not exist.

=head2 sections

Returns a hash containing all the sections, indexed by name. Returns C<0> if
no sections have been created in the builder.

=head2 section_list

Returns all the sections in the builder as a list, sorted by section name.
Returns a null list C<()> if no sections are defined in the builder.

=head2 remove_section $name

Removes a section of a given name from the builder, if it exists. Returns
C<undef> if no such section exists.

=head2 file_count

Returns the total number of files in all sections in the builder

=head2 files

Returns a HASH reference containing all of the Achive::Builder::File object
in the Archive::Builder, keyed by full path name.

=head2 save $directory

Generates the file tree for the entire builder and attempts to save it
below a given directory. The passed directory does not have to exist, it
will be created on demand.

Returns true if all files were generated and saved successfully. Returns
C<undef> if an error occurs, or the directory is bad.

=head2 delete

Because of the structure used to support the parent methods, you should
probably explicitly delete Builds when you are done with them to avoid
memory leaks due to circular dependencies.

The C<delete> method always returns true.

=head2 reset

If the contents of any of the files in the Archive::Builder has been
generated ( and thus cached ), the C<reset> method will remove any cached
content from the files, forcing them to be generated again.

The C<reset> method always returns true.

=head2 archive $type

Creates a handle to an archive of a specified type related to the builder.
Types can only be used if the modules that support them are installed.
The following types are supported, and their prerequisites are listed.

  zip    - Archive::Zip
  tar    - Archive::Tar
  tar.gz - Archive::Tar
  tgz    - Archive::Tar

The tar.gz and tgz are aliases that produce the same thing with a different
file extension.

The C<archive> method only returns a C<Archive::Builder::Archive> handle to
the object, not the object itself. Also, the files are not generated at the
time that the archive is created, so generation errors cannot be guarenteed
to have occurred by this time.

To save or otherwise act on the archive, see the Archive::Builder::Archive
section below.

=head1 Archive::Builder::Section

=head2 new name

Creates a new C<Archive::Builder::Section> object of a given name. Although
meant to be used in an C<Archive::Builder> object, they can still be used
effectively standalone, as they have both C<save> and C<archive> methods.

Returns undef is an invalid section name is given. A section name must
contain only word ( \w ) characters and be 1 to 31 characters long.

As a side note, the reason that Sections exist at all is so that Builders
can be defined containing multiple sections, where the sections will be
saved to different locations, but should still be passed around as a
single entity.

=head2 name

Returns the name of the Section.

=head2 path [ path ]

When used within the context of a Builder object, and set to the same value
as the section's name by default, this method returns the path below the
Builder root that will be used, or if passed a relative path, will set the
path to a new value. You are not likely to need this, as in general, the
same value will suffice for both the name and path.

=head2 Builder

If the Section has been added to a Builder, the C<Builder> method will return
it.

Returns a C<Archive::Builder> object if added, or C<undef> if not.

=head2 add_file $Archive::Builder::File

Adds an existing C<Archive::Builder::File> object to the section.

Returns true on success. Returns C<undef> on error, or if the path
of the file clashes with an existing file in the Section.

This could happen if you try to add a file with the same name, of if your
path contains a directory that is already in the Section as a file. For
example, the two files could not exist in the same Section.

  first/second
  first/second/third

Creation of the directory first/second would be blocked by the existing
file first/second ( or vica versa ). This issue is caught for you now,
rather than wait until we are halfway through writing the files to disk
to find out.

=head2 new_file $path, $generator [, @arguments ]

Creates a new file, using the arguments provided, and immediately adds it
to the current section. See the C<new> method for Archive::Builder::File
below for more details on the arguments.

Returns true if the file is created and added successfuly. Returns C<undef>
if an error occurs during either the creation or addition of the file.

=head2 file $path

Finds the C<Archive::Builder::File> object with the given path and returns
it. Returns undef if no such file exists.

=head2 files

Returns a reference to a hash containing all of the files objects, keyed by
their paths. Returns 0 if no files exist within the section.

=head2 file_list

Returns a list of all the file objects, sorted by path. Returns a null array
C<()> if no files exist within the section.

=head2 remove_file $path

Removes the file object with the given path from the section. Returns C<undef>
if no such path exists within the section.

=head2 file_count

Returns the number of files contained in the section

=head2 save $directory

The C<save()> method works the same as the C<Archive::Builder> C<save> method,
generating the files and saving them below the directory provided. Again, the
directory is created on demand.

Returns C<undef> if an error during generation or saving occurs.

=head2 delete

The C<delete> method deletes a Section, removing it from its parent Builder
if applicable, and removing all child Files from the Section.

The C<delete> method always returns true.

=head2 reset

If the contents of any of the files in the Section has been generated 
( and thus cached ), the C<reset> method will remove any cached
content from the files, forcing them to be generated again.

The C<reset> method always returns true.

=head2 archive $type

As for the C<Archive::Builder> C<acrhive> method, creates an archive handle of
the given type. Returns a C<Archive::Builder::Archive> object on success.
Returns C<undef> on error.

=head1 Archive::Builder::File

=head2 new $path, $generator [, @arguments ]

Creates a new C<Archive::Builder::File> object and returns it. This method is
not normally used directly, with the C<Archive::Builder::Section> method
C<new_file()> being more typically used.

The path argument should be a valid looking relative path. That is, it cannot
start with /. For safety, the use of escaping slashes and relative '..' paths
are restricted for safety.

The generator should be a string containing the name of the function to be used
to generate the file contents. A check will be done to ensure that the module
containing the function is installed, although the existance of the function
itself will not be tested. For example, for the generator function
C<Foo::Bar::makeme>, a test to make sure C<Foo::Bar> is installed will be done.

To specify a function in the the main package ( say in a script ), the format
C<main::function> B<MUST> be used. A generator value that does not contain a
package seperator will be assumed to be one of the default generators. The
list of default generators, and instructions on how to write your own
generators, are in the L<Archive::Builder::Generators> documentation.

Anything passed after the generator are assumed to be arguments to the
generator function, and will be stored and passed as needed. Note that the
arguments are not copied or cloned, so any objects passed as arguments and
later modified, will be generated using the modified values. This is
considered a feature. If you need to freeze a copy of the object for the
generation, you are recommended to L<Clone|Clone> it before passing.

=head2 path

Returns the path for the file. This cannot be changed after creation.

=head2 generator

Returns the generator for the file. This cannot be changed after creation

=head2 arguments

Returns a reference to an array containing the arguments to be passed to
the generator, or C<0> if there are no arguments. The list of arguments
cannot be changed after creation ( although of course objects passed can
be changed outside the scope of this API ).

=head2 binary

This method will analyse the file contents ( generating if needed ) to
determine if the file is a binary file. While not 100% accurate, it should
be good enough for most situations.

=head2 executable

Calling this method will add a hint to the file that it should be considered
as an executable file, should the need arise. This is most likely used in
situations where permissions need to be set after generation.

=head2 Section

If added to a Section, the C<Section> method returns the Section to which we
have been added.

Returns a L<Archive::Builder::Section> object if the File is added to one, or
C<undef> if not.

=head2 contents

Generates and returns the contents of the file as a scalar reference. Returns
C<undef> if a generation error occurs.

=head2 save $filename

Bypassing the normal generation process and path name, the C<save> method
allows you to generate a single file object and save it to a specific
filename. Any directories need to write the file will be created on demand.
Returns C<undef> if a generation permissions error occurs.

=head2 delete

If added to a Section, the C<delete> method allows us to remove and delete
the file from the parent Section. Always returns true.

=head2 reset

If the file has been generated ( and thus cached ), the C<reset> method will
remove any cached content from the files, forcing it to be generated again.

The C<reset> method always returns true.

=head1 TODO

Better control over caching, more archive types, pre-generation testing.

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-Builder>

For other issues, contact the maintainer.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Archive::Builder::Archive>, L<Archive::Builder::Generators>,
L<Archive::Tar>, L<Archive::Zip>.

=head1 COPYRIGHT

Copyright 2002 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
