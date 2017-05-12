package TestApp::Controller::Root;

use strict;
use warnings;

use Catalyst;
use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => q{});

sub begin :Private {
    my ( $self, $c ) = @_;
}

sub end :Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::TT');
}

sub index :Path {
    my ( $self, $c ) = @_;
}

sub request_one :Local {
    my ( $self, $c ) = @_;
    $c->view('TT')->jquery->construct_plugin(
        name => 'Superfish',
        target_selector => '#foobar',
    );
}

sub request_two :Local {
    my ( $self, $c ) = @_;
    $c->view('TT')->jquery->construct_plugin(
        name => 'mcDropdown',
        target_selector => '#foobar',
        source_ul => '#foobar',
    );
}

sub request_three :Local {
    my ( $self, $c ) = @_;
}

sub request_four :Local {
    my ( $self, $c ) = @_;
    $c->view('TT')->jquery->construct_plugin(
        name => 'mcDropdown',
        target_selector => '#foobar',
        source_ul => '#foobar',
    );
    $c->view('TT')->jquery->construct_plugin(
        name => 'Superfish',
        target_selector => '#foobar',
    );
    $c->view('TT')->jquery->construct_plugin(
        name => 'Superfish',
        target_selector => '#barfoo',
    );
    $c->view('TT')->jquery->construct_plugin(
        name => 'Superfish',
        target_selector => '#foobaz',
        options => 
'foo : 42,
bar : $("div#vega")',
    );
}



1;

