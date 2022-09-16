use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::ProgressBar;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $x, $y, $color  ) = @_;
    return unless ref $color eq 'HASH' and exists $color->{'red'} and exists $color->{'green'}and exists $color->{'blue'};

    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y]);
    
    $self->{'x'}     = $x;
    $self->{'y'}     = $y;
    $self->{'color'} = $color;
    $self->{'percentage'} = 0;
 
    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        my $dc = Wx::PaintDC->new( $cpanel );
        my $fg_color = Wx::Colour->new( $self->{'color'}{'red'}, $self->{'color'}{'green'}, $self->{'color'}{'blue'} );
        my $bg_color = Wx::Colour->new( 255, 255, 255 );
        my ($x, $y) = ( $self->GetSize()->GetWidth, $self->GetSize()->GetHeight );
        my $pos = $x * ($self->{'percentage'} / 100);
        my $min_pos = $x * ($self->{'percentage'} - 10) / 100 ;
        $min_pos = 0 if $min_pos < 0;
        $min_pos = $x if $self->{'percentage'} == 100;
        
        $dc->SetPen( Wx::Pen->new( $fg_color, 1, &Wx::wxPENSTYLE_SOLID) );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();

        $dc->GradientFillLinear( Wx::Rect->new($min_pos, 0, $pos - $min_pos, $y ), $fg_color, $bg_color, &Wx::wxRIGHT );
        $dc->GradientFillLinear( Wx::Rect->new(0, 0, $min_pos, $y ), $fg_color, $fg_color );
    } );
    $self;
}

sub set_color {
    my ( $self, $color ) = @_;
    return unless ref $color eq 'HASH' and exists $color->{'red'} and exists $color->{'green'} and exists $color->{'blue'};
    $self->{'color'} = $color;
}

sub set_percentage {
    my ( $self, $p ) = @_;
    return unless defined $p and $p <= 100 and $p >= 0 and $p != $self->{'percentage'};
    $self->{'percentage'} = $p;
    $self->Refresh;
}

sub get_percentage { $_[0]->{'percentage'} }

1;
