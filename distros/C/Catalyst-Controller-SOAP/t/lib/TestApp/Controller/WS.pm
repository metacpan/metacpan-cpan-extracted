package TestApp::Controller::WS;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

sub hello :Local SOAP('DocumentLiteral') {
    my ($self, $c, $body) = @_;
    my $world = $body->textContent;
    $c->stash->{soap}->string_return('Hello '.$world.'!');
}

sub foo :Local SOAP('HTTPGet') {
    my ($self, $c) = @_;
    my $world = $c->req->param('who');
    $c->stash->{soap}->string_return('Hello '.$world.'!');
}

1;
