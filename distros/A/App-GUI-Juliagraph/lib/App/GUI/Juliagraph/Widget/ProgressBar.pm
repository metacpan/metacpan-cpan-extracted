use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Widget::ProgressBar;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $x, $y, $color  ) = @_;
    return unless ref $color eq 'ARRAY' and @$color == 3;

    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y]);

    $self->{'x'}     = $x;
    $self->{'y'}     = $y;
    $self->{'color'} = $color;
    $self->{'percentage'} = [];

    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        my $dc = Wx::PaintDC->new( $cpanel );
        my $bg_color = Wx::Colour->new( 255, 255, 255 );
        my ($x, $y) = ( $self->GetSize->GetWidth, $self->GetSize->GetHeight );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();

        my $l_pos = 0;
        my $l_color = Wx::Colour->new( @{$self->{'color'}} );
        if (@{$self->{'percentage'}} > 1){
            my $i = 1;
            while (exists $self->{'percentage'}[$i]){
                my $r_pos = $x * ($self->{'percentage'}[$i] / 100);
                my $r_color = Wx::Colour->new( @{$self->{'percentage'}[$i-1]} );
                $dc->GradientFillLinear( Wx::Rect->new( $l_pos, 0, $r_pos, $y ), $l_color, $r_color );
                $i += 2;
                $l_pos = $r_pos;
                $l_color = $r_color;
            }
        }
    } );
    $self;
}

sub reset {
    my ( $self, $p, $color ) = @_;
    $self->{'percentage'} = [];
    $self->Refresh;
}

sub set_color {
    my ( $self, $color ) = @_;
    return unless ref $color eq 'HASH' and exists $color->{'red'} and exists $color->{'green'} and exists $color->{'blue'};
    $self->{'color'} = $color;
}

sub add_percentage {
    my ( $self, $p, $color ) = @_;
    return unless defined $p and $p <= 100 and $p >= 0 and $p != $self->{'percentage'};
    push @{$self->{'percentage'}}, $color, $p;
}

sub get_percentage { $_[0]->{'percentage'} }

sub full {
    my ( $self ) = @_;
    $self->Refresh;
}

1;
