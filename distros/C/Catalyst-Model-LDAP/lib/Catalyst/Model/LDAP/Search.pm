package Catalyst::Model::LDAP::Search;

use strict;
use warnings;
use base qw/Net::LDAP::Search/;

=head1 NAME

Catalyst::Model::LDAP::Search - Convenience methods for Net::LDAP::Search

=head1 DESCRIPTION

Subclass of L<Net::LDAP::Search>, with an additional method to rebless
the entries.  See L<Catalyst::Model::LDAP::Entry> for more
information.

=head1 METHODS

=head2 init

Reblesses search results as objects of the specified class.

=cut

sub init {
    my ($self, $class) = @_;

    eval "require $class";
    die $@ if $@;

    foreach my $entry (@{ $self->{entries} }) {
        bless $entry, $class;
        $entry->_ldap_client($self->parent);
    }
}

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

=cut

1;
