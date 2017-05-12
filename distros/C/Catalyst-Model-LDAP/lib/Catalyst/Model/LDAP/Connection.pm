package Catalyst::Model::LDAP::Connection;

use strict;
use warnings;
use base qw/Net::LDAP Class::Accessor::Fast/;
use Carp qw/croak/;
use Catalyst::Model::LDAP::Search;
use Data::Page;
use MRO::Compat;
use Net::LDAP::Constant qw/LDAP_CONTROL_VLVRESPONSE/;
use Net::LDAP::Control::Sort;
use Net::LDAP::Control::VLV;

__PACKAGE__->mk_accessors(qw/base options entry_class/);

=head1 NAME

Catalyst::Model::LDAP::Connection - Convenience methods for Net::LDAP

=head1 DESCRIPTION

Subclass of L<Net::LDAP>, which adds paging support and an additional
method to rebless the entries.  See L<Catalyst::Model::LDAP::Entry>
for more information.

=head1 OVERRIDING METHODS

If you want to override methods provided by L<Net::LDAP>, you can use
the C<connection_class> configuration variable.  For example:

    # In lib/MyApp/Model/LDAP.pm
    package MyApp::Model::LDAP;
    use base qw/Catalyst::Model::LDAP/;

    __PACKAGE__->config(
        # ...
        connection_class => 'MyApp::LDAP::Connection',
    );

    1;

    # In lib/MyApp/LDAP/Connection.pm
    package MyApp::LDAP::Connection;
    use base qw/Catalyst::Model::LDAP::Connection/;
    use Authen::SASL;

    sub bind {
        my ($self, @args) = @_;

        my $sasl = Authen::SASL->new(...);
        push @args, sasl => $sasl;

        $self->SUPER::bind(@args);
    }

    1;

=head1 METHODS

=head2 new

Create a new connection to the specific LDAP server.

    my $conn = Catalyst::Model::LDAP::Connection->new(
        host => 'ldap.ufl.edu',
        base => 'ou=People,dc=ufl,dc=edu',
    );

On connection failure, an error is thrown using L<Carp/croak>.

=cut

sub new {
    my ($class, %args) = @_;

    my $base = delete $args{base};
    my %options = %{ ref $args{options} eq 'HASH' ? delete $args{options} : {} };
    my $entry_class = delete $args{entry_class} || 'Catalyst::Model::LDAP::Entry';

    my $host = delete $args{host};
    my $self = $class->next::method($host, %args);
    croak "Error connecting to $host: $@" unless $self;

    $self->base($base);
    $self->options(\%options);
    $self->entry_class($entry_class);

    return $self;
}

=head2 bind

Bind to the configured LDAP server using the specified credentials.

    $conn->bind(
        dn       => 'uid=dwc,ou=People,dc=ufl,dc=edu',
        password => 'secret',
    );

This method behaves similarly to L<Net::LDAP/bind>, except that it
gives an explicit name to the C<dn> parameter.  For example, if you
need to use SASL to bind to the server, you can specify that in your
call:

    $conn->bind(
        dn   => 'uid=dwc,ou=People,dc=ufl,dc=edu',
        sasl => Authen::SASL->new(mechanism => 'GSSAPI'),
    );

Additionally, if the C<start_tls> configuration option is present, the
client will use L<Net::LDAP/start_tls> to make your connection secure.

For more information on customizing the bind process, see
L</OVERRIDING METHODS>.

=cut

sub bind {
    my ($self, %args) = @_;

    delete $args{$_} for qw/host base options connection_class entry_class/;

    # Bind using TLS if configured
    if (delete $args{start_tls}) {
        my $mesg = $self->start_tls(
            %{ delete $args{start_tls_options} || {} },
        );
        croak 'LDAP TLS error: ' . $mesg->error if $mesg->is_error;
    }

    # Bind via DN if configured
    my $dn = delete $args{dn};

    $self->next::method($dn ? ($dn, %args) : %args);
}

=head2 search 

Search the configured directory using a given filter.  For example:

    my $mesg = $c->model('Person')->search('(cn=Lou Rhodes)');
    my $entry = $mesg->shift_entry;
    print $entry->title;

This method overrides the C<search> method in L<Net::LDAP> to add
paging support.  The following additional options are supported:

=over 4

=item C<page>

Which page to return.

=item C<rows>

Rows to return per page.  Defaults to 25.

=item C<order_by>

Sort the records (on the server) by the specified attribute.  Required
if you use C<page>.

=back

When paging is active, this method returns the server response and a
L<Data::Page> object.  Otherwise, it returns the server response only.

=cut

sub search {
    my $self = shift;
    my %args = scalar @_ == 1 ? (filter => shift) : @_;

    croak "Cannot use 'page' without 'order_by'"
        if $args{page} and not $args{order_by};

    # Use default base
    %args = (
        base => $self->base,
        %{ $self->options || {} },
        %args,
    );

    # Handle server-side sorting
    if (my $order_by = delete $args{order_by}) {
        my $sort = Net::LDAP::Control::Sort->new(order => $order_by);

        $args{control} ||= [];
        push @{ $args{control} }, $sort;
    }

    my ($mesg, $pager);
    if (my $page = delete $args{page}) {
        my $rows = delete $args{rows} || 25;

        my $vlv = Net::LDAP::Control::VLV->new(
            before  => 0,
            after   => $rows - 1,
            content => 0,
            offset  => ($rows * $page) - $rows + 1,
        );

        push @{ $args{control} }, $vlv;

        $mesg = $self->next::method(%args);
        my @resp = $mesg->control(LDAP_CONTROL_VLVRESPONSE) or
            croak 'Could not get pager from LDAP response: ' . $mesg->server_error;
        $pager = Data::Page->new($resp[0]->content, $rows, $page);
    }
    else {
        $mesg = $self->next::method(%args);
    }

    bless $mesg, 'Catalyst::Model::LDAP::Search';
    $mesg->init($self->entry_class);

    return ($pager ? ($mesg, $pager) : $mesg);
}

=head1 SEE ALSO

=over 4

=item * L<Catalyst::Model::LDAP>

=back

=head1 AUTHORS

=over 4

=item * Daniel Westermann-Clark

=item * Marcus Ramberg (paging support)

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
