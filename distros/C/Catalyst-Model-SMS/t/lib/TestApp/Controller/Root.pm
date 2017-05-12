package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => q{} );

sub base : Chained('/') PathPart('') CaptureArgs(0) { }

# your actions replace this one
sub main : Chained('base') PathPart('') Args(0) {
    my ( $self, $ctx ) = @_;
    $ctx->res->body('<h1>It works</h1>');
}

sub sms : Local {
    my ( $self, $c ) = @_;

    my $sender = $c->model('SMS');
    my $sent   = $sender->send_sms(
        text => 'This is a test message',
        to   => '+447931039257',
    );

    my $body;
    if ($sent) {
        $body = 'Message sent';
    }
    else {
        $body = 'Message not sent';
    }
    $c->res->body($body);
}

__PACKAGE__->meta->make_immutable;

1;
