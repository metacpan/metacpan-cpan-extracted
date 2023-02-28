use v5.12;
use warnings;
use Wx;

package App::GUI::Cellgraph::Widget::ProgressBar;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $x, $y, @color  ) = @_;
    return unless @color > 1;
    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y]);
    $self->set_colors( @color );
    return unless ref $self->{'color'};

    $self->{'x'}     = $x;
    $self->{'y'}     = $y;
    $self->{'percentage'} = 100;

    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        my $dc = Wx::PaintDC->new( $cpanel );
        my $bg_color = Wx::Colour->new( 255, 255, 255 );
        my ($x, $y) = ( $self->GetSize->GetWidth, $self->GetSize->GetHeight );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();

        my $l_pos = 0;
        my $l_color = Wx::Colour->new( @{$self->{'color'}[0]} );
        my $stripe_width = int( 1 / $#{$self->{'color'}} * $x);
        if ($self->{'percentage'}){
            for my $i (1 .. $#{$self->{'color'}}){
                my $r_pos = $l_pos + $stripe_width;
                my $r_color = Wx::Colour->new( @{$self->{'color'}[$i]} );
                $dc->GradientFillLinear( Wx::Rect->new( $l_pos, 0, $stripe_width, $y ), $l_color, $r_color, &Wx::wxRIGHT );
                $l_pos = $r_pos;
                $l_color = $r_color;
            }
        }
    } );
    $self;
}

sub set_colors {
    my ( $self, @color ) = @_;
    return unless @color > 1;
    for (@color) { return unless ref $_ eq 'Graphics::Toolkit::Color' }
    $self->{'color'} = [ map {[$_->rgb]} @color ];
}

sub reset {
    my ( $self ) = @_;
    $self->{'percentage'} = 0;
    $self->Refresh;
}


sub full {
    my ( $self ) = @_;
    $self->{'percentage'} = 100;
    $self->Refresh;
}

1;
