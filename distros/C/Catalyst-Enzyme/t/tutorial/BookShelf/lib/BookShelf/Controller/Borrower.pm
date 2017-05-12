package BookShelf::Controller::Borrower;
use base 'Catalyst::Enzyme::CRUD::Controller';

use strict;
use warnings;



=head1 NAME

BookShelf::Controller::Borrower - Catalyst Enzyme CRUD Controller



=head1 SYNOPSIS

See L<BookShelf>



=head1 DESCRIPTION

Catalyst Enzyme Controller with CRUD support.



=head1 METHODS

=head2 model_class

Define the  model class for this Controller

=cut
sub model_class {
    return("BookShelf::Model::BookShelfDB::Borrower");
}



=head1 SEE ALSO

L<BookShelf>, L<Catalyst::Enzyme::CRUD::Controller>,
L<Catalyst::Enzyme>



=head1 AUTHOR

A clever guy



=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
