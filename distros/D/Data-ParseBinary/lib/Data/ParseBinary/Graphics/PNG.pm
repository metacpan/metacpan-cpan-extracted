package Data::ParseBinary::Graphics::PNG;
use strict;
use warnings;
use Data::ParseBinary;
use Data::ParseBinary qw{GreedyRange};

# Portable Network Graphics (PNG) file format
# Official spec: http://www.w3.org/TR/PNG
#
# Original code contributed by Robin Munn (rmunn at pobox dot com)
# (although the code has been extensively reorganized to meet Construct's
# coding conventions)


#===============================================================================
# utils
#===============================================================================
sub Coord {
    my ($name, $field) = @_;
    $field ||= \&UBInt8;
    return Struct($name,
        &$field("x"),
        &$field("y"),
    );
}

my $compression_method = Enum(UBInt8("compression_method"),
    deflate => 0,
    _default_ => $DefaultPass
);


#===============================================================================
# 11.2.3: PLTE - Palette
#===============================================================================
my $plte_info = Struct("plte_info",
    Value("num_entries", sub { $_->ctx(1)->{length} / 3}),
    Array(sub { $_->ctx->{num_entries} },
        Struct("palette_entries",
            UBInt8("red"),
            UBInt8("green"),
            UBInt8("blue"),
        ),
    ),
);

#===============================================================================
# 11.2.4: IDAT - Image data
#===============================================================================
#my $idat_info = OnDemand(
#    Field("idat_info", sub { $_->ctx->{length} }),
#);
my $idat_info = Field("idat_info", sub { $_->ctx->{length} });

#===============================================================================
# 11.3.2.1: tRNS - Transparency
#===============================================================================
my $trns_info = Switch("trns_info", sub { $_->ctx(1)->{image_header}->{color_type} }, 
    {
        "greyscale" => Struct("data",
            UBInt16("grey_sample")
        ),
        "truecolor" => Struct("data",
            UBInt16("red_sample"),
            UBInt16("blue_sample"),
            UBInt16("green_sample"),
        ),
        "indexed" => Array(sub { $_->ctx->{length} },
            UBInt8("alpha"),
        ),
    }
);

#===============================================================================
# 11.3.3.1: cHRM - Primary chromacities and white point
#===============================================================================
my $chrm_info = Struct("chrm_info",
    Coord("white_point", \&UBInt32),
    Coord("red", \&UBInt32),
    Coord("green", \&UBInt32),
    Coord("blue", \&UBInt32),
);

#===============================================================================
# 11.3.3.2: gAMA - Image gamma
#===============================================================================
my $gama_info = Struct("gama_info",
    UBInt32("gamma"),
);

#===============================================================================
# 11.3.3.3: iCCP - Embedded ICC profile
#===============================================================================
my $iccp_info = Struct("iccp_info",
    CString("name"),
    $compression_method,
    Field("compressed_profile", 
        sub { $_->ctx(1)->{length} - (length( $_->ctx->{name}) + 2) }
    ),
);

#===============================================================================
# 11.3.3.4: sBIT - Significant bits
#===============================================================================
my $sbit_info = Switch("sbit_info", sub { $_->ctx(1)->{image_header}->{color_type} }, 
    {
        "greyscale" => Struct("data",
            UBInt8("significant_grey_bits"),
        ),
        "truecolor" => Struct("data",
            UBInt8("significant_red_bits"),
            UBInt8("significant_green_bits"),
            UBInt8("significant_blue_bits"),
        ),
        "indexed" => Struct("data",
            UBInt8("significant_red_bits"),
            UBInt8("significant_green_bits"),
            UBInt8("significant_blue_bits"),
        ),
        "greywithalpha" => Struct("data",
            UBInt8("significant_grey_bits"),
            UBInt8("significant_alpha_bits"),
        ),
        "truewithalpha" => Struct("data",
            UBInt8("significant_red_bits"),
            UBInt8("significant_green_bits"),
            UBInt8("significant_blue_bits"),
            UBInt8("significant_alpha_bits"),
        ),
    }
);

#===============================================================================
# 11.3.3.5: sRGB - Standard RPG color space
#===============================================================================
my $srgb_info = Struct("srgb_info",
    Enum(UBInt8("rendering_intent"),
        perceptual => 0,
        relative_colorimetric => 1,
        saturation => 2,
        absolute_colorimetric => 3,
        _default_ => $DefaultPass,
    ),
);

#===============================================================================
# 11.3.4.3: tEXt - Textual data
#===============================================================================
my $text_info = Struct("text_info",
    CString("keyword"),
    Field("text", sub { $_->ctx(1)->{length} - (length($_->ctx->{keyword}) + 1) }),
);

#===============================================================================
# 11.3.4.4: zTXt - Compressed textual data
#===============================================================================
my $ztxt_info = Struct("ztxt_info",
    CString("keyword"),
    $compression_method,
#    OnDemand(
        Field("compressed_text",
            # As with iCCP, length is chunk length, minus length of
            # keyword, minus two: one byte for the null terminator,
            # and one byte for the compression method.
            sub { $_->ctx(1)->{length} - (length($_->ctx->{keyword}) + 2) },
        ),
#    ),
);

#===============================================================================
# 11.3.4.5: iTXt - International textual data
#===============================================================================
my $itxt_info = Struct("itxt_info",
    CString("keyword"),
    UBInt8("compression_flag"),
    $compression_method,
    CString("language_tag"),
    CString("translated_keyword"),
 #   OnDemand(
        Field("text",
            sub { $_->ctx(1)->{length} - (length($_->ctx->{keyword}) + length($_->ctx->{language_tag}) + length($_->ctx->{translated_keyword}) + 5) },
        ),
#    ),
);

