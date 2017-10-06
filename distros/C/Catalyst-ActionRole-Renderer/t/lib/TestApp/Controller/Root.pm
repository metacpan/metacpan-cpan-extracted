package TestApp::Controller::Root;

use Moose;
#use Catalyst::View::TT;

BEGIN { extends 'Catalyst::Controller' };

__PACKAGE__->config->{namespace} = '';

sub render_tt :Local :Does("Renderer") :View(TT) {
#sub render_tt :Local {
  my ( $self, $c ) = @_;
  $c->stash->{template} = 'hello.tt';
  #$c->forward('View::TT');
  #$c->response->body('Unsecured')
}

#sub root_plain :Local Does("NoSSL") {
#  my ( $self, $c ) = @_;
#  $c->response->body('Unsecured')
#}
#
#
#sub base : Chained('/') PathPart('') CaptureArgs(0) {
#  my ( $self, $c ) = @_;
#  $c->response->body('Unsecured')
#}
#
#sub ssl : Chained('base') CaptureArgs(0) Does("RequireSSL") {
#  my ( $self, $c ) = @_;
#}
#
#sub plain : Chained('base') CaptureArgs(0) Does("NoSSL") {
#  my ( $self, $c ) = @_;
#}
#
#sub plain_chained : Chained('ssl') CaptureArgs(0) Does("NoSSL") {
#  my ( $self, $c ) = @_;
#}
#
#sub ssl_to_plain : Chained('ssl') PathPart('plain') Args(0) Does("NoSSL") {
#  my ( $self, $c ) = @_;
#  $c->response->body('Unsecured')
#}
#
#sub ssl_to_ssl : Chained('ssl') PathPart('ssl') Args(0) {
#  my ( $self, $c ) = @_;
#  $c->response->body('Secured')
#}
#
#sub plain_to_ssl : Chained('plain') PathPart('ssl') Args(0) Does("RequireSSL") {
#  my ( $self, $c ) = @_;
#  $c->response->body('Secured')
#}
#
#sub plain_to_plain : Chained('plain') PathPart('plain') Args(0) {
#  my ( $self, $c ) = @_;
#  $c->response->body('Unsecured')
#}
#
#sub ssl_chained2 : Chained('plain_chained') PathPart('ssl') Args(0) Does("RequireSSL") {
#  my ( $self, $c ) = @_;
#  $c->response->body('Secured')
#}
#
#sub plain_chained2 : Chained('plain_chained') PathPart('plain') Args(0) Does("NoSSL") {
#  my ( $self, $c ) = @_;
#  $c->response->body('Unsecured')
#}
#
#sub end : ActionClass('RenderView') {}
#
#=head1 AUTHOR
#
#Simon Elliott
#
#=head1 LICENSE
#
#This library is free software. You can redistribute it and/or modify
#it under the same terms as Perl itself.
#
#=cut

#sub end : Private {
#    my ($self, $c) = @_; 
#
#    my $view = 'View::TT';
#    $c->forward($view);
#}


1;
