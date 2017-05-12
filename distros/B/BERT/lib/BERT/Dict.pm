package BERT::Dict;
use strict;
use warnings;

sub new {
    my ($class, $arrayref) = @_;
    return bless \$arrayref, $class;
}

sub value {
    return ${ $_[0] };
}

1;

__END__

=head1 NAME

BERT::Dict - Dict data type for BERT

=head1 SYNOPSIS

  use BERT;
  my $dict = BERT::Dict->new([ BERT::Atom->new('key') => 'value' ]);
  my $arrayref = $dict->value;

=head1 DESCRIPTION

This module is intended to be used with L<BERT> to specify a dictionary value.

See the BERT specification at L<http://bert-rpc.org/>.

=head1 METHODS

=over 4

=item $dict = BERT::Dict->new($arrayref)

Creates a new BERT::Dict object initialized with $arrayref as its dictionary
value.

=item $arrayref = $dict->value

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
