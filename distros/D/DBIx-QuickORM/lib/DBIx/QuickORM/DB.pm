package DBIx::QuickORM::DB;
use strict;
use warnings;

our $VERSION = '0.000021';

use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;

use Object::HashBase qw{
    <name
    +connect
    <attributes
    +db_name
    +dsn
    <host
    <port
    <socket
    <user
    <pass
    <created
    <compiled
    <dialect
    <dbi_driver
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::DB - Database connection definition for DBIx::QuickORM.

=head1 DESCRIPTION

Holds the parameters needed to reach one database: dialect, connection
coordinates (DSN or host/port/socket plus user/pass), DBI attributes, and an
optional C<connect> callback. It builds DBI handles on demand, either by
invoking the callback or by calling C<< DBI->connect >> with the resolved
DSN.

=head1 SYNOPSIS

    my $db = DBIx::QuickORM::DB->new(
        dialect => $dialect,
        host    => 'localhost',
        user    => 'someuser',
        pass    => 'secret',
    );

    my $dbh = $db->new_dbh;

=head1 ATTRIBUTES

=over 4

=item name

The name of this database definition.

=item connect

Optional coderef that returns a new DBI handle. When set it is used instead
of building one from the DSN.

=item attributes

Hashref of DBI connection attributes. Sensible defaults (C<RaiseError>,
C<PrintError>, C<AutoCommit>, C<AutoInactiveDestroy>) are filled in at
construction.

=item db_name

The database (schema) name. Falls back to C<name> when not set.

=item dsn

The DBI DSN string. Built from the dialect on first use when not provided.

=item host

=item port

=item socket

Connection coordinates. A socket and a host are mutually exclusive.

=item user

=item pass

Credentials passed to C<< DBI->connect >>.

=item created

=item compiled

Provenance metadata describing where this definition came from.

=item dialect

The L<DBIx::QuickORM> dialect object (required). Used to build the DSN.

=item dbi_driver

The DBI driver name associated with this database.

=back

=head1 PUBLIC METHODS

=over 4

=item $name = $db->db_name

The database name, defaulting to C<name> when C<db_name> is unset.

=cut

sub db_name { $_[0]->{+DB_NAME} // $_[0]->{+NAME} }

sub init {
    my $self = shift;

    croak "'dialect' is a required attribute" unless $self->{+DIALECT};

    delete $self->{+NAME} unless defined $self->{+NAME};

    $self->{+ATTRIBUTES} //= {};
    $self->{+ATTRIBUTES}->{RaiseError}          //= 1;
    $self->{+ATTRIBUTES}->{PrintError}          //= 1;
    $self->{+ATTRIBUTES}->{AutoCommit}          //= 1;
    $self->{+ATTRIBUTES}->{AutoInactiveDestroy} //= 1;

    croak "Cannot provide both a socket and a host" if $self->{+SOCKET} && $self->{+HOST};
}

=pod

=item $dsn = $db->dsn

Returns the DSN, building it from the dialect and caching it on first call.

=cut

sub dsn {
    my $self = shift;
    return $self->{+DSN} if $self->{+DSN};
    return $self->{+DSN} = $self->{+DIALECT}->dsn($self);
}

=pod

=item $dbh = $db->new_dbh

Returns a new DBI handle, using the C<connect> callback when present or
C<< DBI->connect >> with the resolved DSN and credentials otherwise.

=back

=cut

sub new_dbh {
    my $self = shift;
    my (%params) = @_;

    my $attrs = $self->attributes;

    my $dbh;
    eval {
        if ($self->{+CONNECT}) {
            $dbh = $self->{+CONNECT}->();
        }
        else {
            require DBI;
            $dbh = DBI->connect($self->dsn, $self->user, $self->pass, $self->attributes);
        }

        1;
    } or confess $@;

    $dbh->{AutoInactiveDestroy} = 1 if $attrs->{AutoInactiveDestroy};

    return $dbh;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
