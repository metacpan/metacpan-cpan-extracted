use strict;
use warnings;

{
    package Data::Petitcom::QRCode;

    use 5.10.0;
    use bytes();

    use base qw{ Exporter };
    our @EXPORT_OK = qw{ plot_qrcode };

    use Carp ();
    use Compress::Zlib ();
    use Digest::MD5;
    use POSIX qw{ ceil floor };
    use GD::Barcode::QRcode;

    use constant PTC_OFFSET_FILENAME     => 0x0C;
    use constant PTC_OFFSET_DATA         => 0x24;
    use constant PTC_OFFSET_RESOURCENAME => 0x2C;

    use constant PTC_QR_SIGNATURE                => 'PT';
    use constant DEFAULT_PTC_QR_VERSION_IMAGE    => 20;
    use constant DEFAULT_PTC_QR_VERSION_TERM     => 4;
    use constant DEFAULT_PTC_QR_IMAGE_MODULESIZE => 5;

    use constant QR_ECC => +{ L => 0, M => 1, Q => 2, H => 3 };
    use constant QR_VERSION => [
        [ 0,    0,    0,    0 ],
        [ 17,   14,   11,   7 ],
        [ 32,   26,   20,   14 ],
        [ 53,   42,   32,   24 ],
        [ 78,   62,   46,   34 ],
        [ 106,  84,   60,   44 ],
        [ 134,  106,  74,   58 ],
        [ 154,  122,  86,   64 ],
        [ 192,  152,  108,  84 ],
        [ 230,  180,  130,  98 ],
        [ 271,  213,  151,  119 ],
        [ 321,  251,  177,  137 ],
        [ 367,  287,  203,  155 ],
        [ 425,  331,  241,  177 ],
        [ 458,  362,  258,  194 ],
        [ 520,  412,  292,  220 ],
        [ 586,  450,  322,  250 ],
        [ 644,  504,  364,  280 ],
        [ 718,  560,  394,  310 ],
        [ 792,  624,  442,  338 ],
        [ 858,  666,  482,  382 ],
        [ 929,  711,  509,  403 ],
        [ 1003, 779,  565,  439 ],
        [ 1091, 857,  611,  461 ],
        [ 1171, 911,  661,  511 ],
        [ 1273, 997,  715,  535 ],
        [ 1367, 1059, 751,  593 ],
        [ 1465, 1125, 805,  625 ],
        [ 1528, 1190, 868,  658 ],
        [ 1628, 1264, 908,  698 ],
        [ 1732, 1370, 982,  742 ],
        [ 1840, 1452, 1030, 790 ],
        [ 1952, 1538, 1112, 842 ],
        [ 2068, 1628, 1168, 898 ],
        [ 2188, 1722, 1228, 958 ],
        [ 2303, 1809, 1283, 983 ],
        [ 2431, 1911, 1351, 1051 ],
        [ 2563, 1989, 1423, 1093 ],
        [ 2699, 2099, 1499, 1139 ],
        [ 2809, 2213, 1579, 1219 ],
        [ 2953, 2331, 1663, 1273 ],
    ];

    my %defaults = (
        type    => 'text',
        ecc     => 'M',
        version => DEFAULT_PTC_QR_VERSION_IMAGE
    );
    eval "sub $_ { \@_ > 1 ? \$_[0]->{$_} = \$_[1] : \$_[0]->{$_} }" for keys %defaults;

    sub new {
        my $class = ref $_[0] ? ref shift : shift;
        my $self = bless {@_}, $class;
        $self->init() if ( $self->can('init') );
        return $self;
    }

    sub init {
        my $self = shift;
        for ( keys %defaults ) {
            my $value = $self->{$_} || $defaults{$_};
            ( $self->can($_) ) ? $self->$_($value) : ( $self->{$_} = $value );
        }
        return $self;
    }

    sub plot_qrcode {
        my ($ptc, %opts) = @_;
        my $qrcode = __PACKAGE__->new(%opts);
        return $qrcode->plot($ptc);
    }

    sub plot {
        my $self    = shift;
        my $raw_ptc = shift;
        return $self->_generate_qrcode($raw_ptc);
    }

    sub _generate_qrcode {
        my $self    = shift;
        my $raw_ptc = shift;

        my $plot_type = $self->type;
        my $ecc       = $self->ecc;
        my $version   = $self->version;

        my $qr_bin           = _create_qr_bin($raw_ptc);
        my $max_qr_data_size = _max_qr_data_size( $version, QR_ECC->{$ecc} );
        my $number_of_qr     = _number_of_qr( bytes::length($qr_bin), $max_qr_data_size );
        my $qr_opts          = {
            Ecc        => $ecc,
            Version    => $version,
            ModuleSize => ( $plot_type eq 'image' )
            ? DEFAULT_PTC_QR_IMAGE_MODULESIZE
            : 1
        };

        my @qrcode = ();
        for my $count_qr ( 1 .. $number_of_qr ) {
            my $a_qr_data = bytes::substr( $qr_bin, ( $count_qr - 1 ) * $max_qr_data_size, $max_qr_data_size );

            my $a_qr_bin = PTC_QR_SIGNATURE;
            $a_qr_bin .= pack 'C', $count_qr;
            $a_qr_bin .= pack 'C', $number_of_qr;
            $a_qr_bin .= Digest::MD5::md5($a_qr_data);
            $a_qr_bin .= Digest::MD5::md5($qr_bin);
            $a_qr_bin .= $a_qr_data;

            my $qrcode = undef;
            given ($plot_type) {
                when ('term') {
                    $qrcode = GD::Barcode::QRcode::Text->new( $a_qr_bin, $qr_opts )->term;
                }
                when ('image') {
                    my $gd = GD::Barcode::QRcode->new( $a_qr_bin, $qr_opts )->plot;
                    $gd->string(
                        GD::Font->Large,
                        5, 2,    # 0, 0 => left-top
                        "$count_qr / $number_of_qr",
                        $gd->colorAllocate( 0, 0, 0 ),    # black
                    );
                    $qrcode = $gd->png;
                }
                default {
                    $qrcode = GD::Barcode::QRcode::Text->new( $a_qr_bin, $qr_opts )->barcode;
                }
            }
            push @qrcode, $qrcode;
        }

        return \@qrcode;
    }

    sub _deflate_data {
        my $code     = shift;
        my $deflater = Compress::Zlib::deflateInit()
            or Carp::croak "deflateInit() failed: $!";

        my $zdata = $deflater->deflate($code);
        $zdata .= $deflater->flush();

        return $zdata;
    }

    sub _create_qr_bin {
        my $raw_ptc = shift || return;

        my $filename = unpack 'Z*', bytes::substr( $raw_ptc, PTC_OFFSET_FILENAME, 8 );
        my $resource = bytes::substr( $raw_ptc, PTC_OFFSET_RESOURCENAME, 4 );
        my $data     = bytes::substr( $raw_ptc, PTC_OFFSET_DATA );
        my $zdata    = _deflate_data($data);

        my $qr_bin = bytes::substr( $filename . "\x00" x 8, 0, 8 );
        $qr_bin .= $resource;
        $qr_bin .= pack 'I', bytes::length($zdata);
        $qr_bin .= pack 'I', ( bytes::length($raw_ptc) - PTC_OFFSET_DATA );
        $qr_bin .= $zdata;

        return $qr_bin;
    }

    sub _max_qr_data_size {
        my $version = shift || DEFAULT_PTC_QR_VERSION_TERM;
        my $ecc     = shift // 1;

        Carp::croak "version between 1 and 24"
            if ( $version < 1 || $version > 24 );
        Carp::croak "ecc between 0 and 3"
            if ( $ecc < 0 || $ecc > 3 );
        Carp::croak "invalid combination of version x ecc: $version x $ecc"
            if (QR_VERSION->[$version]->[$ecc] <= PTC_OFFSET_DATA);

        return QR_VERSION->[$version]->[$ecc] - PTC_OFFSET_DATA;
    }

    sub _number_of_qr {
        my ( $total_size, $part_size ) = @_;
        return floor( $total_size / $part_size ) + 1;
    }
}

