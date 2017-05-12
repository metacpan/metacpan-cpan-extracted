package BERT::Atom;
use strict;
use warnings;

use overload '""'     => \&value,
             fallback => 1;

sub new {
    my ($class, $value) = @_;
    return bless \$value, $class;
}

sub value {
    return ${ $_[0] };
}

1;

__END__

=head1 NAME

BERT::Atom - Atom data type for BERT

=head1 SYNOPSIS

  use BERT;
  my $atom = BERT::Atom->new('foo');
  my $string = $atom->value;

=head1 DESCRIPTION

This module is intended to be used with L<BERT> to specify an atom value. It is
overloaded to act almost exactly like a string.

See the BERT specification at L<http://bert-rpc.org/>.

=head1 METHODS

=over 4

=item $atom = BERT::Atom->new($string)

Creates a new BERT::Atom object initialized with $string as its atom value.

=item $string = $atom->value

Returns all of the arguments that were passed to C<new()> as-is.

=back

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<BERT>

=cut
