package Catmandu::Fix::isbn10;

use Catmandu::Sane;
use Business::ISBN;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
  my ($self, $var) = @_;

  "${var} = Business::ISBN->new(${var})->as_isbn10->as_string if is_value(${var}) && length(${var});";

}

=head1 NAME

Catmandu::Fix::isbn10 - normalize the isbn value of a key in 10-digit form

=head1 SYNOPSIS

  # Normalize the ISBN value of isbn_field.
  # e.g. isbn_field => '1565922573'

  isbn10(isbn_field) # isbn_field => '1-56592-257-3'

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Fix::isbn13>

=cut

1;
