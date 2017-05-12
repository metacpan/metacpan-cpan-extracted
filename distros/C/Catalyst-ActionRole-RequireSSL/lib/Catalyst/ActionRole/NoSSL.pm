package  Catalyst::ActionRole::NoSSL;

use Moose::Role;
with 'Catalyst::ActionRole::RequireSSL::Role';
use namespace::autoclean;
our $VERSION = '0.07';

=head1 NAME

Catalyst::ActionRole::NoSSL - Force an action to be plain.

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  package MyApp::Controller::Foo;

  use parent qw/Catalyst::Controller::ActionRole/;

  sub bar : Local Does('RequireSSL') { ... }
  sub bar : Local Does('NoSSL') { ... }
   
=cut

around execute => sub {
  my $orig = shift;
  my $self = shift;
  my ($controller, $c) = @_;

  if($c->req->secure && $self->check_chain($c) &&
    ( $c->req->method ne "POST" || 
      $c->config->{require_ssl}->{ignore_on_post} )) {
    my $uri = $c->req->uri->clone;
    $uri->scheme('http');
    $c->res->redirect( $uri );
    $c->detach();
  } else {
    $self->$orig( @_ );
  }
};

1;

=head1 AUTHOR

Simon Elliott <cpan@papercreatures.com>

=head1 THANKS

Andy Grundman, <andy@hybridized.org> for the original RequireSSL Plugin

t0m (Tomas Doran), zamolxes (Bogdan Lucaciu)

=head1 COPYRIGHT & LICENSE

Copyright 2009 by Simon Elliott

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
