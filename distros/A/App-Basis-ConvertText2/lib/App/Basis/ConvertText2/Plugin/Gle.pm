
=head1 NAME

App::Basis::ConvertText2::Plugin::Gle

=head1 SYNOPSIS

    my $content = "size 12 8
    
    set font texcmr
    begin graph
       title  "Fruit Production"
       xtitle "Weekday"
       ytitle "Production [x100 pound]"
       xticks off
       data   "test.dat"
       bar d1,d2 fill navy,skyblue
    end graph" ;
    my $params = {} ;
    my $obj = App::Basis::ConvertText2::Plugin::Gle->new() ;
    my $out = $obj->process( 'gle', $content, $params) ;

=head1 DESCRIPTION

convert a gle/glx text string into a PNG, requires gle program http://glx.sourceforge.net/

=cut

# ----------------------------------------------------------------------------

package App::Basis::ConvertText2::Plugin::Gle;
$App::Basis::ConvertText2::Plugin::Gle::VERSION = '0.4';
use 5.10.0;
use strict;
use warnings;
use Path::Tiny;
use Moo;
use Image::Resize ;
use App::Basis;
use App::Basis::ConvertText2::Support;
use namespace::autoclean;

has handles => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [qw{gle glx}] }
);

use constant GLE => "gle";
use constant RES => 28 ;

# ----------------------------------------------------------------------------

=item gle

create a simple gle image

 parameters
    data   - gle text      
    filename - filename to save the created image as 

 hashref params of
        title       - title to use for image alt attribute
        size        - size of image, widthxheight - optional, default 720x512
        transparent - flag to set background transparent - optional

=cut

sub process {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;
    $params->{size} ||= "720x512";
    my ( $x, $y ) = ( $params->{size} =~ /^\s*(\d+)\s*x\s*(\d+)\s*$/ );

    # strip any ending linefeed
    chomp $content;
    return "" if ( !$content );

    # we can use the cache or process everything ourselves
    my $sig = create_sig( $content, $params );
    my $filename = cachefile( $cachedir, "$sig.png" );
    if ( !-f $filename ) {
        my $glefile = Path::Tiny->tempfile("gleXXXXXXXX");

        my $res = sprintf( "size %.4f %.4f", $x / RES, $y / RES) ;
        $content =~ s/size\s+(.*?)\s+(.*?)$//gsm ;
        $content = "$res\n$content" ;

        path($glefile)->spew_utf8($content);

        my $cmd = GLE . ( $params->{transparent} ? " -transparent" : "" ) . " -output $filename $glefile";
        my ( $exit, $stdout, $stderr ) = run_cmd($cmd);
        if ($exit) {
            warn "Could not run script " . GLE . " get it from http://glx.sourceforge.net/";
        }
    }
    my $out;
    if ( -f $filename ) {

        # create something suitable for the HTML
        $out = create_img_src( $filename, $params->{title} );
    }

    return $out;
}

# ----------------------------------------------------------------------------

1;
