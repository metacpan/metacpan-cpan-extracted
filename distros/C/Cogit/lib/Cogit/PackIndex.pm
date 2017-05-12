package Cogit::PackIndex;
$Cogit::PackIndex::VERSION = '0.001001';
use Moo;
use Path::Class 'file';
use Check::ISA;
use IO::File;
use MooX::Types::MooseLike::Base qw( InstanceOf ArrayRef Str Int );
use namespace::clean;

has filename => (
    is => 'ro',
    isa      => InstanceOf['Path::Class::File'],
    coerce   => sub { file($_[0]) },
    required => 1,
);

has fh => (
    is => 'rw',
    isa => InstanceOf['IO::File'],
);

has offsets => (
    is => 'rw',
    isa => ArrayRef[Int],
);

has size => (
    is => 'rw',
    isa => Int,
);

my $FanOutCount   = 256;
my $SHA1Size      = 20;
my $IdxOffsetSize = 4;
my $OffsetSize    = 4;
my $CrcSize       = 4;
my $OffsetStart   = $FanOutCount * $IdxOffsetSize;
my $SHA1Start     = $OffsetStart + $OffsetSize;
my $EntrySize     = $OffsetSize + $SHA1Size;
my $EntrySizeV2   = $SHA1Size + $CrcSize + $OffsetSize;

sub BUILD {
    my $self     = shift;
    my $filename = $self->filename;

    my $fh = IO::File->new($filename) || confess($!);
    $self->fh($fh);

    my @offsets = (0);
    $fh->seek( $self->global_offset, 0 );
    for my $i ( 0 .. $FanOutCount - 1 ) {
        $fh->read( my $data, $IdxOffsetSize );
        my $offset = unpack( 'N', $data );
        confess("pack has discontinuous index") if $offset < $offsets[-1];
        push @offsets, $offset;
    }
    $self->offsets( \@offsets );
    $self->size( $offsets[-1] );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::PackIndex

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
