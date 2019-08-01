package DNS::Unbound::X::ResolveError;

use strict;
use warnings;

use parent qw( DNS::Unbound::X::Base );

=encoding utf-8

=head1 NAME

DNS::Unbound::X::ResolveError

=head1 DESCRIPTION

This class subclasses L<X::Tiny::Base> and represents a libunbound DNS
resolution failure. Its instances contain the following properties:

=over

=item * C<number> - The libunbound error number.

=item * C<string> - libunbound’s string that describes the error.

=back

=cut

sub _new {
    my ($class, @args_kv) = @_;

    return $class->SUPER::_new( 'DNS query resolution failure', @args_kv );
}

1;
