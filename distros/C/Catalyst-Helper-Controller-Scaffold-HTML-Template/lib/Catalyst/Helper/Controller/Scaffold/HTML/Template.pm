package Catalyst::Helper::Controller::Scaffold::HTML::Template;

use strict;
use Path::Class;

our $VERSION = '0.04';

=head1 NAME

Catalyst::Helper::Controller::Scaffold::HTML::Template - Helper for Scaffolding using HTML::Template.

=head1 SYNOPSIS

    # Imagine you want to generate a scaffolding controller MyApp::C::SomeTable
    # for a CDBI table class MyApp::M::CDBI::SomeTable
    script/myapp_create.pl controller SomeTable Scaffold::HTML::Template CDBI::SomeTable

=head1 DESCRIPTION

This module is heavily based on Catalyst::Helper::Controller::Scaffold.
It provides a framework to do the basic data operations (edit, view, list, 
delete, add).

Scaffolding is very simple with Catalyst, as most of the code will be automagically
generated to handle the basic operations.

Let's say you want to handle the data in SomeTable, all you have to do is :

   script/myapp_create.pl controller SomeTable Scaffold::HTML::Template CDBI::SomeTable

this will create a controller for SomeTable using the model CDBI::SomeTable and
all the required HTML::Template, namely :

   lib/myapp/C/SomeTable.pm
   root/SomeTable/add.tmpl
   root/SomeTable/edit.tmpl
   root/SomeTable/list.tmpl
   root/SomeTable/view.tmpl

Now just add these lines to your CDBI class...

    use Class::DBI::AsForm;
    use Class::DBI::FromForm;

...and modify the one in your application class, to load the FormValidator plugin.

    use Catalyst qw/-Debug FormValidator/;

You're done !

Just browse http://127.0.0.1:3000/sometable and enjoy the Catalyst's power :
You can now add elements in SomeTable, view them, modify them, list them and delete them.
    
=head1 METHODS

=over 4

=item mk_compclass

mk_compclass now accept a hashref as its last argument.
This hash can be used to overrides all $helper attributes
before calling its mk_dir and render_file methods

=cut

sub mk_compclass {
    my ( $self, $helper, $table_class, $ref_options ) = @_;
    if ($ref_options) {
    	my %options = %$ref_options;
    	for (keys %options) { $helper->{$_} = $options{$_} }
    }
    $helper->{table_class} = $helper->{app} . '::M::' . $table_class;
    my $file = $helper->{file};
    my $dir = dir( $helper->{base}, 'root', $helper->{prefix} );
    $helper->mk_dir($dir);
    $helper->render_file( 'compclass', $file );
    $helper->render_file( 'add',       file( $dir, 'add.tmpl' ) );
    $helper->render_file( 'edit',      file( $dir, 'edit.tmpl' ) );
    $helper->render_file( 'list',      file( $dir, 'list.tmpl' ) );
    $helper->render_file( 'view',      file( $dir, 'view.tmpl' ) );
}

=back

=head1 AUTHOR

Sebastian Riedel, Arnaud Assad

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

__PACKAGE__->config( table_class => '[% table_class %]' );

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
    $c->stash->{columns} = [
        map {
            { column => $_, field => [% table_class %]->to_field($_)->as_XML }
          } [% table_class %]->columns
    ];
    $c->stash->{template} = ucfirst('[% uri %]') . '/add.tmpl';
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
    [% table_class %]->create_from_form( $c->form );
    $c->forward('list');
}

=item do_edit

Edits a row and forwards to edit.

=cut

sub do_edit : Local {
    my ( $self, $c, $id ) = @_;
    $c->form( optional => [ [% table_class %]->columns ] );
    [% table_class %]->retrieve($id)->update_from_form( $c->form );
    $c->forward('edit');
}

=item edit

Sets a template.

=cut

sub edit : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{id}      = $id;
    $c->stash->{item}    = [% table_class %]->retrieve($id);
    $c->stash->{columns} = [
        map {
            { column => $_, field => $c->stash->{item}->to_field($_)->as_XML }
          } grep { $_ !~ /^id$/i } [% table_class %]->columns
    ];
    $c->stash->{template} = ucfirst('[% uri %]') . '/edit.tmpl';
}

=item list

Sets a template.

=cut

sub list : Local {
    my ( $self, $c ) = @_;
    my @columns = [% table_class %]->columns;
    $c->stash->{columns} =
      [ map { { column => $_ } } grep { $_ !~ /^id$/i } @columns ];
    my @objects;
    for my $object ( [% table_class %]->retrieve_all ) {
        my @cols;
        for my $col (@columns) {
            push @cols, { column => $object->$col };
        }
        push @objects,
          { columns => [@cols], base => $c->req->base, id => $object->id };
    }
    $c->stash->{objects}  = [@objects];
    $c->stash->{template} = ucfirst('[% uri %]') . '/list.tmpl';
}

=item view

Fetches a row and sets a template.

=cut

sub view : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash->{item}    = [% table_class %]->retrieve($id);
    $c->stash->{columns} =
      [ map { { column => $_, value => $c->stash->{item}->$_ } }
          grep { $_ !~ /^id$/i } [% table_class %]->columns ];
    $c->stash->{template} = ucfirst('[% uri %]') . '/view.tmpl';
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
<form action="<TMPL_VAR NAME="base">[% uri %]/do_add" method="post"> 
	<TMPL_LOOP NAME="columns"> 
		<TMPL_VAR NAME="column"><br /> 
		<TMPL_VAR NAME="field"><br />
	</TMPL_LOOP>
    <input type="submit" value="Add" /> 
</form> <br />
<a href="<TMPL_VAR NAME="base">[% uri %]/list">List</a>
__edit__
<form action="<TMPL_VAR NAME="base">[% uri %]/do_edit/<TMPL_VAR NAME="id">" method="post">
    <TMPL_LOOP NAME="columns">
        <TMPL_VAR NAME="column"><br />
        <TMPL_VAR NAME="field"><br />
    </TMPL_LOOP>
    <input type="submit" value="Edit" />
</form>
<br />
<a href="<TMPL_VAR NAME = "base">[% uri %]/list">List</a>
__list__
<table>
  <tr>
     <TMPL_LOOP NAME="columns">
        <th> <TMPL_VAR NAME="column"> </th>
     </TMPL_LOOP>
   </tr>
  <TMPL_LOOP NAME="objects">
   <tr>
    <TMPL_LOOP NAME="columns"> 
       <td> <TMPL_VAR NAME="column"> </td>
    </TMPL_LOOP>
       <td>
         <a href="<TMPL_VAR NAME="base">[% uri %]/view/<TMPL_VAR NAME="id">"> 
           View
         </a>
         <a href="<TMPL_VAR NAME="base">[% uri %]/edit/<TMPL_VAR NAME="id">">
           Edit 
         </a>
         <a href="<TMPL_VAR NAME="base">[% uri %]/destroy/<TMPL_VAR NAME="id">">
           Destroy 
         </a>
       </td>
   </tr>
  </TMPL_LOOP>
</table>
<a href="<TMPL_VAR NAME="base">[% uri %]/add">Add</a>
__view__
<TMPL_LOOP NAME="columns"> 
	<b><TMPL_VAR NAME="column"></b><br />
	<TMPL_VAR NAME="value"><br/><br />
</TMPL_LOOP>
<a href="<TMPL_VAR NAME="base">[% uri %]/list">List</a>
