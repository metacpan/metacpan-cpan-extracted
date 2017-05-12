package BERT::Time;
use strict;
use warnings;

use overload '""'     => sub { return join('.', $_[0]->value) },
             fallback => 1;

sub new {
    my ($class, $seconds, $microseconds) = @_;
    return bless [$seconds, $microseconds], $class;
}

sub value {
    return @{ $_[0] };
}

1;

__END__

=head1 NAME

BERT::Time - Time data type for BERT

=head1 SYNOPSIS

  use BERT;
  my $time = BERT::Time->new(255295581, 446228);
  my ($seconds, $microseconds) = $time->value;
  ($seconds, $microseconds) = split /\./, $time;

=head1 DESCRIPTION

This module is intended to be used with L<BERT> to specify a time value. It is
overloaded to act almost exactly like a string.

See the BERT specification at L<http://bert-rpc.org/>.

=head1 METHODS

=over 4

=item $time = BERT::Time->new($seconds, $microseconds)

Creates a new BERT::Time object initialized with $seconds and $microseconds as
its time value.

=item ($seconds, $microseconds) = $time->value

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
