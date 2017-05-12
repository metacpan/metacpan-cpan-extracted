package Audio::File::Wav;

use strict;
use warnings;
use base qw( Audio::File::Type );
use Audio::File::Wav::Tag;
use Audio::File::Wav::AudioProperties;

our $VERSION = '0.01a';

=head1 NAME

Audio::File::Wav - represents a Microsoft WAV audio file

=head1 DESCRIPTION

An extension to Audio::File enabling support for Microsoft WAV files.

Uses Audio::Wav internally to parse necessary information from the file.

=head1 SEE ALSO

L<Audio::Wav>, L<Audio::File>, L<Audio::File::Tag>, L<Audio::File::AudioProperties>

=cut

sub init {
	return 1;
}

sub _create_tag {
	my $self = shift;
	$self->{tag} = Audio::File::Wav::Tag->new( $self->name() ) or return;
	return 1;
}

sub _create_audio_properties {
	my $self = shift;
	$self->{audio_properties} = Audio::File::Wav::AudioProperties->new( $self->name() ) or return;
	return 1;
}

1;

=head1 ACKNOWLEDGEMENTS

Thanks to Florian Ragwitz for writing Audio::File

=head1 AUTHORS

Nathaniel Heinrichs E<lt>nheinric@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2009 Nathaniel Heinrichs.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut
