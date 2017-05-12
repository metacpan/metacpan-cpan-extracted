package TestApp::Controller::Root;
use Moose;
use HTTP::Exception;

BEGIN { extends 'Catalyst::Controller' }
with 'Catalyst::ControllerRole::CatchErrors';
__PACKAGE__->config( namespace => '' );

sub index : Path Args(0) {
    my ( $self, $c ) = @_;
    $c->res->body("index");
    $c->error('error');
}

sub rethrow : Local Args(0) {
    my ( $self, $c ) = @_;
    $c->error('rethrow_error_1');
    $c->error('rethrow_error_2');
}

sub http_exception : Local Args(0) {
    my ( $self, $c ) = @_;
    my $e = HTTP::Exception->new( 400, status_message => 'http_exception foobar' );
    $e->throw;
}

sub catch_errors : Private {
    my ( $self, $c, @errors ) = @_;
    for my $error (@errors) {
        if ( $error =~ qr/^rethrow_error_\d+$/xms ) {
            $c->error("Rethrowing '$error'");
        }
        elsif ( $error =~ qr/^error$/xms ) {
            $c->res->body("Error: '$error'");
        }
        else {
            die "Unknown error ($error)";
        }
    }
}

sub end : Private { }

no Moose;
1;
