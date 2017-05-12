package MyApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Catalyst::Plugin::DebugCookie::Util qw/make_debug_cookie/;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

MyApp::Controller::Root - Root Controller for MyApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->body( "default page" );
}

sub secure_debug_cookie :Path(/this/is/not/public) { 
	my ($self, $c, $username) = @_; 

	make_debug_cookie($c, $username);

	$c->res->body("Cookie set"); 
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
