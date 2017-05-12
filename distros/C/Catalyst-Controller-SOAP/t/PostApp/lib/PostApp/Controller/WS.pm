package PostApp::Controller::WS;

use strict;
use warnings;
use base 'Catalyst::Controller::SOAP';

sub hello : Local SOAP('DocumentLiteral') {
    my ( $self, $c, $body ) = @_;
    my $who = $body->textContent();
    $c->stash->{soap}->string_return('Hello '.$who.'!');
}

sub foo : Local SOAP('DocumentLiteral') {
    my ( $self, $c, $body ) = @_;
    my $who = $body->textContent();

    my $env = $c->stash->{soap}->parsed_envelope;
    my $foo = $env->createElement('foo');
    my $bar = $env->createElement('bar');
    $foo->appendChild($bar);
    my $baz = $env->createElement('baz');
    $bar->appendChild($baz);
    $baz->appendText('Hello '.$who.'!');

    $c->stash->{soap}->literal_return($foo);
}

sub bar : Local SOAP('DocumentLiteral') {
    die 'exception leaked by an action';
}

1;
