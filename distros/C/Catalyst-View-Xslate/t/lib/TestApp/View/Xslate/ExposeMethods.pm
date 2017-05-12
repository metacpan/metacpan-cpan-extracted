package TestApp::View::Xslate::ExposeMethods;

use Moose;
use namespace::autoclean;

extends 'Catalyst::View::Xslate';

__PACKAGE__->config(
    expose_methods => {
      abc => 'abc_method',
      def => 'def_method',
   },
);

sub abc_method {
    return 'abc';
}

sub def_method {
    my ($self, $c, $arg) = @_;
    return $self->zzz. " def $arg ". $c->stash->{exposed};
}

sub zzz {
    return 'zzz';
}

1;
