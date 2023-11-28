use v5.12;
use warnings;
use Wx;

package App::GUI::Juliagraph::Widget::ColorDisplay;
use base qw/Wx::Panel/;

sub new {
    my ( $class, $parent, $x, $y, $nr, $init  ) = @_;
    return unless ref $init eq 'HASH' and exists $init->{'red'} and exists $init->{'green'}and exists $init->{'blue'};

    my $self = $class->SUPER::new( $parent, -1, [-1,-1], [$x, $y]);

    Wx::Event::EVT_PAINT( $self, sub {
        my( $cpanel, $event ) = @_;
        return unless exists $self->{'blue'} and exists $self->{'red'} and exists $self->{'green'};
        my $dc = Wx::PaintDC->new( $cpanel );
        my $bg_color = Wx::Colour->new( $self->{'red'}, $self->{'green'}, $self->{'blue'} );
        $dc->SetBackground( Wx::Brush->new( $bg_color, &Wx::wxBRUSHSTYLE_SOLID ) );
        $dc->Clear();
    } );
    $self->{'init'} = $init;
    $self->{'nr'} = $nr;
    $self->set_color( $init );
    $self;
}

sub init {
    my ($self) = @_;
    $self->set_color( $self->{'init'} );
}

sub get_nr { $_[0]->{'nr'} }

sub set_color {
    my ( $self, $color ) = @_;
    return unless ref $color eq 'HASH' and exists $color->{'red'} and exists $color->{'green'} and exists $color->{'blue'};
    $self->{$_} = $color->{$_} for qw/red green blue/;
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


1;
