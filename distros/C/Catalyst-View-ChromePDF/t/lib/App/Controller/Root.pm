package App::Controller::Root;

use Moose;

BEGIN {
    extends qw/ Catalyst::Controller /;
}

sub base : Chained('/') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{pdf} = {
        template  => 'base.tt',
        page_size => 'a5',
    };

    $c->forward('View::ChromePDF');
}

1;
