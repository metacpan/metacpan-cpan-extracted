package Database::Temp;
## no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;

# ABSTRACT: Create an ad-hoc database which drops itself automatically

our $VERSION = '0.003'; # VERSION: generated by DZP::OurPkgVersion

use Module::Load qw( load );
use Carp         qw{ croak };

use UUID::Tiny qw{ create_uuid_as_string UUID_V1 };
use Data::GUID;
use Const::Fast;
use Try::Tiny;

use Database::Temp::DB ();

const my $SHORT_UUID_LEN        => 8;
const my $DEFAULT_BASENAME      => 'database_temp_';
const my $DEFAULT_CLEANUP       => 1;
const my $DEFAULT_INIT_METHOD   => sub { };
const my $DEFAULT_DEINIT_METHOD => sub { };

sub new {
    my ( $class, %params ) = @_;

    # Load driver module
    my $driver_module = _driver_module( $params{'driver'} );
    load $driver_module;

    if ( !$driver_module->is_available() ) {
        croak "Driver $driver_module not available";
    }

    # Create db name
    my $basename = $DEFAULT_BASENAME;
    if ( defined $params{'basename'} ) {
        croak "Invalid temp database basename '${ \$params{'basename'} }'"
          unless $params{'basename'} =~ m/[[:alnum:]_]{1,}/msx;
        $basename = $params{'basename'};
    }
    my $name = $basename . random_name();
    if ( defined $params{'name'} ) {
        $name = $basename . $params{'name'};
    }

    my $cleanup = $DEFAULT_CLEANUP;
    if ( defined $params{'cleanup'} ) {
        croak "Invalid value for parameter cleanup '${ \$params{'cleanup'} }'"
          unless $params{'cleanup'} =~ m/^[10]$/msx;
        $cleanup = $params{'cleanup'};
    }

    my $init = $DEFAULT_INIT_METHOD;
    if ( defined $params{'init'} ) {
        croak if ( ref $params{'init'} !~ m/(?: SCALAR|CODE)/msx );
        $init = $params{'init'};
    }
    my $deinit = $DEFAULT_DEINIT_METHOD;
    if ( defined $params{'deinit'} ) {
        croak if ( ref $params{'deinit'} !~ m/(?: SCALAR|CODE)/msx );
        $deinit = $params{'deinit'};
    }

    my $args = defined $params{'args'} ? $params{'args'} : {};

    return $driver_module->new(
        name    => $name,
        cleanup => $cleanup,
        init    => $init,
        deinit  => $deinit,
        args    => $args,
    );
}

sub is_available {
    my ( $class, %params ) = @_;

    return 0 if ( !$params{'driver'} );

    # Load driver module
    my $driver_module = _driver_module( $params{'driver'} );
    my $can_load;
    try {
        load $driver_module;
        $can_load = 1;
        1;
    }
    catch {
        $can_load = 0;
    };
    return 0 if ( !$can_load );

    return $driver_module->is_available();
}

sub _driver_module {
    return "${ \__PACKAGE__ }::Driver::$_[0]";
}

sub random_name {
    return ( substr Data::GUID->new, 0, $SHORT_UUID_LEN );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Database::Temp - Create an ad-hoc database which drops itself automatically

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use DBI;
    my $db = Database::Temp->new(
        driver => 'SQLite',
    );
    my $dbh = DBI->connect( $db->connection_info );
    my $rows = $dbh->selectall_arrayref(
        "SELECT 1, 1+2",
    );

=head1 DESCRIPTION

With Database::Temp you can quickly create a temporary database
and be sure it gets removed automatically when your reference to it
is deleted, normally when the scope ends.

=head2 new

Create a temporary database.

=head3 Parameters

=over 8

=item driver

Available drivers: SQLite. No default value.

=item basename

=item name

The full name of a database consists of two parts:
basename and name. By default the basename is "database_temp_"
and name is a random string of eight letters and numbers.
You can change both of these if you need to.

=item cleanup

Remove database after use. Default: 1.

=item init

=item deinit

Pointer to an initializing subroutine or just a SQL script.

=item args

Special arguments for the creation of the database.
These are mentioned separately in the equivalent driver documentation.

=back

=head2 is_available

Confirm a driver is available and it can
create a temporary database.

Return boolean

=head3 Parameters

=over 8

=item driver

Available drivers: SQLite. No default value.

=back

=head2 random_name

Generate a random name. A string of 8 random letters and characters.

=head1 STATUS

This module is currently being developed so changes in the API are possible.

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Mikko Johannes Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
