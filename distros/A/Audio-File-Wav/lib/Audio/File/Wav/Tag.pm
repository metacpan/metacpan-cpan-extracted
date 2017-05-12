package Audio::File::Wav::Tag;

use strict;
use warnings;
use base qw( Audio::File::Tag );
use Audio::Wav;

our $VERSION = '0.01';

=head1 NOTE
 The t/test.wav file does contain metadata ('tags') for 'Music',
   'BWAV' and 'Soundminer', but these are not standard.

 Audio::Wav will throw warnings when processing this file
   because it does not understand the non-standard metadata blocks.

 If Audio::Wav is modified to parse these blocks in the future,
   I will add support here.

=cut

sub init {
    my $self = shift;
    my $aw = Audio::Wav->new();
    $self->{wav} = $aw->read( $self->{filename} ) or return;
    my $info = $self->{wav}->get_info;

	$self->title(	$info->{TITLE}		);
	$self->artist(	$info->{ARTIST}		);
	$self->album(	$info->{ALBUM}		);
	$self->comment(	$info->{DESCRIPTION}	);
	$self->genre(	$info->{GENRE}		);
	$self->year(	$info->{DATE}		);
	$self->track(	$info->{TRACKNUMBER}	);
	$self->total(	$info->{TRACKTOTAL}	);

	return 1;
}

1;
