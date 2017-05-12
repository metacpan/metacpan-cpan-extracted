package TestApp::Controller::Me;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }

__PACKAGE__->config(namespace => q{});

sub init : Chained('/') PathPart('my') Does('ProtectedResource') CaptureArgs(0) {
    my ( $self, $ctx )    = @_;
}

sub my_test: Chained('init') PathPart('test') Args(0) {
    my ( $self, $ctx ) = @_;
    if (! $ctx->stash->{error} ) {
        my %test_data = ( 'first_name'    =>  'warachet',
                          'last_name'     =>  'samtalee',
                          'email'         =>  'zdk@abctech-thailand.com'); #testing
        $ctx->stash->{info}  = \%test_data;
    }
    $ctx->forward( $ctx->view('JSON') );
}

__PACKAGE__->meta->make_immutable;

1;