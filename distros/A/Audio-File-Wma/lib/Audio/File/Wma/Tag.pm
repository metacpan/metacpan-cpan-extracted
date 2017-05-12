package Audio::File::Wma::Tag;

use strict;
use warnings;
use base qw( Audio::File::Tag );
use Audio::WMA;

our $VERSION = '0.02';

sub init {
    my $self = shift;
    $self->{wma} = Audio::WMA->new( $self->{filename} ) or return;
    my $tags = $self->{wma}->tags;

    $self->title(    $tags->{TITLE}    );
    $self->artist(    $tags->{AUTHOR}    );
    $self->album(    $tags->{ALBUMTITLE} || $tags->{ALBUM}    );
    $self->comment(    $tags->{DESCRIPTION}    );
    $self->genre(    $tags->{GENRE}    );
    # It may be possible to parse the date out of
    #   $obj->info->{creation_date} but I don't know the format:
    #   it does not appear to be epoch seconds.
    #   creation_date_unix also exists, but does not appear to be correct.
    $self->year(    $tags->{DATE}    );
    $self->track(    $tags->{TRACKNUMBER}    );
    $self->total(    $tags->{TRACKTOTAL}    );

    return 1;
}

1;
