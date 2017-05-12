package Acme::Monkey::Frame;

use Moose;

use Acme::Monkey::ClearScreen;
use Term::Screen;
use Term::ANSIColor qw(:constants);

extends 'Acme::Monkey::ClearScreen';

has 'width'   => (is=>'rw', isa=>'Int', required=>1);
has 'height'  => (is=>'rw', isa=>'Int', required=>1);

has 'layers' => (is=>'rw', isa=>'HashRef', default=>sub{ {} });

sub draw {
    my ($self) = @_;

    my @layers = map { $self->layers->{$_} } sort keys( %{ $self->layers() } );
    my $content = '';

    foreach my $y (1..$self->height()) {
        foreach my $x (1..$self->width()) {
            my $char;
            my $color;
            foreach my $layer (@layers) {
                $char = $layer->get(
                    $x - $layer->x() + 1,
                    $y - $layer->y() + 1,
                );
                if ($char) {
                    $color = $layer->color();
                    last;
                }
            }
            if ($char) {
                $content .= $color.$char.RESET;
            }
            else {
                $content .= ' ';
            }
        }
        $content .= "\n";
    }

    $self->clear_screen();
    print $content;
}

1;
