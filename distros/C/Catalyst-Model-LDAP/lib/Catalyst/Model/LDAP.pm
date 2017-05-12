package Catalyst::Model::LDAP;

use strict;
use warnings;
use base qw/Catalyst::Model/;
use Carp qw/croak/;

our $VERSION = '0.17';

=head1 NAME

Catalyst::Model::LDAP - LDAP model class for Catalyst

=head1 SYNOPSIS

    # Use the Catalyst helper
    script/myapp_create.pl model Person LDAP ldap.ufl.edu ou=People,dc=ufl,dc=edu

    # Or, in lib/MyApp/Model/Person.pm
    package MyApp::Model::Person;

    use base qw/Catalyst::Model::LDAP/;

    __PACKAGE__->config(
        host => 'ldap.ufl.edu',
        base => 'ou=People,dc=ufl,dc=edu',
    );

    1;

    # Then, in your controller
    my $mesg = $c->model('Person')->search('(cn=Lou Rhodes)');
    my @entries = $mesg->entries;
    print $entries[0]->sn;

=head1 DESCRIPTION

This is the L<Net::LDAP> model class for Catalyst.  It is nothing more
than a simple wrapper for L<Net::LDAP>.

This class simplifies LDAP access by letting you configure a common
set of bind arguments.  It also lets you configure a base DN for
searching.

Please refer to the L<Net::LDAP> documentation for information on what
else is available.

=head1 CONFIGURATION

The following configuration parameters are supported:

=over 4

=item * C<host>

The LDAP server's fully qualified domain name (FQDN),
e.g. C<ldap.ufl.edu>.  Can also be an IP address, e.g. C<127.0.0.1>.

=item * C<base>

The base distinguished name (DN) for searching the directory,
e.g. C<ou=People,dc=ufl,dc=edu>.

=item * C<dn>

(Optional) The bind DN for connecting to the directory,
e.g. C<dn=admin,dc=ufl,dc=edu>.  This can be anyone that has
permission to search under the base DN, as per your LDAP server's
access control lists.

=item * C<password>

(Optional) The password for the specified bind DN.

=item * C<start_tls>

(Optional) Set to C<1> to use TLS when binding to the LDAP server, for
secure connections.

=item * C<start_tls_options>

(Optional) A hashref containing options to use when binding using TLS
to the LDAP server.

=item * C<options>

(Optional) A hashref containing options to pass to
L<Catalyst::Model::LDAP::Connection/search>.  For example, this can be
used to set a sizelimit.

NOTE: In previous versions, these options were passed to all
L<Net::LDAP> methods.  This has changed to allow a cleaner connection
interface.  If you still require this behavior, create a class
inheriting from L<Catalyst::Model::LDAP::Connection> that overrides
the specific methods and set C<connection_class>.

=item * C<connection_class>

(Optional) The class or package name that wraps L<Net::LDAP>.
Defaults to L<Catalyst::Model::LDAP::Connection>.

See also L<Catalyst::Model::LDAP::Connection/OVERRIDING METHODS>.

=item * C<entry_class>

(Optional) The class or package name to rebless L<Net::LDAP::Entry>
objects as.  Defaults to L<Catalyst::Model::LDAP::Entry>.

See also L<Catalyst::Model::LDAP::Entry/ADDING ENTRY METHODS>.

=back

=head1 INTERNAL METHODS

=head2 ACCEPT_CONTEXT

Bind the client using the current configuration and return it.  This
method is automatically called when you use e.g. C<< $c->model('LDAP') >>.

See L<Catalyst::Model::LDAP::Connection/bind> for information on how
the bind operation is done.

=cut

sub ACCEPT_CONTEXT {
    my ($self) = @_;

    my %args = %$self;

    # Remove Catalyst-specific parameters (e.g. catalyst_component_name), which
    # cause issues Net::LDAP
    delete $args{$_} for (grep { /^_?catalyst/ } keys %args);

    my $class = $args{connection_class} || 'Catalyst::Model::LDAP::Connection';
    eval "require $class";
    die $@ if $@;

    my $conn = $class->new(%args);
    my $mesg = $conn->bind(%args);
    croak 'LDAP error: ' . $mesg->error if $mesg->is_error;

    return $conn;
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Helper::Model::LDAP>

=item * L<Catalyst::Model::LDAP::Connection>

=item * L<Catalyst::Model::LDAP::Search>

=item * L<Catalyst::Model::LDAP::Entry>

=item * L<Catalyst>

=item * L<Net::LDAP>

=back

=head1 AUTHORS

=over 4

=item * Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=item * Adam Jacob E<lt>holoway@cpan.orgE<gt> (TLS support)

=item * Marcus Ramberg (paging support and entry AUTOLOAD)

=back

=head1 ACKNOWLEDGMENTS

=over 4

=item * Salih Gonullu, for initial work on Catalyst mailing list

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
