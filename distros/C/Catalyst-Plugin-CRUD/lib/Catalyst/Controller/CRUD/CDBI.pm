package Catalyst::Controller::CRUD::CDBI;

use strict;
use warnings;
use base qw(Catalyst::Controller::CRUD);

our $VERSION = '0.21';

=head1 NAME

Catalyst::Controller::CRUD::CDBI - Implementation for Catalyst::Controller::CRUD

=head1 SYNOPSIS

=head2 MyApp/lib/MyApp.pm

  package MyApp;
  
  use Catalyst qw/-Debug I18N CRUD Static::Simple/;
  
  1;
  
=head2 MyApp/lib/MyApp/Controller/User.pm

  package MyApp::Controller::User;
  
  use base 'Catalyst::Controller';
  use Class::Trigger;
  
  sub setting {
      my ( $self, $c ) = @_;
      my $hash = {
          'name'     => 'user',
          'type'     => 'CDBI',
          'model'    => 'CDBI::UserMaster',
          'primary'  => 'id',
          'columns'  => [qw(name phone mail)],
          'default'  => '/user/list',
          'template' => {
              'prefix' => 'template/user/',
              'suffix' => '.tt'
          },
      };
      return $hash;
  }
  
  sub create : Local {
    my ( $self, $c ) = @_;
    $c->create($self);
  }
  
  1;

=head1 DESCRIPTION

This module implements Class::DBI depend interfaces for Catalyst::Controller::CRUD.

 - get_model
 - get_models

=head2 EXPORT

None by default.

=head1 METHODS

=head2 get_model($this,$c,$self,$id)

This method returns model object having $id.

Triggers:

 $self->call_trigger( 'get_model_after', $c, $hash );

=cut

sub get_model {
    my ( $this, $c, $self, $id ) = @_;

    my $name    = $self->setting($c)->{name};
    my $primary = $self->setting($c)->{primary};
    my $model;
    if ($self->can('get_model')) {
        $model = $self->get_model($c, $id);
    } else {
        $model = $c->model( $self->setting($c)->{model} )->retrieve( $primary => $id );
    }

    if (defined $model) {
        my $hash    = $model->toHashRef;
        $self->call_trigger( 'get_model_after', $c, $hash );
        $c->stash->{ $name } = $hash;
    } else {
        $c->res->status(404);
        $c->res->body("404 Not Found\n");
    }

    return $model;
}

=head2 get_models($this,$c,$self)

This method returns model objects.

=cut

sub get_models {
    my ( $this, $c, $self ) = @_;

    my $name    = $self->setting($c)->{name};
    my $primary = $self->setting($c)->{primary};
    my $where   = $c->stash->{$name}->{where} ? $c->stash->{$name}->{where} : { disable => 0 };
    my $order   = $c->stash->{$name}->{order} ? $c->stash->{$name}->{order} : { order_by => $primary };

    my @models = $c->model( $self->setting($c)->{model} )->search_where( $where, $order );
    my @result;
    foreach (@models) {
        my $hash = $_->toHashRef;
        $self->call_trigger( 'get_model_after', $c, $hash );
        $c->stash->{ $name . '_' . $primary . 's' }->{ $hash->{$primary} } = $hash;
        push( @result, $hash );
    }
    return \@result;
}

=head1 SEE ALSO

Catalyst::Controller::CRUD, Class::DBI

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