#===============================================================================
# 11.3.5.1: bKGD - Background color
#===============================================================================
my $bkgd_info = Switch("bkgd_info", sub { $_->ctx(1)->{image_header}->{color_type} }, 
    {
        "greyscale" => Struct("data",
            UBInt16("background_greyscale_value"),
            Alias("grey", "background_greyscale_value"),
        ),
        "greywithalpha" => Struct("data",
            UBInt16("background_greyscale_value"),
            Alias("grey", "background_greyscale_value"),
        ),
        "truecolor" => Struct("data",
            UBInt16("background_red_value"),
            UBInt16("background_green_value"),
            UBInt16("background_blue_value"),
            Alias("red", "background_red_value"),
            Alias("green", "background_green_value"),
            Alias("blue", "background_blue_value"),
        ),
        "truewithalpha" => Struct("data",
            UBInt16("background_red_value"),
            UBInt16("background_green_value"),
            UBInt16("background_blue_value"),
            Alias("red", "background_red_value"),
            Alias("green", "background_green_value"),
            Alias("blue", "background_blue_value"),
        ),
        "indexed" => Struct("data",
            UBInt16("background_palette_index"),
            Alias("index", "background_palette_index"),
        ),
    }
);

#===============================================================================
# 11.3.5.2: hIST - Image histogram
#===============================================================================
my $hist_info = Array(sub { $_->ctx(1)->{length} / 2 },
    UBInt16("frequency"),
);

#===============================================================================
# 11.3.5.3: pHYs - Physical pixel dimensions
#===============================================================================
my $phys_info = Struct("phys_info",
    UBInt32("pixels_per_unit_x"),
    UBInt32("pixels_per_unit_y"),
    Enum(UBInt8("unit"),
        unknown => 0,
        meter => 1,
        _default_ => $DefaultPass,
    ),
);

#===============================================================================
# 11.3.5.4: sPLT - Suggested palette
#===============================================================================
sub splt_info_data_length {
    my $entry_size;
    if ($_->ctx->{sample_depth} == 8) {
        $entry_size = 6;
    } else {
        $entry_size = 10;
    }
    return ($_->ctx(1)->{length} - length($_->ctx->{name}) - 2) / $entry_size;
}

my $splt_info = Struct("data",
    CString("name"),
    UBInt8("sample_depth"),
    Array(\&splt_info_data_length,
        IfThenElse("table", sub { $_->ctx->{sample_depth} == 8 },
            # Sample depth 8
            Struct("table",
                UBInt8("red"),
                UBInt8("green"),
                UBInt8("blue"),
                UBInt8("alpha"),
                UBInt16("frequency"),
            ),
            # Sample depth 16
            Struct("table",
                UBInt16("red"),
                UBInt16("green"),
                UBInt16("blue"),
                UBInt16("alpha"),
                UBInt16("frequency"),
            ),
        ),
    ),
);

#===============================================================================
# 11.3.6.1: tIME - Image last-modification time
#===============================================================================
my $time_info = Struct("data",
    UBInt16("year"),
    UBInt8("month"),
    UBInt8("day"),
    UBInt8("hour"),
    UBInt8("minute"),
    UBInt8("second"),
);

#===============================================================================
# chunks
#===============================================================================
my $default_chunk_info =
#    OnDemand(HexDumpAdapter(
        Field(undef, sub {$_->ctx->{length} }
#    ))
);

my $chunk = Struct("chunk",
    UBInt32("length"),
    String("type", 4),
    Switch("data", sub { $_->ctx->{type} }, 
        {
            "PLTE" => $plte_info,
            "IEND" => $DefaultPass,
            "IDAT" => $idat_info,
            "tRNS" => $trns_info,
            "cHRM" => $chrm_info,
            "gAMA" => $gama_info,
            "iCCP" => $iccp_info,
            "sBIT" => $sbit_info,
            "sRGB" => $srgb_info,
            "tEXt" => $text_info,
            "zTXt" => $ztxt_info,
            "iTXt" => $itxt_info,
            "bKGD" => $bkgd_info,
            "hIST" => $hist_info,
            "pHYs" => $phys_info,
            "sPLT" => $splt_info,
            "tIME" => $time_info,
        },
        default => $default_chunk_info,
    ),
    UBInt32("crc"),
);

my $image_header_chunk = Struct("image_header",
    UBInt32("length"),
    Const(String("type", 4), "IHDR"),
    UBInt32("width"),
    UBInt32("height"),
    UBInt8("bit_depth"),
    Enum(UBInt8("color_type"),
        greyscale => 0,
        truecolor => 2,
        indexed => 3,
        greywithalpha => 4,
        truewithalpha => 6,
        _default_ => $DefaultPass,
    ),
    $compression_method,
    Enum(UBInt8("filter_method"),
        # "adaptive filtering with five basic filter types"
        adaptive5 => 0,
        _default_ => $DefaultPass,
    ),
    Enum(UBInt8("interlace_method"),
        none => 0,
        adam7 => 1,
        _default_ => $DefaultPass,
    ),
    UBInt32("crc"),
);


#===============================================================================
# the complete PNG file
#===============================================================================
our $png_parser = Struct("png",
    Magic("\x89PNG\r\n\x1a\n"),
    $image_header_chunk,
    GreedyRange($chunk),
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($png_parser);

1;

__END__

=head1 NAME

Data::ParseBinary::Graphics::PNG

=head1 SYNOPSIS

    use Data::ParseBinary::Graphics::PNG qw{$png_parser};
    my $data = $png_parser->parse(CreateStreamReader(File => $fh));

Parses the binay PNG format, however it does not decompress the compressed data.
Also, it does not compute / verify the CRC values. 
these actions are left to other layer in the program.

This is a part of the Data::ParseBinary package, and is just one ready-made parser.
please go to the main page for additional usage info.

=cut
