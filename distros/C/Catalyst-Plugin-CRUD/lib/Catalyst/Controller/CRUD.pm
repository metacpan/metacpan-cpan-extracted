package Catalyst::Controller::CRUD;

use strict;
use warnings;

our $VERSION = '0.21';

=head1 NAME

Catalyst::Controller::CRUD - CRUD (create/read/update/delete) Controller for Catalyst

=head1 SYNOPSIS

  package MyApp::Controller::Foo;
  
  use base qw(Catalyst::Controller);
  use Catalyst::Controller::CRUD::CDBI;
  
  sub create : Local {
    my ($self, $c) = @_;
    Catalyst::Controller::CRUD::CDBI->create($c, $self);
  }
  
  1;

=head1 DESCRIPTION

This module provides CRUD (create/read/update/delete) action.

 create: insert new record
 read:   retrieve record
 update: update already record
 delete: delete record
 list:   retrieve all records

=head2 EXPORT

None by default.

=head1 METHODS

=head2 create

Create action.

If there is $c->stash->{create}->{error}, then it does not insert new recoed.

Triggers:

 $self->call_trigger( 'create_check', $c, $hash );
 $self->call_trigger( 'create_after', $c, $model );

=cut

sub create {
    my ( $this, $c, $self ) = @_;

    # insert new record
    if ( $c->req->param('btn_create') ) {
        # create hash from request parameters
        my $hash;
        foreach (@{ $self->setting($c)->{columns} }) {
            my $param = $c->req->param($_);
            $hash->{$_} = $param if ( defined $param );
        }

        # create check
        $self->call_trigger( 'create_check', $c, $hash );

        # insert new record
        if ( !$c->stash->{create}->{error} and scalar( keys %{$hash} ) ) {
            my $model = $c->model( $self->setting($c)->{model} )->create($hash);
            $self->call_trigger( 'create_after', $c, $model );
            $c->res->redirect( $self->setting($c)->{default} );
        }

        # prepare create form
        else {
            $c->stash->{$self->setting($c)->{name}} = $hash;
        }
    }

    # copy record ex) /xxx/create/yyy
    elsif ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        $this->get_model( $c, $self, $c->req->args->[0] );
        undef $c->stash->{$self->setting($c)->{name}}->{$self->setting($c)->{primary}};
    }

    # template setting
    my $prefix = $self->setting($c)->{template}->{prefix};
    my $suffix = $self->setting($c)->{template}->{suffix} ? $self->setting($c)->{template}->{suffix} : '.tt';
    $c->stash->{template} = $prefix . 'create' . $suffix;
}

=head2 read

Read action.

=cut

sub read {
    my ( $this, $c, $self ) = @_;

    # get model
    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        $this->get_model( $c, $self, $c->req->args->[0] );
    }

    # template setting
    my $prefix = $self->setting($c)->{template}->{prefix};
    my $suffix = $self->setting($c)->{template}->{suffix} ? $self->setting($c)->{template}->{suffix} : '.tt';
    $c->stash->{template} = $prefix . 'read' . $suffix;
}

=head2 update

Update action.

If there is $c->stash->{update}->{error}, then it does not update already recoed.

Triggers:

 $self->call_trigger( 'update_check', $c, $hash );
 $self->call_trigger( 'update_after', $c, $model );

=cut

sub update {
    my ( $this, $c, $self ) = @_;

    # update already record
    if ( $c->req->param('btn_update') ) {
        my $model = $this->get_model( $c, $self, $c->req->param( $self->setting($c)->{primary} ) );
        if (defined $model) {
            # create hash from request parameters
            my $primary = $self->setting($c)->{primary};
            my $hash = {$primary => $model->$primary};
            foreach (@{ $self->setting($c)->{columns} }) {
                my $value = $c->req->param($_);
                if (defined $value) {
                    $hash->{$_} = $value;
                }
            }

            # update check
            $self->call_trigger( 'update_check', $c, $hash );

            # update already record
            if ( !$c->stash->{update}->{error} and scalar( keys %{$hash} ) ) {
                foreach (@{ $self->setting($c)->{columns} }) {
                    my $value = $c->req->param($_);
                    if (defined $value) {
                        $model->$_( $value );
                    }
                }
                $model->update();
                $self->call_trigger( 'update_after', $c, $model );
                $c->res->redirect( $self->setting($c)->{default} );
            }

            # prepare update form
            else {
                undef $c->stash->{$self->setting($c)->{name}};
                $c->stash->{$self->setting($c)->{name}} = $hash;
            }
        }
    }

    # prepare update form
    elsif ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        $this->get_model( $c, $self, $c->req->args->[0] );
    }

    # update error
    else {
        $c->res->status(404);
        $c->res->body("404 Not Found\n");
    }

    # template setting
    my $prefix = $self->setting($c)->{template}->{prefix};
    my $suffix = $self->setting($c)->{template}->{suffix} ? $self->setting($c)->{template}->{suffix} : '.tt';
    $c->stash->{template} = $prefix . 'update' . $suffix;
}

=head2 delete

Delete action.

If there is $c->stash->{delete}->{error}, then it does not delete recoed.

Triggers:

 $self->call_trigger( 'delete_check', $c, $model );
 $self->call_trigger( 'delete_after', $c, $model );

=cut

sub delete {
    my ( $this, $c, $self ) = @_;

    # delete record
    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $this->get_model( $c, $self, $c->req->args->[0] );
        if ( defined $model ) {
            $self->call_trigger( 'delete_check', $c, $model );
            if ( !$c->stash->{delete}->{error} ) {
                if ($model->can('disable')) {
                    $model->disable(1);
                    $model->update();
                } else {
                    $model->delete();
                }
                $self->call_trigger( 'delete_after', $c, $model );
            }
        }
        $c->res->redirect( $self->setting($c)->{default} );
    }
 
    # delete error
    else {
        $c->res->status(404);
        $c->res->body("404 Not Found\n");
    }
}

=head2 list

List action.

=cut

sub list {
    my ( $this, $c, $self ) = @_;

    # get models
    $c->stash->{ $self->setting($c)->{name} . 's' } = $this->get_models( $c, $self );

    # template setting
    my $prefix = $self->setting($c)->{template}->{prefix};
    my $suffix = $self->setting($c)->{template}->{suffix} ? $self->setting($c)->{template}->{suffix} : '.tt';
    $c->stash->{template} = $prefix . 'list' . $suffix;
}

=head1 INTERFACE METHODS

=head2 get_model($this,$c,$self,$id)

This method returns model object having $id.
This method must be implemented by sub class.

=cut

sub get_model {
    die 'this method must be overriden in the subclass.';
}

=head2 get_models($this,$c,$self)

This method returns model objects.
This method must be implemented by sub class.

=cut

sub get_models {
    die 'this method must be overriden in the subclass.';
}

=head1 SEE ALSO

Catalyst, Catalyst::Plugin::CRUD

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2007 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
