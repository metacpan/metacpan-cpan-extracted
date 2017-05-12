package MyApp::Controller::REST::Foo;
use Moose;
use namespace::autoclean;

# we might not have this module installed
BEGIN {
    eval {
        extends 'CatalystX::CRUD::Controller::REST';
        __PACKAGE__->config(
            model_name  => 'Foo',
            primary_key => 'id',
            page_size   => 50,
            default     => 'application/json',
        );
    };
    if ($@) {
        warn "CatalystX::CRUD::Controller::REST not available";
    }
}

1;
