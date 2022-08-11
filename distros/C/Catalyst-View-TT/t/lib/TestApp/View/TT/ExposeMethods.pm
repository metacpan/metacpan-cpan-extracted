package TestApp::View::TT::ExposeMethods;

use Moose;
extends 'Catalyst::View::TT';

__PACKAGE__->config(
  expose_methods => [qw/exposed_method other_exposed_method/],
);

sub exposed_method {
    my ($self, $c, $some_param) = @_;

    unless ($some_param) {
        Catalyst::Exception->throw( "no param passed" );
    }
    return 'magic ' . $some_param;
}

sub other_exposed_method {
    my ($self, $c) = @_;
    die "ouch that was unexpected";
}

1;
