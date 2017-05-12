
=head1 NAME

App::Basis::ConvertText2::Plugin::Gnuplot

=head1 SYNOPSIS

    my $content = "#
    # $Id: surface1.dem,v 1.11 2004/09/17 05:01:12 sfeam Exp $
    #
    set samples 21
    set isosample 11
    set xlabel "X axis" offset -3,-2
    set ylabel "Y axis" offset 3,-2
    set zlabel "Z axis" offset -5
    set title "3D gnuplot demo"
    set label 1 "This is the surface boundary" at -10,-5,150 center
    set arrow 1 from -10,-5,120 to -10,0,0 nohead
    set arrow 2 from -10,-5,120 to 10,0,0 nohead
    set arrow 3 from -10,-5,120 to 0,10,0 nohead
    set arrow 4 from -10,-5,120 to 0,-10,0 nohead
    set xrange [-10:10]
    set yrange [-10:10]
    splot x*y
    " ;
    my $params = {} ;
    my $obj = App::Basis::ConvertText2::Plugin::Gnuplot->new() ;
    my $out = $obj->process( 'gnuplot', $content, $params) ;

=head1 DESCRIPTION

convert a gnuplot text string into a PNG, requires gnuplot program http://gnuplot.sourceforge.net/

=cut

# ----------------------------------------------------------------------------

package App::Basis::ConvertText2::Plugin::Gnuplot;
$App::Basis::ConvertText2::Plugin::Gnuplot::VERSION = '0.4';
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
    default  => sub {[qw{gnuplot}]}
);

# gnuplot is a script to run plantgnuplot basically does java -jar plantgnuplot.jar
use constant GNUPLOT => "gnuplot";

# ----------------------------------------------------------------------------

=item gnuplot

create a simple gnuplot image

 parameters
    data   - gnuplot text      
    filename - filename to save the created image as 

 hashref params of
        title   - title to use for image alt attribute
        size    - size of image, widthxheight - optional, default 720x512

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
        my $gnuplotfile = Path::Tiny->tempfile("gnuplotXXXXXXXX");

        # make sure the output file is not theirs
        $content =~ s/set output.*$//gsmi ;
        # set out filename
        $content = "set output '$filename'\n$content" ;
            # we want to set the size
            # strip any size in the data
            $content =~ s/set term png size.*$//gsmi ;
            $content = "set term png size $x, $y\n$content" ;

        path($gnuplotfile)->spew_utf8($content);

        my $cmd = GNUPLOT . " $gnuplotfile";
        my ( $exit, $stdout, $stderr ) = run_cmd($cmd);
        if( $exit) {
            warn "Could not run script " . GNUPLOT . " get it from http://gnuplot.sourceforge.net/" ;
        }
        # if we want to force the size of the graph
        # if ( -f $filename && $x && $y ) {
        #     my $image = Image::Resize->new($filename);
        #     my $gd = $image->resize( $x, $y );

        #     # overwrite original file with resized version
        #     if ($gd) {
        #         path($filename)->spew_raw( $gd->png );
        #     }
        # }
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
