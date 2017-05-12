#!/usr/bin/perl

package ACLTestApp::Controller::Auth;
use base qw/Catalyst::Controller/;

use strict;
use warnings;

sub login : Local {
	my ( $self, $c ) = @_;
	$c->res->body( $c->login ? "login successful" : "login failed" );
}

sub logout : Local {
	my ( $self, $c ) = @_;
	$c->logout;
	$c->res->body( "goodbye" );
}

sub check : Local {
	my ( $self, $c ) = @_;
	$c->res->body( $c->user ? "logged in" : "guest" );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

ACLTestApp::Controller::Auth - 

=head1 SYNOPSIS

	use ACLTestApp::Controller::Auth;

=head1 DESCRIPTION

=cut


