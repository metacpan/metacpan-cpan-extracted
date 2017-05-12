package Brackup::Chunker::MP3;
use strict;

my $HAVE_MP3_INFO;
BEGIN {
    $HAVE_MP3_INFO = eval "use MP3::Info (); 1;";
}

sub chunks {
    my ($class, $file) = @_;
    my @chunk_list;
    die "Required module MP3::Info not found.  Needed by the MP3 file chunker.\n"
        unless $HAVE_MP3_INFO;

    my $file_path = $file->path;

    # file might've been renamed or deleted in the meantime:
    warn "File went away: $file_path ; ignoring it.\n" unless -e $file_path;
    return () unless -e $file_path;

    my ($music_offset, $music_size) = main_music_range($file_path);
    my $size       = $file->size;

    # add the ID3v2 header, if necessary:
    if ($music_offset != 0) {
        push @chunk_list, Brackup::PositionedChunk->new(
                                                        file   => $file,
                                                        offset => 0,
                                                        length => $music_offset,
                                                        );
    }

    # add the music chunk (one big chunk, at least for now)
    push @chunk_list, Brackup::PositionedChunk->new(
                                                    file   => $file,
                                                    offset => $music_offset,
                                                    length => $music_size,
                                                    );

    # add the ID3v1 header chunk, if necessary:
    my $music_end = $music_offset + $music_size;
    if ($music_end != $size) {
        push @chunk_list, Brackup::PositionedChunk->new(
                                                        file   => $file,
                                                        offset => $music_end,
                                                        length => $size - $music_end,
                                                        );
    }

    return @chunk_list;
}

sub main_music_range {
    my $file = shift;
    my $size = -s $file;

    # if not an mp3, include the whole file
    unless ($file =~ /\.mp3$/i) {
        return (0, $size);
    }

    my $info = MP3::Info::get_mp3info($file);
    unless ($info && defined $info->{OFFSET}) {
        return (0, $size);
    }

    my $offset = $info->{OFFSET};
    my $tag = MP3::Info::get_mp3tag($file);
    if ($tag && $tag->{TAGVERSION} && $tag->{TAGVERSION} =~ /ID3v1/) {
        return ($offset, $size - $offset - 128);
    }
    return ($offset, $size - $offset);
}


1;

__END__

=head1 NAME

Brackup::Chunker::MP3 - an mp3-aware file chunker

=head1 ABOUT

This chunker knows about the structure of MP3 files (by using
L<MP3::Info>) and will instruct Brackup to backup the metadata and the
audio bytes separately.  That way if you re-tag your music and later
do an interative backup, you only back up the new metadata bits
(tiny).


