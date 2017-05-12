#!/usr/bin/perl

package ACLTestApp::Controller::LionCage;
use base qw/Catalyst::Controller/;

use strict;
use warnings;

sub default : Private {
	my ( $self, $c ) = @_;
	$c->res->body( "no-one is allowed in here" );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

ACLTestApp::Controller::LionCage - 

=head1 SYNOPSIS

	use ACLTestApp::Controller::LionCage;

=head1 DESCRIPTION

=cut