{
    package GD::Barcode::QRcode::Text;

    use parent qw{ GD::Barcode::QRcode };
    use bytes ();
    use Term::ANSIColor;

    sub new {
        my $class = shift;
        my $self  = $class->SUPER::new(@_);
        bless $self, $class;
        return $self;
    }

    sub barcode {
        my $self = shift;
        return _trim_margin( $self->SUPER::barcode() );
    }

    sub term {
        my $self      = shift;
        my $qr_text   = $self->barcode;
        my $term_text = '';

        for my $i ( 0 .. ( bytes::length($qr_text) - 1 ) ) {
            my $module = bytes::substr $qr_text, $i, 1;
            $term_text .=
                ( $module =~ /^[01]$/ )
                ? colored( '  ', ($module) ? 'on_black' : 'on_white' ) # 2 spaces width
                : $module;
        }

        return $term_text;
    }

    sub _trim_margin {
        my $qr_text   = shift;
        my $qr_aryref = [ map { [ split //, $_ ] } split /\n/, $qr_text ];
        my $ret_text  = '';

        for my $i ( 3 .. ( ( @$qr_aryref - 1 ) - 3 ) ) {
            my $line = $qr_aryref->[$i];
            for my $j ( 3 .. ( ( @$line - 1 ) - 3 ) ) {
                $ret_text .= $line->[$j];
            }
            $ret_text .= "\n";
        }

        return $ret_text;
    }
}

1;
