use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Widget::PositionMarker;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $x, $y, $nr, $state, $color  ) = @_;
    return unless ref $color eq 'HASH' and exists $color->{'red'} and exists $color->{'green'}and exists $color->{'blue'};

    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y]);
    $self->{'nr'} = $nr;

    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        return unless exists $self->{'blue'} and exists $self->{'red'} and exists $self->{'green'};
        my $dc = Wx::PaintDC->new( $cpanel );
        my $bg_color = Wx::Colour->new( $self->{'red'}, $self->{'green'}, $self->{'blue'} );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();
        my $black = Wx::Colour->new( 0, 0, 0 );

        if ($self->{'state'} eq 'active'){
            $dc->SetPen( Wx::Pen->new( $black, 4, &Wx::wxPENSTYLE_SOLID ) );
            $dc->DrawLine( 4,  4, int($x / 2), $y - 4);
            $dc->DrawLine( int($x / 2), $y - 4, $x - 4, 4);
        } elsif ($self->{'state'} eq 'passive'){
        } elsif ($self->{'state'} eq 'disabled'){
            $dc->SetPen( Wx::Pen->new( $black, 1, &Wx::wxPENSTYLE_SOLID ) );
            $dc->DrawLine( 0,  0, $x, $y);
            $dc->DrawLine( 0,  $y, $x, 0);
        }
    } );
    $self->set_state( $state );
    $self->set_color( $color );
    $self;
}

sub get_nr { $_[0]->{'nr'} }

sub get_state { $_[0]->{'state'} }
sub set_state {
    my ( $self, $state ) = @_;
    $self->{'state'} = $state;
    $self->Refresh;
}

sub get_color {
    my ( $self ) = @_;
    {
        red   => $self->{'red'},
        green => $self->{'green'},
        blue  => $self->{'blue'},
    }
}

sub set_color {
    my ( $self, $color ) = @_;
    return unless ref $color eq 'HASH' and exists $color->{'red'} and exists $color->{'green'} and exists $color->{'blue'};
    $self->{$_} = $color->{$_} for qw/red green blue/;
    $self->Refresh;
}


1;
