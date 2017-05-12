package Archive::Builder::Archive;

# Represents the actual or potential Archive.

use strict;
use Scalar::Util     ();
use Params::Util     ('_STRING');
use Archive::Builder ();
use Class::Inspector ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}





# This module makes use of several Archive related modules as needed.
# To start, catalogue the ones we can use.
use vars qw{$dependencies $support};
BEGIN {
	$dependencies = {
		'zip'    => [ 'Archive::Zip', 'Compress::Zlib' ],
		'tar'    => [ 'Archive::Tar'                   ],
		'tgz'    => [ 'Archive::Tar', 'Compress::Zlib' ],
		'tar.gz' => [ 'Archive::Tar', 'Compress::Zlib' ],
		};

	# Which types are we able to create
	foreach my $type ( keys %$dependencies ) {
		$support->{$type} = ! grep { ! Class::Inspector->installed( $_ ) } 
			@{$dependencies->{$type}};
	}
}




# Which types are supported
sub types {
	grep { $support->{$_} } sort keys %$support;
}





# Create the new Archive handle
sub new {
	my $class  = shift;
	my $type   = (_STRING($_[0]) and exists $support->{$_[0]}) ? shift : return undef;
	my $Source = _CAN(shift, '_archive_content') or return undef;

	# Can we use the type?
	unless ( $support->{$type} ) {
		my $modules = join ', ', @{ $dependencies->{$type} };
		return $class->_error( "$type support requires that the modules $modules are installed" );
	}

	# Make sure there is at least one file
	unless ( $Source->file_count > 0 ) {
		return $class->_error( "Your Source does not contain any files" );
	}

	# Get the generated files
	my $files = $Source->_archive_content;
	return $class->_error(
		"Error generating content to create archive: "
		. $Source->errstr || 'Unknown Error'
	) unless $files;

	# Find any special modes we need to set
	my $modes = $Source->_archive_mode;
	return $class->_error(
		"Error generated permissions to create archive: "
		. $Source->errstr || 'Unknown Error'
	) unless $modes;

	# Create the object
	my $self = bless {
		type  => $type,
		files => $files,
		modes => $modes,
	}, $class;

	$self;
}

# Get the type
sub type {
	$_[0]->{type};
}

# Get the file hash
sub files {
	$_[0]->{files};
}

# Get the mode hash
sub modes {
	$_[0]->{modes};
}

# Get them in the special sorted order
sub sorted_files {
	my $self  = shift;
	my @files = sort keys %{$self->files};
	return () unless @files;
	my $first = undef;
        my $parts = undef;
	foreach ( 0 .. $#files ) {
		my @f    = split /\//, $files[$_];
		my $this = scalar @f;
                if ( defined $parts and $this >= $parts ) {
                        next;
                }
		$first = $_;
                $parts = $this;
	}
	unshift @files, splice( @files, $first, 1 );
        return @files;
}

# Get the generated file as a scalar ref
sub generate {
	my $self = shift;
	$self->{generated} || ($self->{generated} = $self->_generate);
}

sub _generate {
	my $self = shift;

	# Load the required modules
	my @modules = @{ $dependencies->{ $self->{type} } };
	foreach ( @modules ) {
		Class::Autouse->load( $_ );
	}

	if ( $self->{type} eq 'zip' ) {
		return $self->_zip;
	} elsif ( $self->{type} eq 'tar' ) {
		return $self->_tar;
	} elsif ( $self->{type} eq 'tar.gz' ) {
		return $self->_tar_gz;
	} elsif ( $self->{type} eq 'tgz' ) {
		return $self->_tgz;
	} else {
		return undef;
	}
}

# Saves the archive to disk
sub save {
	my $self     = shift;
	my $filename = shift;

	# Add the extension to the filename if needed
	my $type = quotemeta $self->{type};
	unless ( $filename =~ /\.$type$/ ) {
		$filename .= '.' . $self->{type};
	}

	# Can we write to the location
	unless ( File::Flat->canWrite( $filename ) ) {
		return $self->_error( "Insufficient permissions to write to '$filename'" );
	}

	# Get the generated archive
	my $contents = $self->generate;
	unless ( $contents ) {
		return $self->_error( "Error generating $self->{type} archive" );
	}

	# Write the file
	unless ( File::Flat->write( $filename, $contents ) ) {
		return $self->_error( "Error writing $self->{type} archive '$filename' to disk" );
	}

	1;
}





