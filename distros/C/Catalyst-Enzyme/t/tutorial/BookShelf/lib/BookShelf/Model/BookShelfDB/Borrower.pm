package BookShelf::Model::BookShelfDB::Borrower;

use strict;



=head1 NAME

BookShelf::Model::BookShelfDB::Borrower - CDBI Table Class



=head1 SYNOPSIS

See L<BookShelf>



=head1 DESCRIPTION

CDBI Table Class with Enzyme CRUD configuration.

=cut


use Data::FormValidator::Constraints qw(:regexp_common);
__PACKAGE__->columns(Stringify=> qw/name/);

__PACKAGE__->columns(list_columns=> qw/ name email url /);
__PACKAGE__->columns(view_columns=> qw/ name email url phone /);

__PACKAGE__->config(
    crud => {
        data_form_validator => {
            optional => [ __PACKAGE__->columns ],
            required => [ "name" ],
            constraint_methods => {
                url => FV_URI(),
                email => Data::FormValidator::Constraints::email(),
            },
            missing_optional_valid => 1,
            msgs => {
                format => '%s',
                constraints => {
                    FV_URI => "Not a URL",
                    email => "Not an email",
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
