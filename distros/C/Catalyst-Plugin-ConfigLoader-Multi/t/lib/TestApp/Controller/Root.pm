package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

TestApp::Controller::Root - Root Controller for TestApp

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 default

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body( $c->welcome_message );
}

sub env_test : Local {
    my ( $s , $c )  = @_;


        $c->response->body($c->config->{ENV_TEST} );

}
sub test : Local {
    my ( $s , $c )  = @_;

    my $amano = 'noob';
    my $masap = 'hacker';
    my $tomyhero = 'hone';

    if (    $amano      eq $c->config->{amano} 
        &&  $masap      eq $c->config->{masap}
        &&  $tomyhero   eq $c->config->{tomyhero}  ) {
        $c->response->body('ok');
    }
    else {
        $c->response->body('ng');
    }
        
}
=head2 end

Attempt to render a view, if needed.

=cut 

#sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Tomohiro Teranishi

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
