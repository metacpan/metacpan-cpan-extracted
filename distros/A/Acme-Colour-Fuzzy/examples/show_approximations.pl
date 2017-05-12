#!/usr/bin/perl -w

use strict;
use lib qw(lib);
use Wx qw(wxSOLID);
use Wx::Event qw(EVT_PAINT);

use Acme::Colour::Fuzzy;

my( $r, $g, $b, $pack ) = @ARGV;
unless( defined( $r ) && defined( $g ) && defined( $b ) ) {
    print <<EOT;
Usage: $0 <r> <g> <b> [<package>]

e.g.: $0 255 128 128
      $0 255 128 128 Color::Similarity::RGB
EOT
    exit 0;
}

$pack ||= 'Color::Similarity::HCL';

eval "require $pack" or die $@;

my $fuzzy = Acme::Colour::Fuzzy->new( 'VACCC', $pack );
my $res = [ $fuzzy->colour_approximations( $r, $g, $b ) ];
my $name = $fuzzy->colour_name( $r, $g, $b );

( my $pp_pack = $pack ) =~ s/^Color::Similarity:://;
my $app = Wx::SimpleApp->new;
my $frame = Wx::Frame->new( undef, -1, "($r, $g, $b) $pp_pack",
                            [-1, -1], [300, 440] );
my $y = 0;
for my $row ( { distance => 0,
                name     => 'ORIGINAL: ' . $name,
                rgb      => [ $r, $g, $b],
                },
              @$res ) {
    my $panel = Wx::Panel->new( $frame, -1, [0, $y], [20, 20] );
    EVT_PAINT( $panel, sub {
                   my $dc = Wx::PaintDC->new( $panel );
                   my $colour = Wx::Colour->new( @{$row->{rgb}} );
                   $dc->SetBrush( Wx::Brush->new( $colour, wxSOLID ) );
                   $dc->DrawRectangle( 0, 0, 20, 20 );
               } );
    Wx::StaticText->new( $frame, -1, $row->{distance} . ' ' . $row->{name},
                         [30, $y + 5] );
    $y += 20;
}
$frame->Show;
$app->MainLoop;

exit 0;

=pod

package Graphics::ColorNames::My;

BEGIN { $INC{'Graphics/ColorNames/My.pm'} = __FILE__ }

use constant STEP => 15;

my %colors;

sub NamesRgbTable() {
    use integer;

    return \%colors if %colors;

    for( my $r = 0; $r < 256; $r += STEP ) {
        for( my $g = 0; $g < 256; $g += STEP ) {
            for( my $b = 0; $b < 256; $b += STEP ) {
                $colors{"($r, $g, $b)"} = ( $r << 16 ) + ( $g << 8 ) + $b;
            }
        }
    }

    return \%colors;
}

=cut
