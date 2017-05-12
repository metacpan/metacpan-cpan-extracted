package Data::ParseBinary::Graphics::BMP;
use strict;
use warnings;
use Data::ParseBinary;

# Windows/OS2 Bitmap (BMP)

#===============================================================================
# pixels: uncompressed
#===============================================================================
sub UncompressedRows {
    my ($subcon, $align_to_byte) = @_;
    # argh! lines must be aligned to a 4-byte boundary, and bit-pixel
    # lines must be aligned to full bytes...
    my $line_pixels;
    if ($align_to_byte) {
        $line_pixels = Bitwise(Array(sub { $_->ctx(2)->{width} }, $subcon));
    } else {
        $line_pixels = Array(sub { $_->ctx(2)->{width} }, $subcon);
    }
    return Array(sub { $_->ctx->{height} }, Aligned($line_pixels, 4));
}

my $uncompressed_pixels = Switch("uncompressed", sub { $_->ctx->{bpp} },
    {
        1 => UncompressedRows(Bit("index"), 1),
        4 => UncompressedRows(Nibble("index"), 1),
        8 => UncompressedRows(Byte("index")),
        24 => UncompressedRows(Sequence("rgb", Byte("red"), Byte("green"), Byte("blue"))),
    }
);

#===============================================================================
# file structure
#===============================================================================
our $bmp_parser = Struct("bitmap_file",
    # header
    Const(String("signature", 2), "BM"),
    ULInt32("file_size"),
    Padding(4),
    ULInt32("data_offset"),
    ULInt32("header_size"),
    Enum(Alias("version", "header_size"),
        v2 => 12,
        v3 => 40,
        v4 => 108,
    ),
    ULInt32("width"),
    ULInt32("height"),
    Value("number_of_pixels", sub { $_->ctx->{width} * $_->ctx->{height} }),
    ULInt16("planes"),
    ULInt16("bpp"), # bits per pixel
    Enum(ULInt32("compression"),
        Uncompressed => 0,
        RLE8 => 1,
        RLE4 => 2,
        Bitfields => 3,
        JPEG => 4,
        PNG => 5,
    ),
    ULInt32("image_data_size"), # in bytes
    ULInt32("horizontal_dpi"),
    ULInt32("vertical_dpi"),
    ULInt32("colors_used"),
    ULInt32("important_colors"),
    
    # palette (24 bit has no palette)
    If( sub { $_->ctx->{bpp} <= 8 },
        Array( sub { 2 ** $_->ctx->{bpp} }, 
            Struct("palette",
                Byte("blue"),
                Byte("green"),
                Byte("red"),
                Padding(1),
            )
        )
    ),
    
    # pixels
    Pointer( sub { $_->ctx->{data_offset} }, 
        Switch("pixels", sub { $_->ctx->{compression} },
            {
                "Uncompressed" => $uncompressed_pixels,
            }
        ),
    ),
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($bmp_parser);

1;


__END__

=head1 NAME

Data::ParseBinary::Graphics::BMP

=head1 SYNOPSIS

    use Data::ParseBinary::Graphics::BMP qw{$bmp_parser};
    my $data = $bmp_parser->parse(CreateStreamReader(File => $fh));

Can parse / build any BMP file, (1, 4, 8 or 24 bit) as long as RLE is not used.

This is a part of the Data::ParseBinary package, and is just one ready-made parser.
please go to the main page for additional usage info.

=cut
