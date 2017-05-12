package Bb::Collaborate::V3::Recording::File;
use warnings; use strict;

use Mouse;

extends 'Bb::Collaborate::V3';

use Scalar::Util;
use Carp;

use Elive::Util;

=head1 NAME

Bb::Collaborate::V3::Recording::File - Collaborate Recording File response class

=head1 DESCRIPTION

This class is used to return responses to recording conversion requests.

=cut

has 'recordingId' => (is => 'rw', isa => 'Int', required => 1);
__PACKAGE__->primary_key('recordingId');
__PACKAGE__->entity_name('RecordingFile');
__PACKAGE__->params(format => 'Str');

has 'recordingStatus' => (is => 'rw', isa => 'Str', required => 1);

=head2 convert_recording

    Bb::Collaborate::V3::RecordingFile->convert_recording( recording_id => $recording_id, format => 'mp4' );

=cut

sub convert_recording {
    my ($class, %opt) = @_;

    my $connection = $opt{connection} || $class->connection
	or croak "Not connected";

    my $recording_id = $opt{recording_id} || $opt{recordingId};

    $recording_id ||= $class->recordingId
	if ref($class);

    croak "unable to determine recording_id"
	unless $recording_id;

    my $format = $opt{format} || 'mp3';

    my $command = $opt{command} || 'ConvertRecording';

    my $params = $class->_freeze({recordingId => $recording_id, format => $format});
    my $som = $connection->call( $command, => %$params);

    my $results = $class->_get_results( $som, $connection );

    use YAML::Syck; die "thats all I've got @{[ YAML::Syck::Dump($results) ]}";
}

1;
