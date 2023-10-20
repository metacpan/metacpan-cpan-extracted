package MyApp03::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(namespace => '');

sub index : Path : Args(0) {
    my ($self, $c) = @_;
    
    $c->res->body('index');
}

sub exempt_path_name : Local : Args(0) {
    my ($self, $c) = @_;

    $c->res->body('exempt_path_namel response');
}

sub exempt_foo : Path('/all_exempt/foo') : Args(0) {
    my ($self, $c) = @_;

    $c->res->body('exempt_url response');
}
sub upload : Local : Args(0) {
    my ($self, $c) = @_;
    $c->res->body("Uploaded file content: " . $c->req->upload('myfile')->slurp);
}

1;

