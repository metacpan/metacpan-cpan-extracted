package DBIx::QuickORM::ORM;
use strict;
use warnings;

our $VERSION = '0.000022';

use Carp qw/croak/;

use DBIx::QuickORM::Connection;

use Object::HashBase qw{
    <name
    +db
    <schema
    <autofill
    <row_class
    <created
    <compiled
    cache_class
    <default_handle_class
    <row_manager

    +connection
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::ORM - Binds a schema to a database for DBIx::QuickORM.

=head1 DESCRIPTION

An ORM object pairs a database definition with a schema (or autofill) and
owns the primary connection to that database. It is the entry point callers
use to obtain a connection or a query handle; the connection is created lazily
and reused.

=head1 SYNOPSIS

    my $orm = DBIx::QuickORM::ORM->new(
        db       => $db,
        schema   => $schema,
    );

    my $con    = $orm->connection;
    my $handle = $orm->handle('users');

=head1 ATTRIBUTES

=over 4

=item name

The name of this ORM.

=item db

The L<DBIx::QuickORM::DB> definition. Settable once via C<db>.

=item schema

The schema object. Either this or C<autofill> is required.

=item autofill

When true, missing schema metadata is introspected from the live database.

=item row_class

The class used for row objects.

=item created

=item compiled

Provenance metadata describing where this ORM came from.

=item cache_class

Optional class used to build the per-connection cache.

=item default_handle_class

Optional default handle class passed through to new connections.

=item row_manager

Optional row manager class (or instance) passed through to new connections
as their C<manager>. When unset the connection uses its own default
(L<DBIx::QuickORM::RowManager::Cached>).

=item connection

The active connection, created lazily and cached here.

=back

=head1 PUBLIC METHODS

=over 4

=item $db = $orm->db

=item $orm->db($db)

Gets the database definition, or sets it once. Croaks on a second set or when
fetched before being set.

=cut

sub init {
    my $self = shift;

    delete $self->{+NAME} unless defined $self->{+NAME};

    croak "You must either provide the 'schema' attribute or enable 'autofill'"
        unless $self->{+SCHEMA} || $self->{+AUTOFILL};
}

sub db {
    my $self = shift;

    if (@_) {
        croak "'db' has already been set" if $self->{+DB};
        croak "Too many arguments" if @_ > 1;
        ($self->{+DB}) = @_;
    }

    return $self->{+DB} // croak "'db' has not been set";
}

=pod

=item $con = $orm->connect

Builds and returns a new L<DBIx::QuickORM::Connection> for this ORM. Croaks
when no database has been set.

=cut

sub connect {
    my $self = shift;

    croak "'db' has not been set" unless $self->{+DB};

    my %params = (orm => $self);
    $params{cache} = $self->{+CACHE_CLASS}->new() if $self->{+CACHE_CLASS};

    $params{+DEFAULT_HANDLE_CLASS} = $self->{+DEFAULT_HANDLE_CLASS};

    $params{manager} = $self->{+ROW_MANAGER} if $self->{+ROW_MANAGER};

    return DBIx::QuickORM::Connection->new(%params);
}

=pod

=item $con = $orm->connection

Returns the active connection, creating it via C<connect> on first use.

=item $orm->disconnect

Drops the cached connection.

=item $con = $orm->reconnect

Drops the cached connection and returns a fresh one.

=item $handle = $orm->handle(...)

Delegates to the active connection's C<handle>.

=back

=cut

sub disconnect {
    my $self = shift;
    delete $self->{+CONNECTION};
}

sub reconnect {
    my $self = shift;
    $self->disconnect;
    return $self->connection;
}

sub connection {
    my $self = shift;
    return $self->{+CONNECTION} //= $self->connect;
}

sub handle {
    my $self = shift;
    return $self->connection->handle(@_);
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
