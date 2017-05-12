package ACLTestApp::Controller::Root;

use strict;
use warnings;
no warnings 'uninitialized';
use base 'Catalyst::Controller';
__PACKAGE__->config->{namespace} = '';

sub restricted : Local {
	my ( $self, $c ) = @_;
	$c->res->body( "restricted" );
}

sub default : Private {
	my ( $self, $c ) = @_;
	$c->res->body( "welcome to the zoo!" );
	
}

sub access_denied : Private {
    my ( $self, $c ) = @_;
    $c->res->body($c->res->body . 'denied');
}

sub end : Private {
    my ( $self, $c ) = @_;
    if ($c->res->body !~ /denied/) {
        $c->res->body($c->res->body . 'allowed');
    }
}

__PACKAGE__;
