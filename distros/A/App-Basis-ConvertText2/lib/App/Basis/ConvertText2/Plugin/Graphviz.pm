
=head1 NAME

App::Basis::ConvertText2::Plugin::Graphviz

=head1 SYNOPSIS

    my $content = "digraph G {
      subgraph cluster_0 {
        style=filled;
        color=lightgrey;
        node [style=filled,color=white];
        a0 -> a1 -> a2 -> a3;
        label = "process #1";
      }

      subgraph cluster_1 {
        node [style=filled];
        b0 -> b1 -> b2 -> b3;
        label = "process #2";
        color=blue
      }
      start -> a0;
      start -> b0;
      a1 -> b3;
      b2 -> a3;
      a3 -> a0;
      a3 -> end;
      b3 -> end;

      start [shape=Mdiamond];
      end [shape=Msquare];
    }" ;
    my $params = { 
        size   => "600x480",
    } ;
    my $obj = App::Basis::ConvertText2::Plugin::Graphviz->new() ;
    my $out = $obj->process( 'graphviz', $content, $params) ;

=head1 DESCRIPTION

convert a graphviz text string into a PNG, requires dot program from http://graphviz.org

=cut

# ----------------------------------------------------------------------------

package App::Basis::ConvertText2::Plugin::Graphviz;
$App::Basis::ConvertText2::Plugin::Graphviz::VERSION = '0.4';
use 5.10.0;
use strict;
use warnings;
use Moo;
use Path::Tiny;
use App::Basis;
use App::Basis::ConvertText2::Support;
use namespace::autoclean;

has handles => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [qw{graphviz dot}] }
);

# ----------------------------------------------------------------------------
use constant GRAPHVIZ => 'dot';
use constant DPI      => 72;

# ----------------------------------------------------------------------------

=item graphviz

create a simple graphviz structured graph image, from the passed text

 parameters
    data   - graphviz text      
    filename - filename to save the created image as 

 hashref params of
        size    - size of image, widthxheight - optional

=cut

sub process {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;
    my $size = "";
    $params->{size} ||= "";
    my ( $x, $y ) = ( $params->{size} =~ /^\s*(\d+)\s*x\s*(\d+)\s*$/ );

    # strip any ending linefeed
    chomp $content;
    return "" if ( !$content );

    # we can use the cache or process everything ourselves
    my $sig = create_sig( $content, $params );
    my $filename = cachefile( $cachedir, "$sig.png" );
    if ( !-f $filename ) {

        my $dotfile = Path::Tiny->tempfile("graphviz.XXXX");

        if ( $x && $y ) {
            $size = sprintf( "  size=\"%.5f,%.5f\";", $x / DPI, $y / DPI );

            # add calculated image size to the graph
            $content =~ s/(digraph.*?)$/$1\n$size\n/sm;
        }

        path($dotfile)->spew_utf8($content);
        my $cmd = GRAPHVIZ . " -Tpng -o$filename $dotfile";
        my ( $exit, $stdout, $stderr ) = run_cmd($cmd);
        if ($exit) {
            warn "Could not run script " . GRAPHVIZ . " get it from http://graphviz.org";
        }

        # if we want to force the size of the graph
        if ( -f $filename && $x && $y ) {
            my $image = Image::Resize->new($filename);
            my $gd = $image->resize( $x, $y );

            # overwrite original file with resized version
            if ($gd) {
                path($filename)->spew_raw( $gd->png );
            }
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
