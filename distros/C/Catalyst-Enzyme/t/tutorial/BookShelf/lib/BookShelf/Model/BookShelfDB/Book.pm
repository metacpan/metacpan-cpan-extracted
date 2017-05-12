package BookShelf::Model::BookShelfDB::Book;

use strict;



=head1 NAME

BookShelf::Model::BookShelfDB::Book - CDBI Table Class



=head1 SYNOPSIS

See L<BookShelf>



=head1 DESCRIPTION

CDBI Table Class with Enzyme CRUD configuration.

=cut


__PACKAGE__->columns(Stringify => "title");

__PACKAGE__->columns(list_columns => qw/ title author genre borrower borrowed format isbn /);
__PACKAGE__->columns(view_columns => __PACKAGE__->columns("list_columns"), "publisher");

__PACKAGE__->config(

    crud => {
        moniker => "Book",
        column_monikers => { __PACKAGE__->default_column_monikers, isbn => "ISBN" },
        rows_per_page => 10,
        data_form_validator => {
            optional => [ __PACKAGE__->columns ],
            required => [ qw/ title format genre /],
            constraint_methods => {
                isbn => { name => "fv_isbn", constraint => qr/^[\d-]+$/ },
            },
            missing_optional_valid => 1,
            msgs => {
                format => '%s',
                constraints => {
                    fv_isbn => "Not an ISBN number",
                },
            },
        },
    },
);



=head1 ALSO

L<Catalyst::Enzyme>



=head1 AUTHOR

A clever guy



=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
