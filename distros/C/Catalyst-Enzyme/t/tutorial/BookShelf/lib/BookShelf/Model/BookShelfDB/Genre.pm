package BookShelf::Model::BookShelfDB::Genre;

use strict;



=head1 NAME

BookShelf::Model::BookShelfDB::Genre - CDBI Table Class



=head1 SYNOPSIS

See L<BookShelf>



=head1 DESCRIPTION

CDBI Table Class with Enzyme CRUD configuration.

=cut


__PACKAGE__->columns(Stringify => "name");


#See the Catalyst::Enzyme docs and tutorial for information on what
#CRUD options you can configure here. These include: moniker,
#column_monikers, rows_per_page, data_form_validator.
__PACKAGE__->config(
    crud => {
        rows_per_page => 3
    }
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
