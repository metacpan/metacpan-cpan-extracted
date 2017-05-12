package Catalyst::Enzyme::CRUD::Controller;
use base 'Catalyst::Enzyme::Controller';

our $VERSION = 0.10;



use strict;
use Data::Dumper;
use Carp;



=head1 NAME

Catalyst::Enzyme::CRUD::Controller - CRUD Controller Base Class with
CRUD support

=head1 SYNOPSIS

See L<Catalyst::Enzyme>


=head1 PROPERTIES


=head2 model_class

The model class, overloaded by you in each controller class to return
the actual class name for the Model this controller should handle.

So in your Controller classes, something like this is recommended:

    sub model_class {
        return("BookShelf::Model::BookShelfDB::Genre");
    }

=cut
sub model_class {
    return("");
}



=head1 METHODS - ACTIONS

These are the default CRUD actions.

You should read the source so you know what the actions do, and how
you can adjust or block them in your own code.

They also deal with form validation, messages, and errors in a certain
way that you could use (or not, you may have a better way) in your own
Controller actions.


=head2 auto : Private

Set up the default model and class for this Controller

=cut
sub auto : Private {
    my ($self, $c) = @_;
    $c->forward("set_crud_controller");
}



=head2 set_crud_controller : Private

Set the current Controller and it's Model class (and the Model's
configuration using the model_class() ).

Point $self->crud_config to the Model's config->{crud}. Set
crud_config keys:

 model_class
 model
 moniker (default)
 rows_per_page (default 20)
 column_monikers (default)

Set stash keys:

 crud (to the crud_config)
 controller_namespace (to the Controller's namespace)
 uri_for_list (to a version that accepts array refs from TT)

Return 1.

=over 4

=item Usage

This action is automatically called by the C<auto> action.

This means that if the user invokes an action in a Controller, the
set_crud_controller is called properly and that Controller's Model class
is used. No need to do anything.

If you forward between actions in the same Controller, the same Model
class should be used, so no need to do anything.

But if you forward to an action in a different Controller, you need to
tell Enzyme to start using the new Model class first. So, going from
e.g. the Book Controller to a Genre action, you need to:

    $c->forward("/genre/set_crud_controller");
    $c->forward("/genre/add");


=back

=cut
sub set_crud_controller : Private {
    my ($self, $c) = @_;
    my $model_class_name = $self->model_class;

    
    #todo: move this to the model base class?
    
    my $crud_config = $self->crud_config;
    $crud_config->{model_class} = $model_class_name;
    
    $crud_config->{moniker} ||= $self->class_to_moniker($model_class_name);
    defined($crud_config->{rows_per_page}) or $crud_config->{rows_per_page} = 20;  #default
    $crud_config->{column_monikers} ||= { $model_class_name->default_column_monikers() };

    my $crud_model = $c->comp($model_class_name);
    ref($crud_model) or die("Object for model class ($model_class_name) not found\n");
    $crud_config->{model} = $crud_model;

    $c->stash->{crud} = $crud_config;
    $c->stash->{controller_namespace} = "/" . $self->action_namespace($c);
    $c->stash->{uri_for_list} = sub { $c->uri_for(map { ref $_ eq 'ARRAY' ? @$_ : $_ } @_); };
    
    return(1);
}



=head2 default

Forward to list.

=cut
sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}



=head2 list

Display list template

=cut

sub list : Local {
    my ( $self, $c ) = @_;
    my $model = $self->model_with_pager($c, $self->crud_config->{rows_per_page}, $c->req->param("page"));
    $c->stash->{items} = [ $model->retrieve_all() ];
    $c->stash->{template} = 'list.tt';
}



=head2 view

Select a row and display view template.

=cut
sub view : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{item} = $self->model_class->retrieve($id);
    $c->stash->{template} = 'view.tt';
}



=head2 add

Display add template

=cut
sub add : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'add.tt';
}



=head2 do_add

Add a new row and redirect to list.

