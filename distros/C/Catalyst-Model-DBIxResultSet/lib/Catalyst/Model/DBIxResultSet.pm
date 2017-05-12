package Catalyst::Model::DBIxResultSet;
BEGIN {
  $Catalyst::Model::DBIxResultSet::VERSION = '0.02';
}
use Moose;

=head1 NAME

Catalyst::Model::DBIxResultSet - A Catalyst model for DBIx::ResultSet.

=head1 SYNOPSIS

Create a model in you Catalyst apps Model directory:

    package MyApp::Model::DBIxResultSet;
    use Moose;
    use namespace::autoclean;
    
    extends 'Catalyst::Model::DBIxResultSet';
    
    __PACKAGE__->config(
        dsn      => ...,
        username => ...,
        password => ...,
        attr     => { ... },
    );
    
    __PACKAGE__->meta->make_immutable;
    1;

Instead of setting the dsn, etc, you can pass a pre-initialized
L<DBIx::ResultSet::Connector> object:

    __PACKAGE__->config(
        connector => $my_connector,
    );

Then in your controllers:

    my $model = $c->model('DBIxResultSet');
    my $rs = $model->resultset('users');
    $c->stash->{users} = $rs->array_of_hash_rows();

=head1 DESCRIPTION

This class is a Catalyst Model that wraps around L<DBIx::ResultSet>.

=cut

extends 'Catalyst::Model';

use DBIx::ResultSet;

=head1 ATTRIBUTES

All attributes are typically set using the __PACKAGE__->config() paradigm as
outlined in the L</SYNOPSIS>.

=head2 dsn

The DSN for connecting to a database.  See L<DBI> for more information on
what DSNs look like.  This attribute it required unless you directly set the
L</connector> attribute.

=cut

has dsn => (
    is       => 'ro',
    isa      => 'Str',
);

=head2 username

The username to access your database with.

=cut

has username => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

=head2 password

The password to access your database with.

=cut

has password => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

=head2 attr

A hash ref of attributes.  See L<DBI> for valid attributes.

=cut

has attr => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

=head2 connector

The L<DBIx::ResultSet::Connector> object.  This defaults to a new
connector using the dsn, username, password, and attr attributes.

=cut

has connector => (
    is         => 'ro',
    isa        => 'DBIx::ResultSet::Connector',
    lazy_build => 1,
    handles => [qw(
        resultset
        format_datetime
        format_date
        format_time
    )],
);
sub _build_connector {
    my ($self) = @_;

    # The dsn is required if a connector is being built for you.
    die 'A dsn is require for your ' . ref($self) if !$self->dsn();

    return DBIx::ResultSet->connect(
        $self->dsn(),
        $self->username(),
        $self->password(),
        $self->attr(),
    );
}

=head1 MEHTODS

=head2 resultset

    my $users = $model->resultset('users');

See L<DBIx::ResultSet::Connector/resultset>.

=head2 format_datetime

    my $date_time = $model->format_datetime( DateTime->now() );

See L<DBIx::ResultSet::Connector/format_datetime>.

=head2 format_date

    my $date = $model->format_date( DateTime->now() );

See L<DBIx::ResultSet::Connector/format_date>.

=head2 format_time

    my $time = $model->format_time( DateTime->now() );

See L<DBIx::ResultSet::Connector/format_time>.

=cut

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

