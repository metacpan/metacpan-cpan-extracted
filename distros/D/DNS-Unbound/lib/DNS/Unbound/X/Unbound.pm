package DNS::Unbound::X::Unbound;

use strict;
use warnings;

use parent qw( DNS::Unbound::X::Base );

=encoding utf-8

=head1 NAME

DNS::Unbound::X::Unbound

=head1 DESCRIPTION

This class subclasses L<X::Tiny::Base> and represents a libunbound
error. Its instances contain the following properties:

=over

=item * C<number> - The libunbound error number. Will correspond
to one of L<DNS::Unbound>’s C<UB_*> constants.

=item * C<string> - libunbound’s string that describes the error.

=back

=cut

sub _new {
    my ($class, $msg, %args_kv) = @_;

    my $str = "$msg: $args_kv{'string'}";

    return $class->SUPER::_new( $str, %args_kv );
}

1;