#####################################################################
# Generators

# We should never get to these methods if the correct modules arn't
# installed. They should also be loaded.

sub _zip {
	my $self = shift;

	# Create the new, empty archive
	my $Archive = Archive::Zip->new;

	# Add each file to it
	my $files = $self->{files};
	my $modes = $self->{modes};
	foreach my $path ( keys %$files ) {
		my $content = $files->{$path};
		my $member  = $Archive->addString( $$content, $path );
		$member->desiredCompressionMethod(
			Archive::Zip::COMPRESSION_DEFLATED()
		);
		if ( $modes->{$path} ) {
			$member->unixFileAttributes( $modes->{$path} );
		}
	}

	# Now stringify the Archive and return it
	my $handle = IO::String->new;
	unless ( $Archive->writeToFileHandle( $handle ) == Archive::Zip::AZ_OK() ) {
		return undef;
	}
	return $handle->string_ref;
}

sub _tar {
	my $self = shift;

	# Create the empty tar object
	my $Archive = Archive::Tar->new;
	unless ( $Archive ) {
		return $self->_error( 'Error creating tar object' );
	}

	# Add each file to it
	my $files = $self->{files};
	my $modes = $self->{modes};
	foreach my $path ( $self->sorted_files ) {
		my $content = $files->{$path};
		my $member  = $Archive->add_data( $path, $$content );
		if ( $modes->{$path} ) {
			$member->mode( $modes->{$path} );
		}
	}

	# Get the output
	my $string = $Archive->write;

	# Free up some memory
	$Archive->clear;

	return $string ? \$string : undef;
}

sub _tar_gz {
	my $self = shift;

	# Get the normal tar
	my $tar = $self->_tar or return undef;

	# Compress it
	my $compressed = Compress::Zlib::memGzip( $$tar );
	$compressed ? \$compressed : undef;
}

# Exactly the same as _tar_gz
sub _tgz { shift->_tar_gz }





#####################################################################
# Utility methods

# Pass through error
sub errstr { Archive::Builder->errstr }
sub _error { shift; Archive::Builder->_error(@_) }
sub _clear { Archive::Builder->_clear }

# Params::Util style checking function
sub _CAN {
	(defined $_[0] and Scalar::Util::blessed($_[0]) and $_[0]->can($_[1])) ? $_[0] : undef;
}

1;

__END__

=head1 NAME 

Archive::Builder::Archive - Archive abstraction handles

=head1 DESCRIPTION

C<Archive::Builder::Archive> objects provide a type neutral handle for
outputing the various archive file types L<Archive::Builder> objects.

For more information on Archive::Builder objects, see its POD documentation.

=head1 METHODS

=head2 types

When loaded, Archive::Builder::Archive examines your system to determine which
archive types it is capable of creating, based on dependencies.

The C<types> method returns a list of types that are supported by your 
system.

=head2 new( type, Archive::Builder|Archive::Builder::Section )

Although obtained via the Archive::Builder and Archive::Builder::Section 
C<archive> methods, archives can be created directly, by passing them a valid
type and either an C<Archive::Builder> or C<Archive::Builder::Section> object.

=head2 type

Returns the type of an C<Archive::Builder::Archive> object.

=head2 generate

Generates and returns the actual archive object, with will be an 
L<Archive::Zip>, L<Archive::Tar>, or whatever, depending on the type.

Returns C<undef> if an error occurs during file generation, or archive 
generation.

=head2 save( filename )

Generates and saves the archive file to a specific filename. If the file name
does NOT end in the file type you have specified, it will be appended for you.

That is, C<save('file')> will result in the creation of file.zip for an 
archive of type 'zip'.

=head1 TODO

More Archive types, like rar.

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Archive-Builder>

For other issues, contact the maintainer.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>
        
=head1 SEE ALSO

L<Archive::Builder>, L<Archive::Builder::Generators>,
L<Archive::Tar>, L<Archive::Zip>.

=head1 COPYRIGHT

Copyright 2002 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
