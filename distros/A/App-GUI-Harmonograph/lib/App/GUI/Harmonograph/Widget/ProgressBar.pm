use v5.12;
use warnings;
use Wx;

package App::GUI::Harmonograph::Widget::ProgressBar;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $x, $y, $color  ) = @_;
    return unless ref $color eq 'ARRAY' and @{$color} == 3;

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
    my ( $self, $r, $g, $b ) = @_;
    return unless defined $b;
    $self->{'color'} = [$r, $g, $b];
}

sub add_percentage {
    my ( $self, $percent, $color ) = @_;
    return unless defined $percent and $percent <= 100 and $percent >= 0
        and $percent != $self->{'percentage'} and ref $color eq 'ARRAY' and @$color == 3;
    push @{$self->{'percentage'}}, $color, $percent; # say " $percent  $color->[0],$color->[1],$color->[2]";
    $self->Refresh;
}

sub get_percentage { $_[0]->{'percentage'} }

1;
