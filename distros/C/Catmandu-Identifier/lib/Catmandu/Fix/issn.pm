package Catmandu::Fix::issn;

use Catmandu::Sane;
use Business::ISSN;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
  my ($self, $var) = @_;
  "${var} = Business::ISSN->new(${var})->as_string if is_value(${var}) && length(${var});";
}

=head1 NAME

Catmandu::Fix::issn - normalize the issn value for a given key

=head1 SYNOPSIS

  # Normalize the ISSN value of issn_field.
  # e.g. issn_field => '1553667x'

  issn(issn_field) # issn_field => '1553-667X'

=head1 SEE ALSO

L<Catmandu::Fix>

=cut

1;
