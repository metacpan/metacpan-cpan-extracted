package Catalyst::Model::LDAP::Entry;

use strict;
use warnings;
use base qw/Net::LDAP::Entry Class::Accessor::Fast/;
use Carp qw/croak/;
use MRO::Compat;

__PACKAGE__->mk_accessors(qw/_ldap_client/);

=head1 NAME

Catalyst::Model::LDAP::Entry - Convenience methods for Net::LDAP::Entry

=head1 SYNOPSIS

    # In your controller
    my $mesg = $c->model('Person')->search('(cn=Lou Rhodes)');
    my $entry = $mesg->shift_entry;
    print $entry->title;

=head1 DESCRIPTION

This module simplifies use of L<Net::LDAP::Entry> objects in your
application.  It makes accessors and mutators for all attributes on an
entry.  For example:

    print $entry->cn;

It also stores a reference to the parent LDAP connection, simplifying
updates to the entry:

    $entry->title('Folk singer');
    $entry->update;

=head1 ADDING ENTRY METHODS

If you want to provide your own methods on an LDAP entry, you can use
the C<entry_class> configuration variable.  For example:

    # In lib/MyApp/Model/LDAP.pm
    package MyApp::Model::LDAP;
    use base qw/Catalyst::Model::LDAP/;

    __PACKAGE__->config(
        # ...
        entry_class => 'MyApp::LDAP::Entry',
    );

    1;

    # In lib/MyApp/LDAP/Entry.pm
    package MyApp::LDAP::Entry;
    use base qw/Catalyst::Model::LDAP::Entry/;
    use DateTime::Format::Strptime;

    sub get_date {
        my ($self, $attribute) = @_;

        my ($datetime) = ($self->get_value($attribute) =~ /^(\d{14})/);

        my $parser = DateTime::Format::Strptime->new(
            pattern     => '%Y%m%d%H%M%S',
            locale      => 'en_US',
            time_zone   => 'UTC'
        );

        return $parser->parse_datetime($datetime);
    }

    1;

=head1 METHODS

=head2 new

Override the L<Net::LDAP::Entry> object constructor to take an
optional LDAP handle.  If provided this will be used automatically on
L</update>.

=cut

sub new {
    my ($class, $dn, %attributes) = @_;

    my $client = delete $attributes{_ldap_client};

    my $self = $class->next::method($dn, %attributes);

    if ($client) {
        $self->_ldap_client($client);
    }

    return $self;
}

=head2 update

Override C<update> to default to the optional LDAP handle provided to
the constructor.

=cut

sub update {
    my $self   = shift;
    my $client = shift || $self->_ldap_client;
    croak 'No LDAP client provided to update' unless $client;

    return $self->next::method($client, @_);
}

=head2 can

Override C<can> to declare existence of the LDAP entry attribute
methods from C<AUTOLOAD>.

=cut

sub can {
    my ($self, $method) = @_;
    return 0 unless ref($self);
    $self->exists($method) || $self->SUPER::can($method);
}

sub AUTOLOAD {
    my ($self, @args) = @_;

    my ($attribute) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $attribute eq 'DESTROY';

    croak qq[Can't locate object method "$attribute" via package "] . ref($self) . qq["]
        unless $self->exists($attribute);

    if (scalar @args) {
        $self->replace($attribute, @args);
    }

    return $self->get_value($attribute);
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Model::LDAP>

=item * L<Catalyst::Model::LDAP::Search>

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
