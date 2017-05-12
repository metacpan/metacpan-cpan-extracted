
=head1 NAME

App::Basis::ConvertText2::Plugin::Sparkline

=head1 SYNOPSIS

    my $content = "1,2,3,4,5,6,7,8" ;
    my $params = {} ;
    my $obj = App::Basis::ConvertText2::Plugin::Sparkline->new() ;
    my $out = $obj->process( 'sparkline', $content, $params) ;

=head1 DESCRIPTION

Convert a text string of comma separated numbers into a sparkline image PNG

=cut

# ----------------------------------------------------------------------------

package App::Basis::ConvertText2::Plugin::Sparkline;
$App::Basis::ConvertText2::Plugin::Sparkline::VERSION = '0.4';
use 5.10.0;
use strict;
use warnings;
use GD::Sparkline;
use Path::Tiny;
use Capture::Tiny qw(capture);
use Moo;
use App::Basis::ConvertText2::Support;
use namespace::clean;

has handles => (
    is       => 'ro',
    init_arg => undef,
    default  => sub {[qw{sparkline}]}
);

# -----------------------------------------------------------------------------

my %_colour_schemes = (
    orange => { b => 'transparent', a => 'ffcc66', l => 'ff6000' },
    blue   => { b => 'transparent', a => 'ccffff', l => '3399cc' },
    red    => { b => 'transparent', a => 'ccaaaa', l => '990000' },
    green  => { b => 'transparent', a => '99ff99', l => '006600' },
    mono   => { b => 'ffffff',      a => 'ffffff', l => '000000' }
);

# -----------------------------------------------------------------------------

=item color_schemes

return a list of the color schemes available

=cut

sub color_schemes {
    my $self    = shift;
    my @schemes = sort keys %_colour_schemes;
    return @schemes;
}

# -----------------------------------------------------------------------------

=item process (sparkline)

create a simple sparkline image, with some nice defaults

 parameters
    text   - comma separated list of integers for the sparkline
    filename - filename to save the created sparkline image as 

    hashref params of
        bgcolor - background color in hex (123456) or transparent - optional
        line    - color or the line, in hex (abcdef) - optional
        color   - area under the line, in hex (abcdef) - optional
        scheme  - color scheme, only things in red blue green orange mono are valid - optional
        size    - size of image, default 80x20, widthxheight - optional

=cut

sub process {
    my $self = shift;
    my ( $tag, $content, $params, $cachedir ) = @_;
    my $scheme = $params->{scheme};
    my ( $b, $a, $l ) = ( $params->{bgcolor}, $params->{color}, $params->{line} );

    $params->{size} ||= "80x20";
    $params->{size} =~ /^\s*(\d+)\s*x\s*(\d+)\s*$/;
    my ( $w, $h ) = ( $1, $2 );

    if ( !$h ) {
        $w = 80;
        $h = 20;
    }

    die "Missing content" if ( !$content );
    die "Does not appear to be comma separated integers" if ( $content !~ /^[,\d ]+$/ );

    # we can use the cache or process everything ourselves
    my $sig = create_sig( $content, $params );
    my $filename = cachefile( $cachedir, "$sig.png" );
    if ( !-f $filename ) {
        $content =~ s/^\n*//gsm;    # remove any leading new lines
        if ( $content !~ /\n$/sm ) {    # make sure we have a trailing new line
            $content .= "\n";
        }

        if ($scheme) {
            $scheme = lc $scheme;
            if ( !$_colour_schemes{$scheme} ) {
                warn "Unknown color scheme $params->{scheme}";
                $scheme = ( sort keys %_colour_schemes )[0];
            }
            $b = $_colour_schemes{ $params->{scheme} }{b};    # background color
            $a = $_colour_schemes{ $params->{scheme} }{a};    # area under line color
            $l = $_colour_schemes{ $params->{scheme} }{l};    # top line color
        }
        else {
            $b ||= 'transparent';
            $a = 'cccccc';
            $l = '333333';
        }

        my $args = { b => $b, a => $a, l => $l, s => $content, w => $w, h => $h };
        my $spark = GD::Sparkline->new($args);
        if ($spark) {
            my $png = $spark->draw();
            if ($png) {
                path($filename)->spew_raw($png) ;
            }
        }
    }

    my $out;
    if (-f $filename) {

        # create something suitable for the HTML
        $out = create_img_src( $filename, $params->{title} );
    }

    return $out;
}

# ----------------------------------------------------------------------------

1;

__END__
