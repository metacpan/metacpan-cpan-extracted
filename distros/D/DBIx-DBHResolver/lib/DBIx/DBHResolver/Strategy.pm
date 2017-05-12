package DBIx::DBHResolver::Strategy;

use strict;
use warnings;
use Carp;
use Data::Util qw(is_array_ref);

our $VERSION = '0.01';

sub connect_info { croak 'Not implement'; }
sub resolve { croak 'Not implement'; }

sub keys_from_args {
    my ( $class, $args ) = @_;
    return is_array_ref( $args->{key} ) ? @{ $args->{key} } : ( $args->{key} );
}

1;

__END__

=head1 NAME

DBIx::DBHResolver::Strategy - Strategy base class

=head1 SYNOPSIS

  use DBIx::DBHResolver::Strategy;

=head1 DESCRIPTION

=head1 METHODS

=head2 connect_info($resolver, $node_or_cluster, $args)

Abstract method.

=head2 resolve($resolver, $node_or_cluster, $args)

Abstract method.

=head2 keys_from_args($args)

Internal use.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@dena.jp<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
