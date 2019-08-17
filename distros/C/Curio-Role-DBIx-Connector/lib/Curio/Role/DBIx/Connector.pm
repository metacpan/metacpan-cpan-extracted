package Curio::Role::DBIx::Connector;
our $VERSION = '0.02';

use DBIx::Connector;
use Scalar::Util qw( blessed );
use Types::Standard qw( InstanceOf ArrayRef );

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Curio::Role';

after initialize => sub{
    my ($class) = @_;

    my $factory = $class->factory();

    $factory->does_caching( 1 );
    $factory->resource_method_name( 'connector' );

    return;
};

has _custom_connector => (
    is       => 'ro',
    isa      => InstanceOf[ 'DBIx::Connector' ] | ArrayRef,
    init_arg => 'connector',
    clearer  => '_clear_custom_connector',
);

has connector => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build_connector {
    my ($self) = @_;

    my $connector = $self->_custom_connector();
    $self->_clear_custom_connector();
    return $connector if blessed $connector;

    return DBIx::Connector->new( @$connector ) if $connector;

    my $dsn        = $self->dsn();
    my $username   = $self->can('username') ? $self->username() : '';
    my $password   = $self->can('password') ? $self->password() : '';
    my $attributes = $self->can('attributes') ? $self->attributes() : {};

    return DBIx::Connector->new(
        $dsn,
        $username,
        $password,
        {
            AutoCommit => 1,
            %$attributes,
        },
    );
}

1;
__END__

=encoding utf8

=head1 NAME

Curio::Role::DBIx::Connector - Build Curio classes around DBIx::Connector.

=head1 SYNOPSIS

Create a Curio class:

    package MyApp::Service::DB;
    
    use MyApp::Config;
    use MyApp::Secrets;
    
    use Curio role => '::DBIx::Connector';
    use strictures 2;
    
    key_argument 'connection_key';
    export_function_name 'myapp_db';
    always_export;
    export_resource;
    
    add_key 'writer';
    add_key 'reader';
    
    has connection_key => (
        is       => 'ro',
        required => 1,
    );
    
    sub dsn {
        my ($self) = @_;
        return myapp_config()->{db}->{ $self->connection_key() }->{dsn};
    }
    
    sub username {
        my ($self) = @_;
        return myapp_config()->{db}->{ $self->connection_key() }->{username};
    }
    
    sub password {
        my ($self) = @_;
        return myapp_secret( $self->connection_key() . '_' . $self->username() );
    }
    
    1;

Then use your new Curio class elsewhere:

    use MyApp::Service::DB;
    
    my $db = myapp_db('writer');
    
    $db->run(sub{
        my ($one) = $_->selectrow_array( 'SELECT 1' );
    });

=head1 DESCRIPTION

This role provides all the basics for building a Curio class which
wraps around L<DBIx::Connector>.

=head1 OPTIONAL ARGUMENTS

=head2 connector

Holds the L<DBIx::Connector> object.

May be passed as either ain arrayref of arguments or a pre-created
object.  If this argument is not set then it will be built from L</dsn>,
L</username>, L</password>, and L</attributes>.

=head1 REQUIRED METHODS

These methods must be implemented in your Curio class.

=head2 dsn

This method must return a L<DBI> C<$dsn>/C<$data_source>, such as
C<dbi:SQLite:dbname=:memory:>.

=head1 OPTIONAL METHODS

These methods may be implemented in your Curio class.

=head2 username

If this method is not present then an empty string will be used for
the username when the L</connector> is built.

=head2 password

If this method is not present then an empty string will be used for
the passord when the L</connector> is built.

=head2 attributes

If this method is not present then an empty hashref will be used for
the attributes when the L</connector> is built.

    sub attributes {
        return { SomeAttribute => 3 };
    }

Note what L</AUTOCOMMIT> says.

=head1 AUTOCOMMIT

The C<AutoCommit> L<DBI> attribute is defaulted to C<1>.  You can
override this in L</attributes>.

If the L</connector> argument is set then this defaulting of
C<AutoCommit> is skipped.

=head1 FEATURES

This role turns on L<Curio::Factory/does_caching> and sets
L<Curio::Factory/resource_method_name> to C<connector> (as in
L</connector>).

You can of course revert these changes:

    does_caching 0;
    resource_method_name undef;

=head1 SUPPORT

Please submit bugs and feature requests to the
Curio-Role-DBIx-Connector GitHub issue tracker:

L<https://github.com/bluefeet/Curio-Role-DBIx-Connector/issues>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/> for
encouraging their employees to contribute back to the open source
ecosystem.  Without their dedication to quality software development
this distribution would not exist.

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

