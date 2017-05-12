package Data::Petitcom::BMP;

use strict;
use warnings;

use parent qw{Exporter};
our @EXPORT_OK = qw{ DATA2BMP BMP2DATA Load Dump RGB555toRGB888 RGB888toRGB555 };

use bytes ();
use Carp ();

use constant CHR_WIDTH => 8;
use constant CHR_SIZE  => CHR_WIDTH * CHR_WIDTH;

use constant DEFAULT_COLORMAP => [
    0x000000,0x383838,0xf81800,0xf858c0,0x0038f0,0x7838f8,0x00b8f8,0x905828,0xf8a000,0xf8c8a0,0x007800,0x00f018,0xf8e000,0xb8b8b8,0x000000,0xf8f8f8,
    0x000000,0x282828,0x883028,0x985880,0x203880,0x604890,0x287088,0x584030,0x886028,0xa09080,0x104010,0x208030,0x887828,0x808080,0xf8f8f8,0x000000,
    0xf8f8f8,0xf8f8c8,0xf8f898,0xf8f860,0xf8f830,0xf8f800,0xf8c8f8,0xf8c8c8,0xf8c898,0xf8c860,0xf8c830,0xf8c800,0xf898f8,0xf898c8,0xf89898,0xf89860,
    0xf89830,0xf89800,0xf860f8,0xf860c8,0xf86098,0xf86060,0xf86030,0xf86000,0xf830f8,0xf830c8,0xf83098,0xf83060,0xf83030,0xf83000,0xf800f8,0xf800c8,
    0xf80098,0xf80060,0xf80030,0xf80000,0xc8f8f8,0xc8f8c8,0xc8f898,0xc8f860,0xc8f830,0xc8f800,0xc8c8f8,0xc8c8c8,0xc8c898,0xc8c860,0xc8c830,0xc8c800,
    0xc898f8,0xc898c8,0xc89898,0xc89860,0xc89830,0xc89800,0xc860f8,0xc860c8,0xc86098,0xc86060,0xc86030,0xc86000,0xc830f8,0xc830c8,0xc83098,0xc83060,
    0xc83030,0xc83000,0xc800f8,0xc800c8,0xc80098,0xc80060,0xc80030,0xc80000,0x98f8f8,0x98f8c8,0x98f898,0x98f860,0x98f830,0x98f800,0x98c8f8,0x98c8c8,
    0x98c898,0x98c860,0x98c830,0x98c800,0x9898f8,0x9898c8,0x989898,0x989860,0x989830,0x989800,0x9860f8,0x9860c8,0x986098,0x986060,0x986030,0x986000,
    0x9830f8,0x9830c8,0x983098,0x983060,0x983030,0x983000,0x9800f8,0x9800c8,0x980098,0x980060,0x980030,0x980000,0x60f8f8,0x60f8c8,0x60f898,0x60f860,
    0x60f830,0x60f800,0x60c8f8,0x60c8c8,0x60c898,0x60c860,0x60c830,0x60c800,0x6098f8,0x6098c8,0x609898,0x609860,0x609830,0x609800,0x6060f8,0x6060c8,
    0x606098,0x606060,0x606030,0x606000,0x6030f8,0x6030c8,0x603098,0x603060,0x603030,0x603000,0x6000f8,0x6000c8,0x600098,0x600060,0x600030,0x600000,
    0x30f8f8,0x30f8c8,0x30f898,0x30f860,0x30f830,0x30f800,0x30c8f8,0x30c8c8,0x30c898,0x30c860,0x30c830,0x30c800,0x3098f8,0x3098c8,0x309898,0x309860,
    0x309830,0x309800,0x3060f8,0x3060c8,0x306098,0x306060,0x306030,0x306000,0x3030f8,0x3030c8,0x303098,0x303060,0x303030,0x303000,0x3000f8,0x3000c8,
    0x300098,0x300060,0x300030,0x300000,0x00f8f8,0x00f8c8,0x00f898,0x00f860,0x00f830,0x00f800,0x00c8f8,0x00c8c8,0x00c898,0x00c860,0x00c830,0x00c800,
    0x0098f8,0x0098c8,0x009898,0x009860,0x009830,0x009800,0x0060f8,0x0060c8,0x006098,0x006060,0x006030,0x006000,0x0030f8,0x0030c8,0x003098,0x003060,
    0x003030,0x003000,0x0000f8,0x0000c8,0x000098,0x000060,0x000030,0xe8e8e8,0xd8d8d8,0xb8b8b8,0xa8a8a8,0x888888,0x707070,0x505050,0x404040,0x202020,
];
use constant SPRITE_SIZE => {
    8  => [ 8, 16, 32 ],
    16 => [ 8, 16, 32 ],
    32 => [ 8, 16, 32, 64 ],
    64 => [ 32, 64 ],
};

