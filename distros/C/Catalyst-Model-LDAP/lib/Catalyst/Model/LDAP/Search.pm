package Catalyst::Model::LDAP::Search;
# ABSTRACT: Convenience methods for Net::LDAP::Search

use strict;
use warnings;
use base qw/Net::LDAP::Search/;
use Module::Runtime qw/ require_module /;


sub init {
    my ( $self, $class ) = @_;

    require_module($class);

    foreach my $entry ( @{ $self->{entries} } ) {
        bless $entry, $class;
        $entry->_ldap_client( $self->parent );
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Model::LDAP::Search - Convenience methods for Net::LDAP::Search

=head1 VERSION

version 0.21

=head1 DESCRIPTION

Subclass of L<Net::LDAP::Search>, with an additional method to rebless
the entries.  See L<Catalyst::Model::LDAP::Entry> for more
information.

=head1 METHODS

=head2 init

Reblesses search results as objects of the specified class.

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Model::LDAP>

=item * L<Catalyst::Model::LDAP::Entry>

=back

=head1 AUTHORS

=over 4

=item * Marcus Ramberg

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Gavin Henry <ghenry@surevoip.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gavin Henry.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
