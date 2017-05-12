package TestApp::View::Xslate::ExposeMethodsCoerced;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Xslate';

__PACKAGE__->config(
    expose_methods => [qw(abc def)],
);

sub abc {
    return 'abc';
}

sub def {
    my ($self, $c, $arg) = @_;
    return $self->zzz. " def $arg ". $c->stash->{exposed};
}

sub zzz {
    return 'zzz';
}

1;
