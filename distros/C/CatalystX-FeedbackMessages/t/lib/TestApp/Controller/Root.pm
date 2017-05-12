package TestApp::Controller::Root;
our $VERSION = '0.0603';
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

TestApp::Controller::Root - Root Controller for TestApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

sub has_message :Local {
    my ( $self, $c ) = @_;
    $c->msg("Test");
    $c->res->body(@{$c->stash->{messages}});
}

sub no_message :Local {
    my ( $self, $c ) = @_;
    $c->res->body("No messages");
}

sub many_messages : Local {
	my ( $self, $c ) = @_;
	$c->msg("One");
	$c->msg("Two");
	$c->msg("Three");
	$c->res->body(join ", ", @{$c->stash->{messages}}); 
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Devin Austin

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
