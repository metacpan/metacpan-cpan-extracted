package Catalyst::Enzyme::CRUD::Model;
use base 'Catalyst::Model';

our $VERSION = 0.10;



use strict;



=head1 NAME

Catalyst::Enzyme::CRUD::Model - CRUD Model Component


=head1 SYNOPSIS



=head1 DESCRIPTION

CRUD Model Component.

This is how to configure your model classes' meta data.


=head1 ENZYME MODEL CONFIGURATION: 

Some things are Enzyme related configurations. These go in the:

    __PACKAGE__->config( crud => {} )

hash ref.


=head2 moniker

Human readable name for this model.

E.g. "Shop Location".

Default: MyApp::Model::CDBI::ShopLocation becomes "Shop Location".



=head2 column_monikers

Column monikers. Hash ref with (key: column name: value:
moniker).

Default: based on the column name (id_% and %id removed, the
capitalized).

Override specific column names like this:

    column_monikers => { __PACKAGE__->default_column_monikers, url => "URL" },


=head2 data_form_validator

Validation rules for the data fields.

Default: no validation, all columns are optional.

Note that you need to provide the entire config hashref that
L<Data::FormValidator> expects.


=head2 rows_per_page

Number of rows per page when using a pager (which will happen unless
paging is disabled by setting this value is 0).

Default: 20



=head1 CDBI CONFIGURATION

=head2 Stringified column

Let's say your Model class Book has a Foreign Key (FK) genre_id to the
Genre Model class.

In the list of Books, the Genre will just be displayed with this
identifier, whereas you really would like it to display the Genre name.

In the Genre model class, define the column group Stringify, like this:

  __PACKAGE__->columns(Stringify => qw/ name /);

This magic is performed by L<Class::DBI> and L<Class::DBI::AsForm>'s
to_field method.

When objects are displayed in a C<list>, the text in the Stringify
column will become a link to C<view> the object.



=head2 Fields to display

The following set of columns can be defined for various uses in the
templates. The column names both define which columns to display, and
in which order.

    __PACKAGE__->columns(view_columns => qw/ COLUMNS /);
    __PACKAGE__->columns(edit_columns => qw/ COLUMNS /);
    __PACKAGE__->columns(list_columns => qw/ COLUMNS /);

The default is all columns except primary keys.

These are pre-entered by the Model helper so it's easy for you to
remove or change the order. If you like it the way it is, just delete
the lines altogether.



=head1 EXAMPLE

    use Data::FormValidator::Constraints qw(:regexp_common);

    __PACKAGE__->columns(Stringify => qw/ url /);
    __PACKAGE__->columns(list_columns=> qw/ name email url /);
    __PACKAGE__->columns(view_columns=> qw/ name email url phone /);


    __PACKAGE__->config(

        crud => {
            moniker => "URL",
            rows_per_page => 20,
            data_form_validator => {
                optional => [ __PACKAGE__->columns ],
                required => [ "url" ],
                constraint_methods => {
                    url => FV_URI(),
                },
                msgs => {
                    format => '%s',
                    constraints => {
                        FV_URI => "Not a URL",
                    },
                },
            },
        },
    );




=head1 CLASS METHODS


=head2 default_column_monikers()

Return hash ref with the default column monikers (display names) for
all columns.

You can use this to setup a Model's crud config like this:

    __PACKAGE__->config(
        crud => {
            column_monikers => { __PACKAGE__->default_column_monikers, url_id => "URL" };
        },
    );

=cut
sub default_column_monikers {
    my $pkg = shift;
    return( map { $_ => $pkg->default_column_moniker($_) } $pkg->columns );
}





=head2 default_column_moniker($column)

Return default name for $column.

Remove _id$ and ^id_.

Exemple: author_name_id --> Author Name

=cut
sub default_column_moniker {
    my $pkg = shift;
    my ($column) = @_;

    my $name = lc($column);
    $name =~ s/^id_//i;
    $name =~ s/_id$//i;

    $name =~ s/(.)[_\s]+(.)/ "$1 " . uc($2) /eg;

    $name = ucfirst($name);
    
    return($name);
}





=head2 list_columns()

Return array with the column names suitable for a list of the objects
in this Model.

Configure this with:

    __PACKAGE__->columns(list_columns => qw/ column names /);

Default: the default_columns.

=cut
sub list_columns {
    my $pkg = shift;
    return($pkg->named_columns("list_columns"));
}





=head2 view_columns()

Return array with the column names suitable for viewing an object in
this Model.

Configure this with:

    __PACKAGE__->columns(view_columns => qw/ column names /);

Default: the default_columns.

=cut
sub view_columns {
    my $pkg = shift;
    return($pkg->named_columns("view_columns"));
}





=head2 edit_columns()

Return array with the column names suitable for editing an object in
this Model.

Configure this with:

    __PACKAGE__->columns(edit_columns => qw/ column names /);

Default: edit_columns (if specified), otherwise the default_columns.

=cut
sub edit_columns {
    my $pkg = shift;

    my @columns = $pkg->columns("view_columns");
    @columns or @columns = $pkg->view_columns;
    @columns or @columns = $pkg->default_columns();
    
    return(@columns);
}





=head2 named_columns($group_name)

Return array with the column names identified by
__PACKAGE__->columns($group_name).

Configure this with:

    __PACKAGE__->columns($group_name => qw/ column names /);

=cut
sub named_columns {
    my $pkg = shift;
    my ($group_name) = @_;

    my @columns = $pkg->columns($group_name);
    @columns or @columns = $pkg->default_columns();

    return(@columns);
}





=head2 default_columns()

Return array with the default column names suitable for an object in
this Model.

This is all column names, except PK columns.

=cut
sub default_columns {
    my $pkg = shift;

    my %pk_name_exists = map { $_ => 1 } $pkg->columns("Primary");
    my @columns = grep { ! $pk_name_exists{$_} } $pkg->columns();
    
    return(@columns);
}





=head2 namespace_of_column_has_a($c, $column)

If $column has a has_a relationship to another table, return the
Model's Controller's namespace (or the first if there are many).

Return "" if there are no related tables.

=cut
sub namespace_of_column_has_a {
    my $pkg = shift;
    my ($c, $column) = @_;

    my $has_a = $pkg->meta_info->{has_a}->{$column} or return("");
#    my $has_a_class = $has_a->foreign_class or return("");
#    $c->models

    #todo: this is a hack, replace with a proper search-for-the controller with model_class
    my $namespace = $has_a->foreign_class or return("");
    $namespace =~ s/^(.*?)::(\w+)$/lc($2)/e or return("");
    
    return("/$namespace");
}





=head1 AUTHOR

Johan Lindstrom <johanl ÄT cpan.org>



=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
