package TestApp::View::TT::ExposeMethods;

use Moose;
extends 'Catalyst::View::TT';

__PACKAGE__->config(
  expose_methods => [q/exposed_method/],
);

sub exposed_method {
    my ($self, $c, $some_param) = @_;

    unless ($some_param) {
        Catalyst::Exception->throw( "no param passed" );
    }
    return 'magic ' . $some_param;
}


1;
