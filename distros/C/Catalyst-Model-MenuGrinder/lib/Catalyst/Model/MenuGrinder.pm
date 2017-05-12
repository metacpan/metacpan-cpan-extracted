package Catalyst::Model::MenuGrinder;
BEGIN {
  $Catalyst::Model::MenuGrinder::VERSION = '0.07';
}

# ABSTRACT: Catalyst Model base class for WWW::MenuGrinder
# This looks a lot like Catalyst::Model::Factory::PerRequest, but it differs
# in that it constructs the MenuGrinder object once on startup, loading all of
# the plugins and such, and then delegates to the glue's "accept_context" on
# ACCEPT_CONTEXT. We could probably remove a layer here and switch to PerRequest
# but that's for later.

use Moose;
extends 'Catalyst::Model';

use Scope::Guard;
use Module::Runtime;

has '_menu' => (
  is => 'rw',
  builder => '_build__menu',
  lazy => 1,
);

has 'menu_class' => (
  is => 'ro',
  isa => 'Str',
  default => 'Catalyst::Model::MenuGrinder::Menu',
);

has 'menu_config' => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { +{} },
);

sub _build__menu {
  my ($self) = @_;

  return Module::Runtime::use_module($self->menu_class)->new(
    config => $self->menu_config,
  );
}

sub ACCEPT_CONTEXT {
  my ($self, $c) = @_;

  $c->stash->{__menu_guard} = [] unless defined $c->stash->{__menu_guard};
  push @{ $c->stash->{__menu_guard} }, Scope::Guard->new(sub {
      $self->_menu->cleanup();
    }
  );

  $self->_menu->_accept_context($c);

  return $self->_menu;
}

sub BUILD {
  my ($self) = @_;

  # Force loading at startup
  $self->_menu;
}

1;


__END__
=pod

=head1 NAME

Catalyst::Model::MenuGrinder - Catalyst Model base class for WWW::MenuGrinder

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  package MyApp::Model::Menu;

  use base 'Catalyst::Model::MenuGrinder';

  __PACKAGE__->config(
    menu_config => {
      plugins => [
        'XMLLoader',
        'DefaultTarget',
        'NullOutput',
      ],
      filename => MyApp->path_to('root', 'menu.xml'),
    },
  );

=head1 AUTHOR

Andrew Rodland <andrew@cleverdomain.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by HBS Labs, LLC..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

