package Archive::Builder::File;

# This package represents a single file in the Archive::Builder structure

use strict;
use Scalar::Util     ();
use Params::Util     ('_SCALAR0');
use Archive::Builder ();

use vars qw{$VERSION %_PARENT};
BEGIN {
	$VERSION = '1.16';
	%_PARENT = ();
}





#####################################################################
# Main Interface Methods

sub new {
	my $class = shift;
	$class->_clear;

	# Get and check the path
	my $path = Archive::Builder->_check( 'relative path', $_[0] ) ? shift
		: return $class->_error( 'Invalid path format for File creation' );

	# Get and check the Archive::Builder function
	my $generator = Archive::Builder->_check( 'generator', $_[0] ) ? shift
		: return $class->_error( 'Invalid generator function: '
			. Archive::Builder->errstr );

	# Create the File object
	bless {
		path      => $path,
		generator => $generator,
		arguments => @_ ? [ @_ ] : 0,
	}, $class;
}

# Accessor methods
sub path      { $_[0]->{path} }
sub generator { $_[0]->{generator} }
sub arguments { $_[0]->{arguments} ? [@{ $_[0]->{arguments} }] : 0 }

# Save the file to disk ( optionally below a directory )
sub save {
	my $self = shift;
	my $filename = shift or return undef;

	# Can we write to the location
	unless ( File::Flat->canWrite( $filename ) ) {
		return $self->_error( "Insufficient permissions to write to '$filename'" );
	}

	# Get the file contents ( as a scalar ref )
	my $contents = $self->contents or return undef;

	# Write the file
	File::Flat->write( $filename, $contents )
		or return $self->_error( "Error writing to '$filename': $!" );

	# If it is executable, set the mode
	if ( $self->{executable} ) {
		chmod 0755, $filename;
	}

	1;
}

# Is the file binary. Worked out by examining the content for the null byte,
# which should never be in a text file, but almost always is in binary files.
sub binary {
	my $self = shift;
	my $contents = $self->contents or return undef;
	index($$contents, "\000") != -1;
}

# Flag a File as being executable
sub executable { $_[0]->{executable} = 1 }

# Get our parent Section
sub Section { $_PARENT{ Scalar::Util::refaddr($_[0]) } }

# Delete this from from its parent
sub delete {
	my $self = shift;
	my $Section = $self->Section or return 1;

	# Remove from our parent
	$Section->remove_file( $self->path );

	1;
}	

# If the content has been generated, remove it so it will
# be generated again. ( Possibly with a different result )
sub reset { delete $_[0]->{contents}; 1 }





######################################################################
# File generation

# Get the generated content.
# Implement caching.
sub contents {
	my $self = shift;
	unless ( exists $self->{contents} ) {
		my $contents = $self->_contents;
		unless ( defined $contents ) {
			return $self->_error( 'Error while generating contents: ' . $self->errstr );
		}
		$self->{contents} = $contents;
	}
	$self->{contents};
}

# Actually generate the contents
sub _contents {
	my $self = shift;

	# Load the module for the function if needed
	my $generator = $self->{generator} =~ /::/
		? $self->{generator}
		: "Archive::Builder::Generators::$self->{generator}";
	my ($module) = $generator =~ m/^(.*)::.*$/;
	unless ( Class::Autouse->load( $module ) ) {
		return $self->_error( "Failed to load module '$module'" );
	}

	# Call the function
	no strict 'refs';
	my $result = $self->{arguments}
		? &{ $generator }( $self, @{ $self->{arguments} } )
		: &{ $generator }( $self );
	_SCALAR0($result) or return undef;

	# Clean up newlines in text files
	if ( index($$result, "\000") == -1 ) { # If not a binary file
		$$result =~ s/(?:\015\012|\015|\012)/\n/g;
	}
	
	$result;
}





#####################################################################
# Utility Methods

# Pass through error
sub errstr { Archive::Builder->errstr }
sub _error { shift; Archive::Builder->_error(@_) }
sub _clear { Archive::Builder->_clear }

1;

__END__

=pod

The documentation for this class is part of L<Archive::Builder>.

=cut
