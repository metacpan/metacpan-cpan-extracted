package App::Controller::Root;

use Moose;

BEGIN {
    extends qw/ Catalyst::Controller /;
}

sub base : Chained('/') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{wk} = {
        template  => 'base.tt',
        page_size => 'a5',
        lowquality => 1,
    };

    $c->forward('View::Wkhtmltopdf');
}

1;
