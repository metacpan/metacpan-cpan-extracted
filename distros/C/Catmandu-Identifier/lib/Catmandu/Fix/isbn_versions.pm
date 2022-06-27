package Catmandu::Fix::isbn_versions;

our $VERSION = '0.15';

use Catmandu::Sane;
use Business::ISBN;
use Moo;
use Catmandu::Fix::Has;

has path => (fix_arg => 1);

with 'Catmandu::Fix::SimpleGetValue';

sub emit_value {
    my ($self, $var) = @_;

    qq|
if (is_value(${var}) && length(${var})) {
  my \$val = ${var};
  \$val =~ s/\\s.*//;
  my \$isbn = Business::ISBN->new(\$val);
  if (defined \$isbn && \$isbn->is_valid) {
    my \$isbn13 = \$isbn->as_isbn13->as_string;
    my \$isbn13d = \$isbn13;
    \$isbn13d =~ s/\-//g;
    my \$isbn10 = \$isbn->as_isbn10;
    if (\$isbn10) {
      my \$isbn10d = \$isbn10->as_string;
      \$isbn10d =~ s/\-//g;
      ${var} = [\$isbn10->as_string, \$isbn10d, \$isbn13, \$isbn13d];
    } else {
      ${var} = [(\$isbn13, \$isbn13d)];
    }
  }
}
|;
}

=head1 NAME

Catmandu::Fix::isbn_versions - provide different forms for an ISBN

=head1 SYNOPSIS

  # Convert any given ISBN to ISBN-13 and ISBN-10 (if possible) with and without dashes.

=head1 SEE ALSO

L<Catmandu::Fix>, L<Catmandu::Fix::isbn10>, L<Catmandu::Fix::isbn13>

=cut

1;
