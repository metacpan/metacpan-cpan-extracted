package Catmandu::Fix::Condition::is_valid_isbn;

our $VERSION = '0.13';

use Catmandu::Sane;
use Moo;
use Business::ISBN;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::Condition::SimpleAllTest';

sub emit_test {
    my ($self, $var) = @_;
    "(is_value(${var}) && Business::ISBN->new(${var}) && Business::ISBN->new(${var})->is_valid)";
}

=head1 NAME

Catmandu::Fix::Condition::is_valid_isbn - condition on validity of isbn numbers

=head1 SYNOPSIS

   if is_valid_isbn(isbn_field)
     ...
   else
     ...
   end

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