sub is_valid_width  { $_[0] && $_[0] <= 256 && $_[0] % CHR_WIDTH == 0 }
sub is_valid_height { $_[0] && $_[0] <= 192 && $_[0] % CHR_WIDTH == 0 }
sub is_valid_spsize {
    my ($width, $height) = @_;
    return unless ($width && $height);
    for ( @{ SPRITE_SIZE->{$width} } ) { return 1 if ( $height == $_ ) }
}

sub _xy(&;%) {
    my $code = shift;

    my %opts      = @_;
    my $width     = delete $opts{width} || 256;
    my $height    = delete $opts{height} || 64;
    my $sp_width  = delete $opts{sp_width} || 16;
    my $sp_height = delete $opts{sp_height} || 16;
    my $vflip     = delete $opts{vflip};
    my $debug     = delete $opts{debug};
    Carp::croak "invalid sp_width: $sp_width"
        if ( $sp_width > $width || $width % $sp_width );
    Carp::croak "invalid sp_height: $sp_height"
        if ( $sp_height > $height || $height % $sp_height );

    my $sp_cols = $width / $sp_width;
    my $sp_rows = $height / $sp_height;
    my $sp_nums = $sp_cols * $sp_rows;
    my $sp_size = $sp_width * $sp_height;

    my $chr_cols = $sp_width / CHR_WIDTH;
    my $chr_rows = $sp_height / CHR_WIDTH;
    my $chr_nums = $chr_cols * $chr_rows;

    my $flip_y = ($vflip) ? ($height - 1) : 0;
    for my $i ( 0 .. ( $sp_nums - 1 ) ) {
        my $sp_x = $i % $sp_cols * $sp_width;
        my $sp_y = int( $i / $sp_cols ) * $sp_height;

        for my $j ( 0 .. ( $chr_nums - 1 ) ) {
            my $chr_x = $sp_x + ( $j % $chr_cols * CHR_WIDTH );
            my $chr_y = $sp_y + ( int( $j / $chr_cols ) * CHR_WIDTH );

            for my $k ( 0 .. ( CHR_SIZE - 1 ) ) {
                my $x = $chr_x + ( $k % CHR_WIDTH );
                my $y = abs( $flip_y - ( $chr_y + ( int( $k / CHR_WIDTH ) ) ) );

                print STDERR sprintf("(% 3d, % 3d)\n", $x, $y) if ($debug);

                my $pixel = $code->( $x, $y, {
                    width     => $width,
                    height    => $height,
                    sp_width  => $sp_width,
                    sp_height => $sp_height,
                    count     => ( $sp_size * $i ) + ( CHR_SIZE * $j ) + $k,
                } );
            }

        }

    }
}

sub DATA2BMP {
    my ($data, %opts) = @_;
    my $width     = delete $opts{width}     || 256;
    Carp::croak "invalid width: $width"
        unless ( is_valid_width($width) );
    my $height    = delete $opts{height}    || 64;
    Carp::croak "invalid height: $height"
        unless ( is_valid_height($height) );
    my $sp_width  = delete $opts{sp_width}  || 16;
    my $sp_height = delete $opts{sp_height} || 16;
    Carp::croak "invalid sprite size: $sp_width x $sp_height "
        unless( is_valid_spsize($sp_width, $sp_height ) );

    my @pixels;
    _xy {
        my ( $x, $y, $info ) = @_;
        my $index = $width * $y + $x;
        $pixels[$index] = bytes::substr $data, $info->{count}, 1;
    }
    width     => $width,
    height    => $height,
    sp_width  => $sp_width,
    sp_height => $sp_height,
    vflip     => 1,
    debug     => 0;

    return Dump(
        width  => $width,
        height => $height,
        pixels => [ map { unpack 'C', $_ } @pixels ],
    );
}