=cut
sub do_add : Local {
    my ($self, $c) = @_;

    $c->form( %{ $self->crud_config->{data_form_validator} || $self->default_dfv($c)});
    $c->form->success or return( $c->forward('add') );

    my $item;
    $self->run_safe($c,
        sub  { $item = $self->model_class->create_from_form( $c->form ) },
        "add", "Could not create record",
    ) or return;

    $c->stash->{message} = "Record created OK";
    return( $c->res->redirect($c->uri_for('view', $item->id)) );
}



=head2 edit

Display edit template.

=cut
sub edit : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{item} = $self->model_class->retrieve($id);
    $c->stash->{template} = 'edit.tt';
}



=head2 do_edit

Edit a row and redirect to edit.

=cut
sub do_edit : Local {
    my ( $self, $c, $id ) = @_;
    
    $c->form( %{ $self->crud_config->{data_form_validator} || $self->default_dfv($c)});
    $c->form->success or return( $c->forward('edit') );

    $self->run_safe($c,
        sub  { $self->model_class->retrieve($id)->update_from_form( $c->form ) },
        "edit", "Could not update record",
    ) or return;


    $c->stash->{message} = "Record updated OK";
    return( $c->res->redirect($c->uri_for('view', $id)) );
}



=head2 delete

Display delete template.

=cut
sub delete : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{item} = $self->model_class->retrieve($id);
    $c->stash->{template} = 'delete.tt';
}



=head2 do_delete

Destroy row and forward to list.

=cut
sub do_delete : Local {
    my ( $self, $c, $id ) = @_;

    $self->run_safe($c,
        sub  { $self->model_class->retrieve($id)->delete },
        "list", "Could not delete record",
    ) or return;


    $c->stash->{message} = "Record deleted OK";
    return( $c->res->redirect($c->uri_for('list')) );
}



=head1 METHODS


=head2 default_dfv

Return hash ref with a default L<Data::FormValidator> config.

=cut
sub default_dfv {
    my ($self, $c) = @_;
    return({
        optional => [ $self->model_class->columns ],
        msgs => { format => '%s' },
        missing_optional_valid => 1,
    });
}



=head2 crud_config()

Return hash ref with config values form the Model class'
config->{crud} (so model_class needs to be set).

=cut
sub crud_config {
    my ($self) = @_;

    my $model_class = $self->model_class or confess("No model_class defined in (" . ref($self) . '). Make sure you define a model class in the "sub model_class" method' . "\n");

    $self->model_class->config->{crud} ||= {};  #Default to empty crud config
    my $crud_config = $self->model_class->config->{crud};
    
    return($crud_config);
}



=head2 model_with_pager($c, $rows_per_page, $page)

Return either the current model class, or (if $rows_per_page > 0) a
pager for the current model class. $page indicates which page to
display in the pager (default to the first page).

Assign the pager to $c->stash->{pager}.

The Model class (or it's base class) must C<use L<Class::DBI::Pager>>.

=cut
sub model_with_pager {
    my ($self, $c, $rows_per_page, $page) = @_;
    
    my $model = $self->model_class;
    $rows_per_page or return($model);
    
    $model->can("pager") or die("Class '$model' does not have a 'pager' property and still the ($model->config->{crud}->{rows_per_page} > 0. You need to add a 'use Class::DBI::Pager;' to ($model) or it's Model base class to enable paging or set the 'rows_per_page' to 0 to disable paging\n");
    $model = $model->pager($rows_per_page, $page);
    $c->stash->{pager} = $model;

    return($model);
}





=head2 template_with_item($template, $c, $id)

Retrieve object with $id and set the $template. Suitable to call like
this in an action (nothing else is needed):

    sub edit : Local {
       shift->template_with_item("edit.tt", @_);
    }

=cut
sub template_with_item : Private {
    my ( $self, $template, $c, $id ) = @_;
    $c->stash->{item} = $self->model_class->retrieve($id); #todo: error checking
    $c->stash->{template} = $template;
}





=head1 AUTHOR

Johan Lindstrom <johanl ÄT cpan.org>


=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
