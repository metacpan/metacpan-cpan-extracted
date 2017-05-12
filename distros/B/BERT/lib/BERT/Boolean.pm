package BERT::Boolean;
use strict;
use warnings;

use overload bool     => \&value,
             fallback => 1;

sub new {
    my ($class, $value) = @_;
    $value = $value ? 1 : 0;
    return bless \$value, $class;
}

sub value {
    return ${ $_[0] };
}

sub true {
    return $_[0]->new(1);
}

sub false {
    return $_[0]->new(0);
}

1;

__END__

=head1 NAME

BERT::Boolean - Boolean data type for BERT

=head1 SYNOPSIS

  use BERT;
  my $true = BERT::Boolean->true;
  my $false = BERT::Boolean->false;
  my $boolean = BERT::Boolean->new(1);
  my $number = $boolean->value;

=head1 DESCRIPTION

This module is intended to be used with L<BERT> to specify a boolean value. It is
overloaded to act almost exactly like the numbers C<1> and C<0>.

See the BERT specification at L<http://bert-rpc.org/>.

=head1 METHODS

=over 4

=item $boolean = BERT::Boolean->new($value)

Creates a new BERT::Boolean object initialized with $value as its boolean value.

=item $string = $boolean->value

Returns either C<1> or C<0> depending on the boolean interpretation of the argument
passed to C<new()>.

=back

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<BERT>

=cut