sub BMP2DATA {
    my ($raw_bmp, %opts) = @_;
    my $sp_width   = delete $opts{sp_width}   || 16;
    my $sp_height  = delete $opts{sp_height}  || 16;
    Carp::croak "invalid sprite size: $sp_width x $sp_height "
        unless( is_valid_spsize($sp_width, $sp_height ) );

    my $bmp = Load($raw_bmp);
    my $data;
    _xy {
        my ( $x, $y ) = @_;
        my $offset = $bmp->{width} * ( ( $bmp->{height} - 1 ) - $y ) + $x;
        $data .= pack( 'C', $bmp->{pixels}->[$offset] );
    }
    width     => $bmp->{width},
    height    => $bmp->{height},
    sp_width  => $sp_width,
    sp_height => $sp_height,
    debug     => 0;

    return $data;
}

sub Load {
    my $raw_bmp = shift;

    my @file_header = unpack 'a2VvvV', bytes::substr( $raw_bmp, 0, 14 );
    my $type = $file_header[0];
    Carp::croak "invalid type: $type"
        if ( $type ne 'BM' );

    my @info_header = unpack 'VVVvvVVVVVV', bytes::substr( $raw_bmp, 0x0E, 40 );
    my $width = $info_header[1];
    Carp::croak "invalid width: $width"
        unless ( is_valid_width($width) );
    my $height = $info_header[2];
    Carp::croak "invalid height: $height"
        unless ( is_valid_height($height) );
    my $bit = $info_header[4];
    Carp::croak "invalid bit: $bit"
        if ( $bit != 8 );

    my @colormap = unpack 'V*', bytes::substr( $raw_bmp, 0x36,   256 * 4 );
    my @pixels   = unpack 'C*', bytes::substr( $raw_bmp, 0x0436, $width * $height );
    if ( my $lack = ( $width * $height ) - @pixels ) {
        push @pixels, 0x00 for ( 1 .. $lack );
    }

    return +{
        width    => $width,
        height   => $height,
        colormap => \@colormap,
        pixels   => \@pixels,
    };
}

sub Dump {
    my $bmp = ( ref $_[0] eq 'HASH' ) ? shift : {@_};

    my $width    = delete $bmp->{width};
    Carp::croak "invalid width: $width"
        unless ( is_valid_width($width) );
    my $height   = delete $bmp->{height};
    Carp::croak "invalid height: $height"
        unless ( is_valid_height($height) );
    my $colormap = delete $bmp->{colormap} || DEFAULT_COLORMAP;
    Carp::croak "invalid colormap: " . scalar @$colormap
        if ( scalar @$colormap != 256 );
    my $pixels   = delete $bmp->{pixels};
    Carp::croak "pixels mismatch: " . scalar @$pixels
        if ( scalar @$pixels != $width * $height );

    my $size = 14 + 40 + 256 * 4 + $width * $height;
    my $raw_bmp = pack 'a2VvvV', "BM", $size, 0, 0, 14 + 40;
    $raw_bmp .= pack "VVVvvVVVVVV", 40, $width, $height, 1, 8, 0, 0, 0, 0, 0, 0;
    $raw_bmp .= pack 'V*', @$colormap;
    $raw_bmp .= pack 'C*', @$pixels;

    return $raw_bmp;
}

sub RGB888toRGB555 {
    my $rgb888 = (ref $_[0] eq 'ARRAY') ? shift : [ @_ ];
    my @rgb555 = map {
        my $rgb = $_;
        my ( $r, $g, $b ) = map { $_ >> 3 } (
            ($rgb >> 16 ) & 0xFF,
            ($rgb >> 8 ) & 0xFF,
            $rgb & 0xFF,
        );
        # Unused(1), Blue(5), Green(5), Red(5)
        ( $b << 10 ) | ( $g << 5 ) | $r;
    } @$rgb888;
    return \@rgb555;
}

sub RGB555toRGB888 {
    my $rgb555 = (ref $_[0] eq 'ARRAY') ? shift : [ @_ ];
    my @rgb888 = map {
        my $rgb = $_;
        my ($r, $g, $b) = map { $_ << 3 | $_ >> 2 } (
            $rgb & 0x1F,
            ($rgb >> 5) & 0x1F,
            ($rgb >> 10) & 0x1F,
        );
        # Reserved(8), Red(8), Green(8), Blue(8)
        ($r << 16) | ($g << 8) | $b;
    } @$rgb555;
    return \@rgb888;
}



1;
