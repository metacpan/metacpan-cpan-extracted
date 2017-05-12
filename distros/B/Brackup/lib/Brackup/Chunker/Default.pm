package Brackup::Chunker::Default;
use strict;

sub chunks {
    my ($class, $file) = @_;
    my @chunk_list;

    my $root       = $file->root;
    my $chunk_size = $root->chunk_size;
    my $size       = $file->size;

    my $offset = 0;
    while ($offset < $size) {
        my $len = _min($chunk_size, $size - $offset);
        my $chunk = Brackup::PositionedChunk->new(
                                                  file   => $file,
                                                  offset => $offset,
                                                  length => $len,
                                                  );
        push @chunk_list, $chunk;
        $offset += $len;
    }
    return @chunk_list;
}

sub _min {
    return (sort { $a <=> $b } @_)[0];
}

1;
