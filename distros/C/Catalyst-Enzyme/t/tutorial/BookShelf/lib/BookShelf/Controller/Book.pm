package BookShelf::Controller::Book;
use base 'Catalyst::Enzyme::CRUD::Controller';

use strict;
use warnings;



=head1 NAME

BookShelf::Controller::Book - Catalyst Enzyme CRUD Controller



=head1 SYNOPSIS

See L<BookShelf>



=head1 DESCRIPTION

Catalyst Enzyme Controller with CRUD support.



=head1 METHODS

=head2 model_class

Define the  model class for this Controller

=cut
sub model_class {
    return("BookShelf::Model::BookShelfDB::Book");
}




=head1 ACTIONS

=head2 do_checkout()

=cut
sub do_borrow : Local {
    my ( $self, $c, $id ) = @_;
    $id += 0;

    $c->form(
        required => [ qw/ borrower / ],
        defaults => { borrowed => scalar(localtime()) }
    );
    $c->form->success or return( $c->forward('edit') );
    
    $self->run_safe($c,
        sub  {
            $c->form->valid("borrower") eq "1" and die("The Bookshelf can't borrow a book, silly!\n");

            my $item = $self->model_class->retrieve($id) or die("Could not find id ($id)\n");

            if($item->borrower && $item->borrower->id &&
                   $item->borrower->id ne "1" &&
                   $item->borrower->id ne $c->form->valid("borrower")
                   ) {
                die("Book is already borrowed by '" . $item->borrower . "'\n");
            }
            
            $item->update_from_form( $c->form );
        },
        "/book/view/$id", "Could not borrow book",
    ) or return;

    $c->stash->{message} = "Book borrowed OK";

    return( $c->res->redirect( $c->uri_for('view', $id) ) );
}



=head2 do_return

=cut
sub do_return : Local {
    my ( $self, $c, $id ) = @_;
    $id += 0;
    
    $self->run_safe($c,
        sub  {
            my $item = $self->model_class->retrieve($id) or die("Could not find id ($id)\n");
            $item->borrowed(undef);
            $item->borrower(1);  #hard coded to In Shelf (this should be in the model)
            $item->update;
        },
        "view", "Could not return book",
    ) or return;

    $c->stash->{message} = "Book returned OK";

    return( $c->res->redirect( $c->uri_for('view', $id) ) );
#    return( $c->res->redirect($c->uri_for('view', $id)) );
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
