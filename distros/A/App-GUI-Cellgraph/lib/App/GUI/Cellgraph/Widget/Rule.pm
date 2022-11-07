use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Widget::Rule;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $cell_size, $pattern, $colors) = @_;
    return unless ref $pattern eq 'ARRAY' and ref $colors eq 'ARRAY' and @$colors;
    for (@$colors){ return unless ref $_ eq 'ARRAY' and @$_ == 3}
    my $cell_count = @$pattern;
    my $x = ($cell_size + 1) * $cell_count + 1;
    my $y = $cell_size + 2;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y]);
  
    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        my $dc = Wx::PaintDC->new( $cpanel );
        my $bg_color = Wx::Colour->new( 255, 255, 255 );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();
        $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 170, 170, 170 ), 1, &Wx::wxPENSTYLE_SOLID ) );
        $dc->DrawLine(  0,    0, $x-1,    0 );
        $dc->DrawLine(  0, $y-1, $x-1, $y-1 );
        $dc->DrawLine( $_,    0,   $_, $y-1 ) for map { ($cell_size + 1) * $_ }  0 .. $cell_count;
        my @color = map { Wx::Colour->new( @$_ ) } @$colors;
        for my $cell_nr (1 .. $cell_count) {
            my $color_i = $pattern->[$cell_nr - 1];
            my $color = $color_i == 0 ? $bg_color : $color[ $color_i - 1 ];
            $dc->SetPen( Wx::Pen->new( $color, 1, &Wx::wxPENSTYLE_SOLID ) );
            $dc->SetBrush( Wx::Brush->new( $color, &Wx::wxBRUSHSTYLE_SOLID ) );
            my $cell_x = 1 + (($cell_nr - 1) * ($cell_size + 1));
            $dc->DrawRectangle( $cell_x, 1, $cell_size, $cell_size );
        }
    } );
    $self;
}


1;
