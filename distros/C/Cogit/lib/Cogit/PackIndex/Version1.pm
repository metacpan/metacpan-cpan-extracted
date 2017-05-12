package Cogit::PackIndex::Version1;
$Cogit::PackIndex::Version1::VERSION = '0.001001';
use Moo;
use namespace::clean;

extends 'Cogit::PackIndex';

my $FanOutCount   = 256;
my $SHA1Size      = 20;
my $IdxOffsetSize = 4;
my $OffsetSize    = 4;
my $CrcSize       = 4;
my $OffsetStart   = $FanOutCount * $IdxOffsetSize;
my $SHA1Start     = $OffsetStart + $OffsetSize;
my $EntrySize     = $OffsetSize + $SHA1Size;
my $EntrySizeV2   = $SHA1Size + $CrcSize + $OffsetSize;

sub global_offset {
    return 0;
}

sub all_sha1s {
    my ( $self, $want_sha1 ) = @_;
    my $fh = $self->fh;
    my @sha1s;

    my $pos = $OffsetStart;
    $fh->seek( $pos, 0 ) || die $!;
    for my $i ( 1 .. $self->size ) {
        $fh->read( my $data, $OffsetSize ) || die $!;
        my $offset = unpack( 'N', $data );
        $fh->read( $data, $SHA1Size ) || die $!;
        my $sha1 = unpack( 'H*', $data );
        push @sha1s, $sha1;
        $pos += $EntrySize;
    }
    return @sha1s;
}

sub get_object_offset {
    my ( $self, $want_sha1 ) = @_;
    my @offsets = @{$self->offsets};
    my $fh      = $self->fh;

    my $slot = unpack( 'C', pack( 'H*', $want_sha1 ) );
    return unless defined $slot;

    my ( $first, $last ) = @offsets[ $slot, $slot + 1 ];

    while ( $first < $last ) {
        my $mid = int( ( $first + $last ) / 2 );
        $fh->seek( $SHA1Start + $mid * $EntrySize, 0 ) || die $!;
        $fh->read( my $data, $SHA1Size ) || die $!;
        my $midsha1 = unpack( 'H*', $data );
        if ( $midsha1 lt $want_sha1 ) {
            $first = $mid + 1;
        } elsif ( $midsha1 gt $want_sha1 ) {
            $last = $mid;
        } else {
            my $pos = $OffsetStart + $mid * $EntrySize;
            $fh->seek( $pos, 0 ) || die $!;
            $fh->read( my $data, $OffsetSize ) || die $!;
            my $offset = unpack( 'N', $data );
            return $offset;
        }
    }

    return;
}

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::PackIndex::Version1

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
