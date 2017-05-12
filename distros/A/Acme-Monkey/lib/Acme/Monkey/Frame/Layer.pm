package Acme::Monkey::Frame::Layer;

use Moose;

use Term::ANSIColor qw(:constants);

has 'x'       => (is=>'rw', isa=>'Int', default=>1);
has 'y'       => (is=>'rw', isa=>'Int', default=>1);

has 'width'   => (is=>'rw', isa=>'Int', required=>1);
has 'height'  => (is=>'rw', isa=>'Int', required=>1);

has 'hidden'    => (is=>'rw', isa=>'Int', default=>0);
has 'constrain' => (is=>'rw', isa=>'Int', default=>0);
has 'color'     => (is=>'rw', isa=>'Str', default=>WHITE);

has '_canvas' => (is=>'rw', isa=>'ArrayRef', default=>\&clear, lazy=>1);

sub clear {
    my ($self) = @_;

    my $canvas = [];

    foreach my $x (1..$self->width()) {
        foreach my $y (1..$self->height()) {
            $canvas->[$x]->[$y] = '';
        }
    }

    $self->_canvas( $canvas );

    return $canvas;
}

sub set {
    my ($self, $x, $y, $string) = @_;

    my $current_x = $x;
    my $current_y = $y;
    foreach my $char (split(//, $string)) {
        if ($char eq "\n") {
            $current_y ++;
            $current_x = $x;
        }
        else {
            $char = '' if ($char eq "\t");
            $self->_canvas->[$current_x]->[$current_y] = $char;
            $current_x ++;
        }
    }
}

sub get {
    my ($self, $x, $y) = @_;

    return '' if ($self->hidden());
    return '' if ($x<1 or $y<1 or $x>$self->width() or $y>$self->height());
    return $self->_canvas->[$x]->[$y] || '';
}

sub move_up {
    my ($self, $shift) = @_;

    $self->y( $self->y() - ($shift || 1) );
}

sub move_down {
    my ($self, $shift) = @_;

    $self->y( $self->y() + ($shift || 1) );
}

sub move_left {
    my ($self, $shift) = @_;

    $self->x( $self->x() - ($shift || 1) );
}

sub move_right {
    my ($self, $shift) = @_;

    $self->x( $self->x() + ($shift || 1) );
}

1;
