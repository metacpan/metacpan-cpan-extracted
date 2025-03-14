package Cogit::Pack::WithoutIndex;
$Cogit::Pack::WithoutIndex::VERSION = '0.001001';
use Moo;
use IO::Digest;
use MooX::Types::MooseLike::Base 'HashRef';
use Carp 'confess';
use namespace::clean;

extends 'Cogit::Pack';

has offsets => (
    is => 'rw',
    isa => HashRef,
);

my @TYPES = (qw(none commit tree blob tag), '', 'ofs_delta', 'ref_delta' );

sub create_index {
    my ($self) = @_;
    my $index_filename = $self->filename;
    $index_filename =~ s/\.pack/.idx/;
    my $index_fh = IO::File->new("> $index_filename") || die $!;

    my $iod = IO::Digest->new( $index_fh, 'SHA' );

    my $offsets = $self->create_index_offsets;
    my @fan_out_table;
    for my $sha1 ( sort keys %$offsets ) {
        my $offset = $offsets->{$sha1};
        my $slot = unpack( 'C', pack( 'H*', $sha1 ) );
        $fan_out_table[$slot]++;
    }
    for my $i ( 0 .. 255 ) {
        $index_fh->print( pack( 'N', $fan_out_table[$i] || 0 ) ) || die $!;
        $fan_out_table[ $i + 1 ] += $fan_out_table[$i] || 0;
    }
    for my $sha1 ( sort keys %$offsets ) {
        my $offset = $offsets->{$sha1};
        $index_fh->print( pack( 'N',  $offset ) ) || die $!;
        $index_fh->print( pack( 'H*', $sha1 ) )   || die $!;
    }

    # read the pack checksum from the end of the pack file
    my $size = -s $self->filename;
    my $fh   = $self->fh;
    $fh->seek( $size - 20, 0 ) || die $!;
    my $read = $fh->read( my $pack_sha1, 20 ) || die $!;

    $index_fh->print($pack_sha1) || die $!;
    $index_fh->print( $iod->digest ) || die $!;

    $index_fh->close() || die $!;
}

sub create_index_offsets {
    my ($self) = @_;
    my $fh = $self->fh;

    $fh->read( my $signature, 4 );
    $fh->read( my $version,   4 );
    $version = unpack( 'N', $version );
    $fh->read( my $objects, 4 );
    $objects = unpack( 'N', $objects );

    my %offsets;
    $self->offsets( \%offsets );

    for my $i ( 1 .. $objects ) {
        my $offset = $fh->tell || die "Error telling filehandle: $!";
        my $obj_offset = $offset;
        $fh->read( my $c, 1 ) || die "Error reading from pack: $!";
        $c = unpack( 'C', $c ) || die $!;
        $offset++;

        my $size        = ( $c & 0xf );
        my $type_number = ( $c >> 4 ) & 7;
        my $type        = $TYPES[$type_number]
            || confess
            "invalid type $type_number at offset $offset, size $size";

        my $shift = 4;

        while ( ( $c & 0x80 ) != 0 ) {
            $fh->read( $c, 1 ) || die $!;
            $c = unpack( 'C', $c ) || die $!;
            $offset++;
            $size |= ( ( $c & 0x7f ) << $shift );
            $shift += 7;
        }

        my $content;

        if ( $type eq 'ofs_delta' || $type eq 'ref_delta' ) {
            ( $type, $size, $content )
                = $self->unpack_deltified( $type, $offset, $obj_offset, $size,
                \%offsets );
        } elsif ( $type eq 'commit'
            || $type eq 'tree'
            || $type eq 'blob'
            || $type eq 'tag' )
        {
            $content = $self->read_compressed( $offset, $size );
        } else {
            confess "invalid type $type";
        }

        my $raw  = $type . ' ' . $size . "\0" . $content;
        my $sha1 = Digest::SHA->new;
        $sha1->add($raw);
        my $sha1_hex = $sha1->hexdigest;
        $offsets{$sha1_hex} = $obj_offset;
    }

    return \%offsets;
}

sub get_object {
    my ( $self, $want_sha1 ) = @_;
    my $offset = $self->offsets->{$want_sha1};
    return unless $offset;
    return $self->unpack_object($offset);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Pack::WithoutIndex

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
