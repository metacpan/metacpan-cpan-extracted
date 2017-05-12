package Catalyst::ActionRole::RequireSSL;
{
  $Catalyst::ActionRole::RequireSSL::VERSION = '0.07';
}

use Moose::Role;
with 'Catalyst::ActionRole::RequireSSL::Role';
use namespace::autoclean;

=head1 NAME

Catalyst::ActionRole::RequireSSL - Force an action to be secure only.

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  package MyApp::Controller::Foo;

  use parent qw/Catalyst::Controller::ActionRole/;

  sub bar : Local Does('RequireSSL') { ... }
  sub bar : Local Does('NoSSL') { ... }
  
=head2 HIERARCHY

You can chain the SSL Roles to allow for enforced combinations such as all
secure apart from a certain action and vice versa. See the tests to see this
in action.
   
=cut

around execute => sub {
  my $orig = shift;
  my $self = shift;
  my ($controller, $c) = @_;
  
  unless(defined $c->config->{require_ssl}->{disabled}) {
    $c->config->{require_ssl}->{disabled} = 
      $c->engine->isa("Catalyst::Engine::HTTP") ? 1 : 0;
  }
  #use Data::Dumper;warn Dumper($c->action);
  if (!$c->req->secure && $c->req->method eq "POST"
      && !$c->config->{require_ssl}->{ignore_on_post})
  {
    $c->error("Cannot secure request on POST") 
  }

  unless(
    $c->config->{require_ssl}->{disabled} ||
    $c->req->secure ||
    $c->req->method eq "POST" ||
    !$self->check_chain($c)
    ) {
    my $uri = $c->req->uri->clone;
    $uri->scheme('https');
    $c->res->redirect( $uri );
    $c->detach();
  } else {
    $c->log->warn("Would've redirected to SSL") 
      if $c->config->{require_ssl}->{disabled} && $c->debug;
    $self->$orig( @_ );
  }
};

1;

=head1 AUTHOR

Simon Elliott <cpan@papercreatures.com>

=head1 THANKS

Andy Grundman, <andy@hybridized.org> for the original RequireSSL Plugin

t0m (Tomas Doran), zamolxes (Bogdan Lucaciu), wreis (Wallace Reis)

=head1 COPYRIGHT & LICENSE

Copyright 2009 by Simon Elliott

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
