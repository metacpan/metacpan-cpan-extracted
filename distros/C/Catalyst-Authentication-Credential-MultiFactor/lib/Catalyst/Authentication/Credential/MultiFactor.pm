package Catalyst::Authentication::Credential::MultiFactor;

use strict;
use warnings;
use 5.01.102;

use Moose;

our $VERSION = '1.2';

has config => (is => 'ro', required => 1);
has factors => (is => 'ro', default => sub { [] });

sub BUILDARGS {
  my ($class, $config, $app, $realm) = @_;
  { config => $config, app => $app, realm => $realm };
}

sub BUILD {
  my ($self, $args) = @_;

  my ($app, $realm) = @{$args}{qw(app realm)};
  
  foreach my $factor (@{$self->config->{'factors'}}) {

    my $credential_class  = $factor->{'class'};

    if ($credential_class !~ /^\+(.*)$/ ) {
      $credential_class = "Catalyst::Authentication::Credential::${credential_class}";
    } else {
      $credential_class = $1;
    }
    
    Catalyst::Utils::ensure_class_loaded( $credential_class );

    $app->log->debug('LOADED class: '.$credential_class) if $app->debug;
    push @{$self->factors}, $credential_class->new($factor, $app, $realm);
  
  }
}

sub authenticate {
  my ($self, $c, $realm, $authinfo) = @_;
  
  my $user_obj;
  
  foreach my $factor (@{$self->factors}) {
    $c->log->debug('Trying to authenticate agains '.$factor) if $c->debug;
    return unless eval { $user_obj = $factor->authenticate($c, $realm, $authinfo) };
    $c->log->debug('Authentication successful against '.$factor) if $c->debug;
  }
  return $user_obj;
}

1;
__END__


=head1 NAME

Catalyst::Authentication::Credential::MultiFactor

=head VERSION

Version 1.2

=head1 DESCRIPTION

Provides multi-factor authentication to your Catalyst app
Uses the Catalyst::Plugin::Authentication system.

=head1 SYNOPSIS

  use Catalyst qw(
    ...
    Authentication
    ...
    );

  __PACKAGE__->config(
    name => 'myApp',

    ....

    'Plugin::Authentication' => {
      ...
      default => {
        credential => {
          class => 'MultiFactor',                                                                                                                                                                                                                                  
          factors  => [
            {
              class        => 'YubiKey',
              api_id       => 1337,
              api_key      => 'foo/BAr/baz818=',
            },
            {
              class         => 'Password',
              user_model    => 'DB::login',
              password_type => 'self_check',
            },
            .... add more plugins!
          ],
        },
      },
    },
  );

=head1 INSTALLATION

  To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

  This module requires these other modules and libraries:

  Moose
  namespace::autoclean

=head 1COPYRIGHT AND LICENCE

  Copyright (C) 2012 by Cédric Jeanneret

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.14.2 or,
  at your option, any later version of Perl 5 you may have available.

=cut
