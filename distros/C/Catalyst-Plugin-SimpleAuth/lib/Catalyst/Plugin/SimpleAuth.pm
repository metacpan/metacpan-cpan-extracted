package Catalyst::Plugin::SimpleAuth;
use strict;
use warnings;
use Digest::SHA1 qw(sha1_hex);
use base qw/Class::Accessor::Fast/;
our $VERSION = '0.33';
use NEXT;
use Catalyst::Exception;

BEGIN {
    __PACKAGE__->mk_accessors(qw(_simpleauth_model));
}

sub setup {
    my $c = shift;
    $c->_throw_error(
        'SimpleAuth: this module requires the Session or CookiedSession plugin'
        )
        unless $c->isa('Catalyst::Plugin::Session')
            || $c->isa('Catalyst::Plugin::CookiedSession');
}

sub _throw_error {
    my ( $c, $error ) = @_;
    $c->log->fatal($error);
    Catalyst::Exception->throw($error);
}

sub prepare_action {
    my $c             = shift;
    my $configuration = $c->config->{simpleauth} || {};
    my $class         = $configuration->{class};
    $c->_throw_error('SimpleAuth: requires a class in the configuration')
        unless $class;
    my $model = $c->model($class);
    $c->_throw_error("SimpleAuth: unable to load model $class")
        unless defined $model;
    $c->_simpleauth_model($model);

    my $simpleauth_id = $c->session->{_simpleauth_id};
    if ($simpleauth_id) {
        my $user = $model->find($simpleauth_id);
        if ($user) {
            $c->log->debug(
                "SimpleAuth: found user_id $simpleauth_id in session and user"
            ) if $c->debug;
            $c->stash->{user} = $user;
        } else {
            $c->log->debug(
                "SimpleAuth: found user_id $simpleauth_id in session, but no user"
            ) if $c->debug;
        }
    } else {
        $c->log->debug("SimpleAuth: did not find user_id in session")
            if $c->debug;
    }

    $c->NEXT::prepare_action(@_);
}

sub sign_up {
    my ( $c, $conf ) = @_;
    my $model = $c->_simpleauth_model;
    $conf->{password} = sha1_hex( $conf->{password} );
    if ( $model->single( { username => $conf->{username} } ) ) {
        $c->log->debug("SimpleAuth sign_up: user already exists")
            if $c->debug;
        return 0;
    }
    my $user = $model->create($conf);
    if ($user) {
        $c->log->debug("SimpleAuth sign_up: signed up user") if $c->debug;
        $c->session->{_simpleauth_id} = $user->id;
        $c->stash->{user}             = $user;
        return 1;
    } else {
        $c->log->debug("SimpleAuth sign_up: did not sign up user")
            if $c->debug;
        return 0;
    }
}

sub sign_in {
    my ( $c, $conf ) = @_;
    my $model    = $c->_simpleauth_model;
    my $username = $conf->{username};
    my $password = sha1_hex( $conf->{password} );
    my $user
        = $model->single( { username => $username, password => $password } );
    if ($user) {
        $c->log->debug("SimpleAuth sign_in: signed in user") if $c->debug;
        $c->session->{_simpleauth_id} = $user->id;
        $c->stash->{user}             = $user;
        return 1;
    } else {
        $c->log->debug("SimpleAuth sign_in: did not sign in user")
            if $c->debug;
        return 0;
    }
}

sub sign_out {
    my $c = shift;
    delete $c->session->{_simpleauth_id};
    delete $c->stash->{user};
}

sub user {
    my $c = shift;
    return $c->stash->{user};
}

1;

__END__

=head1 NAME

Catalyst::Plugin::SimpleAuth - Simple authentication for Catalyst

=head1 SYNOPSIS

  # in your Catalyst application:
  use Catalyst qw(SimpleAuth);
  
  __PACKAGE__->config(
      simpleauth => { class => 'Users' },
  );
  
  # in your sign up code
  
  unless( $c->sign_up(
            {   username => $email,
                password => $password,
            }
        ) ) {
        # sign up failed, user exists
  }
  my $user = $c->user;
  ...

  # in your sign in code
  
  my $user = $c->user; 
  if ($c->sign_in(
          {   username => $email,
              password => $password,
          }
      )
      )
  {
      my $user = $c->user;
      ...
  } else {
      # sign in failed
  }

  # in your sign out code

  $c->sign_out;

  
=head1 DESCRIPTION

This module is a replacement module for Catalyst::Authentication::*
which does one thing and does it well. This module assumes that
you have a model for the users you wish to authenticate - this will
typically be a DBIx::Class module.

You set the name of the model to authenticate in the configuration
as above. 'sign_up' creates the instance for you. 'sign_in' signs
a person in, 'sign_out' signs a person out. You can access the user
object either as $c->user in the code or as the 'user' variable in
the stash.

This module saves SHA1 digests of the passwords instead of the password.

The model will generally have a database structure along the lines of:

  CREATE TABLE `users` (
    `username` text NOT NULL,
    `password` char(40) NOT NULL,
    `first_name` text,
    `last_name` text
  );

Note that the password will be 40 characters long.

This module requires either L<Catalyst::Plugin::Session> or
L<Catalyst::Plugin::CookiedSession>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2008-9, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
