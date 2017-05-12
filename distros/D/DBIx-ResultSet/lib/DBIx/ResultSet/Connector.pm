package DBIx::ResultSet::Connector;
BEGIN {
  $DBIx::ResultSet::Connector::VERSION = '0.17';
}
use Moose;
use namespace::autoclean;

=head1 NAME

DBIx::ResultSet::Connector - Access result sets via DBIx::Connector.

=head1 SYNOPSIS

    use DBIx::ResultSet;
    
    # Same arguments as DBI and DBIx::Connector.
    my $connector = DBIx::ResultSet->connect(
        $dsn, $user, $pass,
        $attr, #optional
    );
    
    # Get a resultset for the users table.
    my $users_rs = $connector->resultset('users');
    
    # Use the proxied txn() method to do a bunch of inserts
    # within a single transaction that will automatically
    # re-connect if the DB connection is lost during the
    # transaction (fixup).
    $connector->txn(fixup => sub{
        foreach my $user_name (@new_user_names) {
            $users_rs->insert({ user_name=>$user_name });
        }
    });
    
    # Format dates and times in the DB's format.
    print $connector->format_datetime( DateTime->now() );
    print $connector->format_date( DateTime->now() );
    print $connector->format_time( DateTime->now() );

=head1 DESCRIPTION

This module is a lightweight wrapper around L<SQL::Abstract>,
L<SQL::Abstract::Limit>, L<DBIx::Connector>, and the various
DateTime::Format modules.  This module is primarly a factory
for creating new L<DBIx::ResultSet> objects via the
resultset() method.

=cut

use DBIx::ResultSet;
use DBIx::Connector;
use SQL::Abstract::Limit;
use Module::Load;
use Carp qw( croak );

=head1 METHODS

=head2 connect

This is the actual connect method that is called by L<DBIx::ResultSet>
See <DBIx::RestultSet/connect> for more information.

=cut

sub connect {
    my ($class, $dsn, $username, $password, $attr) = @_;
    $attr ||= {};
    $attr->{AutoCommit} = 1 if !exists( $attr->{AutoCommit} );
    my $mode = delete( $attr->{ConnectionMode} ) || 'fixup';
    my $connector = DBIx::Connector->new( $dsn, $username, $password, $attr );
    $connector->mode( $mode );
    return $class->new( dbix_connector=>$connector );
}

=head2 resultset

    # Get a resultset for the users table.
    my $users_rs = $connector->resultset('users');

Returns a new L<DBIx::ResultSet> object tied to the specified
table.

=cut

sub resultset {
    my ($self, $table) = @_;

    return DBIx::ResultSet->new(
        connector => $self,
        table     => $table,
    );
}

=head2 format_datetime

    print $connector->format_datetime( DateTime->now() );

Returns the date and time in the DB's format.

=cut

sub format_datetime {
    my ($self, $dt) = @_;
    return $self->datetime_formatter->format_datetime( $dt );
}

=head2 format_date

    print $connector->format_date( DateTime->now() );

Returns the date in the DB's format.

=cut

sub format_date {
    my ($self, $dt) = @_;
    return $self->datetime_formatter->format_date( $dt );
}

=head2 format_time

    print $connector->format_time( DateTime->now() );

Returns the time in the DB's format.

=cut

sub format_time {
    my ($self, $dt) = @_;
    return $self->datetime_formatter->format_time( $dt );
}

sub _auto_pk {
    my ($self, $table) = @_;

    my $driver = $self->dbix_connector->driver->{driver};

    if ($driver eq 'mysql') {
        return $self->run(sub{
            my ($dbh) = @_;
            return ($dbh->selectrow_array('SELECT LAST_INSERT_ID()'))[0];
        });
    }
    elsif ($driver eq 'SQLite') {
        return $self->run(sub{
            my ($dbh) = @_;
            return ($dbh->selectrow_array('SELECT LAST_INSERT_ROWID()'))[0];
        });
    }

    croak 'Retrieving autoincrementing IDs from ' . $driver . ' is not supported';
}

=head1 ATTRIBUTES

=head2 dbix_connector

Holds the underlying L<DBIx::Connector> object.  The dbh(), run(),
txn(), and svp() methods are proxied.

=cut

has 'dbix_connector' => (
    is => 'ro',
    isa => 'DBIx::Connector',
    required => 1,
    handles => [qw(
        dbh
        run
        txn
        svp
    )],
);

=head2 abstract

A L<SQL::Abstract::Limit> object for use by L<DBIx::ResultSet>.

=cut

has 'abstract' => (
    is => 'ro',
    isa => 'SQL::Abstract::Limit',
    lazy_build => 1,
);
sub _build_abstract {
    my ($self) = @_;

    return $self->run(sub{
        my ($dbh) = @_;

        return SQL::Abstract::Limit->new(
            limit_dialect => $dbh,
        );
    });
}

=head2 datetime_formatter

    my $formatter = $connector->datetime_formatter();
    print $formatter->format_date( DateTime->now() );

This returns the DateTime::Format::* class that is appropriate for
your database connection.

=cut

has 'datetime_formatter' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);
sub _build_datetime_formatter {
    my ($self) = @_;

    my %driver_to_formatter = (
        mysql  => 'MySQL',
        Pg     => 'Pg',
        Oracle => 'Oracle',
        MSSQL  => 'MSSQL',
        SQLite => 'SQLite',
    );

    my $driver = $self->dbix_connector->driver->{driver};
    my $formatter = $driver_to_formatter{ $driver };
    croak 'Unable to determine correct DateTime::Format module for the ' . $driver . ' driver' if !$formatter;
    $formatter = 'DateTime::Format::' . $formatter;
    load $formatter;

    return $formatter;
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

