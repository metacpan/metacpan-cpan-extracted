package BookShelf::View::TT;

use strict;
use base qw/ Catalyst::View::TT::ControllerLocal Catalyst::Enzyme::CRUD::View /;

use HTML::Element;
use Data::Dumper;



=head1 NAME

BookShelf::View::TT - Catalyst Catalyst::Enzyme::CRUD::View TT View




=head1 SYNOPSIS

See L<BookShelf>



=head1 DESCRIPTION

Catalyst TT View with L<Catalyst::View::TT::ControllerLocal> and
L<Catalyst::Enzyme::CRUD::View> CRUD support.





=head1 METHODS

=head2 dropdown_remove_id($element, $id)

Modify the $element (a <SELECT>) to remove any <OPTION>s with value eq
$id.

=cut
sub dropdown_remove_id {
    my ($self, $element, $id) = @_;
    $element->tag eq "select" or return($element);

    my @to_remove;
    for my $option ($element->content_list) {
        push(@to_remove, $option) if($option->attr("value") eq $id);
    }
    $_->detach() for(@to_remove);
     
    return($element);
}





=head1 AUTHOR

A clever guy



=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
