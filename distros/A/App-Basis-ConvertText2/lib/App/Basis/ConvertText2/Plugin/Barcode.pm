
=head1 NAME

App::Basis::ConvertText::Plugin::Barcode

=head1 SYNOPSIS

    my $content = "12345678" ;
    my $params = { 
        type   => "EAN8"
    } ;
    my $obj = App::Basis::ConvertText2::Plugin::Barcode->new() ;
    my $out = $obj->process( 'barcode', $content, $params) ;

=head1 DESCRIPTION

convert a text string into a QRcode PNG, requires qrencode program

=cut

# ----------------------------------------------------------------------------

package App::Basis::ConvertText2::Plugin::Barcode;
$App::Basis::ConvertText2::Plugin::Barcode::VERSION = '0.4';
use 5.10.0;
use strict;
use warnings;
use Path::Tiny;
use Capture::Tiny ':all';
use Image::Resize;
use GD::Barcode;
use Moo;
use App::Basis;
use App::Basis::ConvertText2::Support;
use namespace::autoclean;

has handles => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [qw{qrcode barcode}] }
);

use constant QRCODE => 'qrencode';

my @_barcodes = (
    qw(Code39 EAN13 EAN8 COOP2of5 IATA2of5 Industrial2of5
        ITF Matrix2of5 NW7 QRcode UPCA UPCE)
);
my %valid_barcodes = map { lc($_) => $_ } @_barcodes;

# ----------------------------------------------------------------------------

=item barcode

create a qrcode image, just use default options for now


 parameters
    filename - filename to save the created image as 

 hashref params of
        size    - size of image, widthxheight - optional
        version - version of the qrcode to create, defaults to 2
        pixels  - number of pixels that make a bit, defaults to 2

=cut

sub process {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;
    my $qrcode ;

    # we have a special tag handler for qrcodes
    if ( $tag eq 'qrcode' ) {
        $params->{type} = 'QRcode';
        $qrcode->{Version} = $params->{version} || 2 ;
        $qrcode->{ModuleSize} = $params->{pixels} || 2 ;
    }

    # strip any ending linefeed
    chomp $content;
    return "" if ( !$content );

    # get the type as BG::Barcode understands it    
    my $type = $valid_barcodes{ lc($params->{type}) } ;
    # check if we can process this barcode
    if ( !$type ) {

        warn "$params->{type} is not a valid barcode type";

        # let the caller put the block back together
        return undef;
    }

    # we can use the cache or process everything ourselves
    my $sig = create_sig( $content, $params );
    my $filename = cachefile( $cachedir, "$sig.png" );
    if ( !-f $filename ) {
        my $gdb ;
        # sometimes it throws out some warnings, lets hide them
        my ($stdout, $stderr, @result) = capture {
            $gdb = GD::Barcode->new( $type, $content, $qrcode );
        } ;
        if ( !$gdb ) {
            warn "warning $tag $params->{type}: " .  $GD::Barcode::errStr;
            return undef;
        }
        my $gd = $gdb->plot( NoText => $params->{notext}, Height => $params->{height} );
        path($filename)->spew_raw( $gd->png );

        # my $cmd = QRCODE . " -o$filename '$content'";
        # my ( $exit, $stdout, $stderr ) = run_cmd($cmd);

        # for some reason qrcodes may need scaling
        if ( -f $filename && $type eq 'QRcode' && $params->{height}) {
            my $image = Image::Resize->new($filename);
            my $gd = $image->resize( $params->{height}, $params->{height} );

            # overwrite original file with resized version
            if ($gd) {
                path($filename)->spew_raw( $gd->png );
            }
        }
    }

    my $out;
    if ( -f $filename ) {

        # create something suitable for the HTML
        $out = create_img_src( $filename, $params->{title} ) . "\n" ;
    }
    return $out;
}

# ----------------------------------------------------------------------------

1;
