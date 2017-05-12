package Catalyst::Helper::Model::LDAP;

use strict;
use warnings;

=head1 NAME

Catalyst::Helper::Model::LDAP - Helper for LDAP models

=head1 SYNOPSIS

    script/myapp_create.pl model Person LDAP ldap.ufl.edu ou=People,dc=ufl,dc=edu dn=admin,dc=ufl,dc=edu mypass 1

=head1 DESCRIPTION

Helper for the L<Catalyst> LDAP model.

=head1 USAGE

When creating a new LDAP model class using this helper, you can
specify much of the configuration and have it filled automatically.
Using the example from the L</SYNOPSIS> section:

=over

=item * C<Person>

The name of the model.  This is also used to determine the filename,
e.g. C<lib/MyApp/Model/Person.pm>.

=item * C<LDAP>

The helper to use, i.e. this one.

=item * C<ldap.ufl.edu>

The LDAP server's fully qualified domain name (FQDN).  Can also be an
IP address, e.g. C<127.0.0.1>.

=item * C<ou=People,dc=ufl,dc=edu>

The base distinguished name (DN) for searching the directory.

=item * C<dn=admin,dc=ufl,dc=edu>

The bind DN for connecting to the directory.  This can be anyone that
has permission to search under the base DN, as per your LDAP server's
access control lists.

=item * C<mypass>

The password for the specified bind DN.

=item * C<1>

Optionally uses TLS when binding to the LDAP server, for secure
connections.

=back

=head1 METHODS

=head2 mk_compclass

Makes the LDAP model class.

=cut

sub mk_compclass {
    my ($self, $helper, $host, $base, $dn, $password, $start_tls) = @_;

    $helper->{host}      = $host      || '';
    $helper->{base}      = $base      || '';
    $helper->{dn}        = $dn        || '';
    $helper->{password}  = $password  || '';
    $helper->{start_tls} = $start_tls ? 1 : 0;

    $helper->render_file('modelclass', $helper->{file});

    return 1;
}

=head2 mk_comptest

Makes tests for the LDAP model.

=cut

sub mk_comptest {
    my ($self, $helper) = @_;

    $helper->render_file('modeltest', $helper->{test});
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Manual>

=item * L<Catalyst::Test>

=item * L<Catalyst::Helper>

=back

=head1 AUTHORS

=over

=item * Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=item * Gavin Henry E<lt>ghenry@cpan.orgE<gt> (TLS Helper option and documentation)

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__modelclass__
package [% class %];

use strict;
use warnings;
use base qw/Catalyst::Model::LDAP/;

__PACKAGE__->config(
    host              => '[% host %]',
    base              => '[% base %]',
    dn                => '[% dn %]',
    password          => '[% password %]',
    start_tls         => [% start_tls %],
    start_tls_options => { verify => 'require' },
    options           => {},  # Options passed to search
);

=head1 NAME

[% class %] - LDAP Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

LDAP Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__modeltest__
use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');
