package Catmandu::Fix::isbn13;

our $VERSION = '0.11';

use Catmandu::Sane;
use Business::ISBN;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
  my ($self, $var) = @_;

  "${var} = Business::ISBN->new(${var})->as_isbn13->as_string if is_value(${var}) && length(${var});";

}

=head1 NAME

Catmandu::Fix::isbn13 - normalize the isbn value of a key in 13-digit form

=head1 SYNOPSIS

  # Normalize the ISBN value of isbn_field.
  # e.g. isbn_field => '1565922573'

  isbn13(isbn_field) # isbn_field => '978-1-56592-257-0'

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Fix::isbn10>

=cut

1;
