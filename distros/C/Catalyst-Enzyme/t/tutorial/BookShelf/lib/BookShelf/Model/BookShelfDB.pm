package BookShelf::Model::BookShelfDB;
use base 'Catalyst::Model::CDBI';

use strict;
use Class::DBI::Pager;
use Path::Class;



__PACKAGE__->config(
    dsn           => 'dbi:SQLite:dbname=' . file(BookShelf->config->{home}, 'db/bookshelf.db'),
    user          => '',
    password      => '',
    options       => {},
    relationships => 1,
    additional_base_classes => [
        qw/
           Class::DBI::AsForm
           Class::DBI::FromForm
           Catalyst::Enzyme::CRUD::Model
           /
       ],    
);




=head1 NAME

BookShelf::Model::BookShelfDB - Enzyme CDBI Model Component



=head1 SYNOPSIS

See L<BookShelf>



=head1 DESCRIPTION

Enzyme CDBI Model Component.



=head1 SEE ALSO

L<BookShelf>, L<Catalyst::Enzyme>



=head1 AUTHOR

A clever guy



=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
