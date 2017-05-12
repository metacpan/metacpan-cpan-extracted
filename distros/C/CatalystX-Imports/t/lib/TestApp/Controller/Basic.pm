package TestApp::Controller::Basic;
use warnings;
use strict;

use base 'TestApp::Controller';

use CatalystX::Imports Vars => 1, Context => {
    Default => ':all',
    Config => [
        'config_test',
        { alias_test1 => 'config_test_alias1',
          alias_test2 => 'config_test_alias2' },
    ] };

our $PROTOTYPE_TEST;
BEGIN {
    no strict 'refs';
    $PROTOTYPE_TEST = prototype \&prototype_test;
}

__PACKAGE__->config(
    config_test => 'BAZ',
    alias_test1 => 23,
    alias_test2 => 17,
);

sub base: Chained CaptureArgs(0) PathPart('') { }

sub capt: Chained('base') CaptureArgs(3) PathPart('') { }

sub test_captures: Chained('capt') {
    my ($self, $c) = @_;
    $c->res->body(
        join( '; ',
            join( ', ', captures),
            join( ', ', scalar captures),
        ),
    );
}

sub test_action: Chained('base') {
    my ($self, $c) = @_;
    $c->res->body(
        join( '; ',
            action,
            action('base'),
            action('/basic/base'),
            ref(action('base')),
        ),
    );
}

sub test_uri_for: Chained('base') {
    my ($self, $c) = @_;
    $c->res->body(
        uri_for(action('test_captures'), [3..5], 'foo', {x => 7})
    );
}

sub test_model: Chained('base') {
    my ($self, $c) = @_;
    $c->res->body( model('TestModel')->foo );
}

sub test_model_withac: Chained('base') {
    my ($self, $c, @args) = @_;
    $c->res->body( model('TestAC', @args)->join );
}

sub test_response: Chained('base') {
    my ($self, $c) = @_;
    $c->res->body( response->isa('Catalyst::Response') ? 1 :0 );
}

sub test_request: Chained('base') {
    my ($self, $c) = @_;
    $c->res->body( request->isa('Catalyst::Request') ? 1 : 0 );
}

sub test_has_param: Chained('base') {
    my ($self, $c) = @_;
    $c->res->body( has_param('foo') ? 1 : 0 );
}

sub test_param: Chained('base') {
    my ($self, $c) = @_;
    $c->res->body( param('foo') );
}

sub test_path_to: Chained('base') {
    my ($self, $c) = @_;
    $c->res->body( path_to(qw(root foo bar)) );
}

sub test_stash: Chained('base') {
    stash(foo => param('foo'));
    response->body( stash->{foo} );
}

sub test_config: Chained('base') {
    response->body( config_test );
}

sub test_config_alias: Chained('base') {
    response->body( config_test_alias1 + config_test_alias2 );
}

sub test_args_midpoint: Chained('base') PathPart('') CaptureArgs(2) {
    response->body( join ', ', @{ arguments() } );
}
sub test_args: Chained('test_args_midpoint') {
    my ($self, $c) = @_;
    response->body( join '; ', response->body, join(', ', @{ arguments() }) );
    $c->forward('test_args_forward', [qw(x y z)]);
}
sub test_args_forward: Private {
    response->body( join '; ', response->body, join(', ', @{ arguments() }) );
}

sub test_passed_args: Chained('base') {
    my ($self, $c) = @_;
    $c->forward('test_passed_args_rcvr', arguments);
}
sub test_passed_args_rcvr: Private {
    response->body( join ', ', @{ arguments() } );
}

1;
