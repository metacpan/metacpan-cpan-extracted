package Catalyst::Helper::Controller::Scaffold::Mason;

use strict;
use Path::Class;

our $VERSION = '0.03';

=head1 NAME

Catalyst::Helper::Controller::Scaffold::Mason - Helper for Scaffolding

=head1 SYNOPSIS

    # Imagine you want to generate a scaffolding controller MyApp::C::SomeTable
    # for a CDBI table class MyApp::M::CDBI::SomeTable
    script/myapp_create.pl controller SomeTable Scaffold::Mason CDBI::SomeTable

=head1 DESCRIPTION

Helper for Scaffolding.

Templates are Mason so you'll need a Mason View Component and a forward in
your end action too, or the DefaultEnd plugin.

Note that you have to add these lines to your CDBI class...

    use Class::DBI::AsForm;
    use Class::DBI::FromForm;

for L<Catalyst::Model::CDBI> you can do that  by adding this

    additional_base_classes => [qw/Class::DBI::AsForm Class::DBI::FromForm/],   

to the component config. Also, change your application class like this:

    use Catalyst qw/-Debug FormValidator/;

=head1 METHODS

=over 4

=item mk_compclass

Does the actual work. Called from helper api.

=cut

sub mk_compclass {
    my ( $self, $helper, $table_class ) = @_;
    $helper->{table_class} = $helper->{app} . '::M::' . $table_class;
    my $file = $helper->{file};
    my $dir = dir( $helper->{base}, 'root', $helper->{prefix} );
    $helper->mk_dir($dir);
    $helper->render_file( 'compclass', $file );
    $helper->render_file( 'add',       file( $dir, 'add.mhtml' ) );
    $helper->render_file( 'edit',      file( $dir, 'edit.mhtml' ) );
    $helper->render_file( 'list',      file( $dir, 'list.mhtml' ) );
    $helper->render_file( 'view',      file( $dir, 'view.mhtml' ) );
}

=back

=head1 AUTHOR

Sebastian Riedel

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Base';

=head1 NAME

[% class %] - Scaffolding Controller Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Scaffolding Controller Component.

=head1 METHODS

=over 4

=item add

Sets a template.

=cut

sub add : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '[% prefix %]/add.mhtml';
}

=item default

Forwards to list.

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}

=item destroy

Destroys a row and forwards to list.

=cut

sub destroy : Local {
    my ( $self, $c, $id ) = @_;
    [% table_class %]->retrieve($id)->delete;
    $c->forward('list');
}

=item do_add

Adds a new row to the table and forwards to list.

=cut

sub do_add : Local {
    my ( $self, $c ) = @_;
    $c->form( optional => [ [% table_class %]->columns ] );
    if ($c->form->has_missing) {
        $c->stash->{message}='You have to fill in all fields. '.
        'The following are missing: <b>'.
        join(', ',$c->form->missing()).'</b>';
    } elsif ($c->form->has_invalid) {
        $c->stash->{message}='Some fields are correctly filled in. '.
        'The following are invalid: <b>'.
	join(', ',$c->form->invalid()).'</b>';
    } else {
	[% table_class %]->create_from_form( $c->form );
    	return $c->forward('list');
    }
    $c->forward('add');
}

=item do_edit

Edits a row and forwards to edit.

=cut

sub do_edit : Local {
    my ( $self, $c, $id ) = @_;
    $c->form( optional => [ [% table_class %]->columns ] );
    if ($c->form->has_missing) {
        $c->stash->{message}='You have to fill in all fields.'.
        'the following are missing: <b>'.
        join(', ',$c->form->missing()).'</b>';
    } elsif ($c->form->has_invalid) {
        $c->stash->{message}='Some fields are correctly filled in.'.
        'the following are invalid: <b>'.
	join(', ',$c->form->invalid()).'</b>';
    } else {
	[% table_class %]->retrieve($id)->update_from_form( $c->form );
	$c->stash->{message}='Updated OK';
    }
    $c->forward('edit');
}

=item edit

Sets a template.

=cut

sub edit : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{item} = [% table_class %]->retrieve($id);
    $c->stash->{template} = '[% prefix %]/edit.mhtml';
}

=item list

Sets a template.

=cut

sub list : Local {
    my ( $self, $c ) = @_;
    $c->stash->{template} = '[% prefix %]/list.mhtml';
}

=item view

Fetches a row and sets a template.

=cut

sub view : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{item} = [% table_class %]->retrieve($id);
    $c->stash->{template} = '[% prefix %]/view.mhtml';
}

=back

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__add__

<%args>
$message=>undef
</%args>
<p><%$message%></p>
<form action="<% $base . '[% uri %]/do_add' %>" method="post">
%foreach my $column ([%table_class%]->columns) {
%next if ($column eq [%table_class%]->primary_column);
        <% $column %><br/>
        <% [%table_class%]->to_field($column)->as_XML %><br/>
%}
    <input type="submit" value="Add"/>
<form/>
<br/>
<a href="<% $base . '[% uri %]/list' %>">List</a>
__edit__
<%args>
$message=>undef
$item
</%args>
<p><%$message%></p>
<form action="<% $base . '[% uri %]/do_edit/' . $item->id %>"
    method="post">
%for my $column ($item->columns) {
%next if ($column eq $item->primary_column);
        <% $column %><br/>
        <% $item->to_field($column)->as_XML %><br/>
%}
    <input type="submit" value="Edit"/>
<form/>
<br/>
<a href="<% $base . '[% uri %]/list' %>">List</a>
__list__
<table>
    <tr>
%for my $column ([%table_class%]->columns) {
%next if ($column eq [%table_class%]->primary_column);
        <th><% $column %></th>
%}
        <th/>
    </tr>
%for my $object ([%table_class%]->retrieve_all) {
        <tr>
% for my $column  ([%table_class%]->columns) {
%   next if ($column eq [%table_class%]->primary_column);
            <td><% $object->$column %></td>
%  }
            <td>
                <a href="<% $base . '[% uri %]/view/' . $object->id %>">
                    View
                </a>
                <a href="<% $base . '[% uri %]/edit/' . $object->id %>">
                    Edit

                </a>
                <a href="<% $base . '[% uri %]/destroy/' . $object->id %>">
                    Destroy
                </a>
            </td>
        </tr>
%}
</table>
<a href="<% $base . '[% uri %]/add' %>">Add</a>
__view__
<%args>
$item
</%args>
%for my $column ($item->columns) {
%  next if $column eq $item->primary_column;
    <b><% $column %></b><br/>
    <% $item->$column %><br/><br/>
%}
<a href="<% $base . '[% uri %]/list' %>">List</a>
