package DBIx::DBHResolver::Strategy::Remainder;

use strict;
use warnings;
use Carp;

our $VERSION = '0.10';

sub connect_info {
    my ( $class, $resolver, $node, $args ) = @_;
    croak q|args has not 'key' field|
      unless ( defined $args->{key} && $args->{key} =~ m/^\d+$/ );
    my @nodes         = $resolver->clusters($node);
    my $resolved_node = $nodes[ $args->{key} % scalar @nodes ];
    return $resolver->connect_info($resolved_node);
}

1;

=head1 NAME

DBIx::DBHResolver::Strategy::Remainder - Deprecated

=head1 SYNOPSIS

=head1 DESCRIPTION

DBIx::DBHResolver::Strategy::Remainder is now deprecated. Please use to L<DBIx::DBHResolver::Strategy::Key> instead of this.

=head1 METHOD

=head2 connect_info( $resolver, $node, $args )

=head1 AUTHOR

Kosuke Arisawa E<lt>arisawa@gmail.comE<gt>

=head1 SEE ALSO

=over

=item L<DBIx::DBHResolver>

=item L<DBIx::DBHResolver::Strategy::Key>

=item L<DBI>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
