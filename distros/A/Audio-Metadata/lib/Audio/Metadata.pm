package Audio::Metadata;
{
  $Audio::Metadata::VERSION = '0.16';
}
BEGIN {
  $Audio::Metadata::VERSION = '0.15';
}

use strict;
use warnings;

use Path::Class;
use Any::Moose;


has path => ( isa => 'Path::Class::File', is => 'ro', );


__PACKAGE__->meta->make_immutable;


sub BUILDARGS {
    ## Builds object from file name given as string.
    my $self = shift;
    my ($file_name) = @_;

    return {
        path => Path::Class::File->new($file_name),
    };
}


sub new_from_path {
    ## Reads file with given name and returns an object representing it. Object is of type specific
    ## to the codec, i.e.: Audio::Tag::PlainText::AudioFile::Flac, Audio::Tag::PlainText::AudioFile::Mp3
    my $class = shift;
    my ($file_path) = @_;

    # Derive type-specific module name from file extension.
    my ($extension) = $file_path =~ /\.([^.]+)$/;
    my $file_class_name = __PACKAGE__ . '::' . ucfirst($extension);

    # Load appropriate module, instantiate file object and return it.
    eval "require $file_class_name"
        or die "Could not load plugin for file extension \"$extension\" ($file_path): $@\n";
    return $file_class_name->new($file_path);
}


sub file_path {
    ## Returns absolute path to the file.
    my $self = shift;

    die 'Cannot return path until file is specified' unless $self->path;
    return $self->path->absolute . '';
}


sub get_var {
    ## Returns value of specified metadata variable.
    my $self = shift;
    my ($var) = @_;

    die 'Call to abstract method';
}


sub set_var {
    ## Sets specified metadata variable to given value. Value of 'undef' will prompt
    ## removal of the variable, if underlying format permits.
    my $self = shift;
    my ($var, $value) = @_;

    die 'Call to abstract method';
}


sub vars_as_hash {
    ## Returns metadata as hash reference.
    my $self = shift;

    die 'Call to abstract method';
}


sub as_text {
    ## Returns complete file information as space-separated key/value
    ## pairs in multi-line string.
    my $self = shift;

    my $vars = $self->vars_as_hash;
    return join("\n",
                '_FILE_NAME ' . $self->file_path,
                map $_ . ' ' . $vars->{$_}, sort keys %$vars) . "\n";
}


sub save {
    ## Writes metadata to file.
    my $self = shift;

    die 'Call to abstract method';
}


sub file_to_text {
    ## Class method. Returns text metadata for the specified file.
    my $class = shift;
    my ($path) = @_;

    my $metadata = $class->new_from_path($path);
    return $metadata->as_text;
}


no Any::Moose;

1;


__END__

=head1 NAME

Audio::Metadata - Manipulate metadata in audio files

=cut

=head1 DESCRIPTION

The aim of this module suite is to read and write metadata in various audio formats with
minimum limitations and no dependencies on external libraries.

This module defines the API and implements common methods.  Format-specific functionality
is implemented in subclasses of Audio::Metadata, such as L<Audio::Metadata::Flac>.

=head1 SYNOPSIS

 my $metadata = Audio::Metadata->new_from_path('/home/user/audio/song.flac');
 $metadata->set_var(artist => 'Joe Zawinul');
 $metadata->save;

=head1 METHODS AND FUNCTIONS

=head3 C<new_from_path($file_path)>

=over

Builds object from file name given as string. Reads file with given name and returns an object representing it. Object is of type specific to the codec, i.e.: Audio::Tag::PlainText::AudioFile::Flac, Audio::Tag::PlainText::AudioFile::Mp3 

=back

=head3 C<file_path($extension)>

=over

Returns absolute path to the file. 

=back

=head3 C<get_var($var)>

=over

Returns value of specified metadata variable. 

=back

=head3 C<set_var($var, $value)>

=over

Sets specified metadata variable to given value. Value of 'undef' will prompt removal of the variable, if underlying format permits. 

=back

=head3 C<vars_as_hash()>

=over

Returns metadata as hash reference. 

=back

=head3 C<as_text()>

=over

Returns complete file information as space-separated key/value pairs in multi-line string. 

=back

=head3 C<save()>

=over

Writes metadata to file. 

=back

=head3 C<file_to_text($path)>

=over

Class method. Returns text metadata for the specified file. 

=back

=head1 AUTHOR

Egor Shipovalov, C<< <kogdaugodno at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-blogger at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Audio-Metadata>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Audio::Metadata

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audio-Metadata>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audio-Metadata>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audio-Metadata>

=item * Search CPAN

L<http://search.cpan.org/dist/Audio-Metadata/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Egor Shipovalov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
