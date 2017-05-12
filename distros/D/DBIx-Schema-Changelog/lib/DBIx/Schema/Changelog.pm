package DBIx::Schema::Changelog;

=head1 NAME

DBIx::Schema::Changelog - Continuous Database Migration

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

=head1 DESCRIPTION

C<DBIx::Schema::Changelog> is a pure Perl module.

Continuous Database Migration
A package which allows a continuous development with an application that hold the appropriate database system synchronously.

=cut

use utf8;
use strict;
use warnings;

use Moose;
use MooseX::HasDefaults::RO;
use MooseX::Types::Moose qw(ArrayRef Str Defined);
use MooseX::Types::LoadableClass qw(LoadableClass);

use DBIx::Schema::Changelog::Actions;
use DBIx::Schema::Changelog::Read;
use DBIx::Schema::Changelog::Write;

has db_changelog_table => ( isa => Str, default => 'databasechangelog' );
has db_driver          => ( isa => Str, default => 'SQLite' );
has file_type          => ( isa => Str, default => 'Yaml' );
has dbh => ( isa => 'DBI::db', required => 1, );

has actions => (
    lazy    => 1,
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Actions->new(
            driver => $self->driver(),
            dbh    => $self->dbh(),
        );
    },
);

has driver_class => (
    isa     => LoadableClass,
    lazy    => 1,
    default => sub {
        'DBIx::Schema::Changelog::Driver::' . shift->db_driver();
    }
);

has driver => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Driver',
    default => sub { shift->driver_class()->new(); }
);

has reader => (
    lazy    => 1,
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Read->new(
            driver             => $self->driver,
            dbh                => $self->dbh,
            file_type          => $self->file_type,
            db_changelog_table => $self->db_changelog_table,
        );
    }
);

has writer => (
    lazy    => 1,
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Write->new(
            driver             => $self->driver,
            dbh                => $self->dbh,
            file_type          => $self->file_type,
            db_changelog_table => $self->db_changelog_table,
        );
    }
);

=head1 SUBROUTINES/METHODS

=head2 BUILD

Run to check driver version with installed db driver.

Creates changelog table if it's not existing.

=cut

sub BUILD {
    my $self   = shift;
    my $vendor = uc $self->dbh()->get_info(17);
    print STDOUT __PACKAGE__, ". Db vendor $vendor. \n";
    $self->driver()->check_version( $self->dbh()->get_info(18) );
}

=head2 read

Read main changelog file and sub changelog files

=cut

sub read {
    my ( $self, $dir ) = @_;
    my $handle_time = time();
    $self->actions->tables->add( $self->driver()->create_changelog_table( $self->dbh(), $self->db_changelog_table() ) );
    $self->reader->run($dir);
    print STDOUT __PACKAGE__, " Reading: completedin " . ( time() - $handle_time ) . "s.\n";
}

=head2 write

Write main changelog file and sub changelog files

=cut

sub write {
    my ( $self, $dir ) = @_;
    $self->writer->run($dir);
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 Synopsis

    use DBI;
    use DBIx::Schema::Changelog;

    my $dbh = DBI->connect( "dbi:SQLite:database=league.sqlite" );
    DBIx::Schema::Changelog->new( dbh => $dbh )->read( $FindBin::Bin . '/../changelog' );

    ...
    
    my $dbh = DBI->connect( "dbi:Pg:dbname=database;host=127.0.0.1", "user", "password" );
    DBIx::Schema::Changelog->new( dbh => $dbh, db_driver => 'Pg' )->read( $FindBin::Bin . '/../changelog' );

=head1 Motivation

 When working with several people on a large project that is bound to a database.
 If you there and back the databases have different levels of development.

 You can keep in sync with SQL statements, but these are then incompatible with other database systems.

=head1 Constructor and initialization

new(...) returns an object of type C<DBIx::Schema::Changelog>.

This is the class's constructor.

Usage: DBIx::Schema::Changelog -> new().

This method takes a set of parameters. Only the dbh parameter is mandatory.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

=over 4

=item dbh

This is a database handle, returned from DBI's connect() call.

This parameter is mandatory.

There is no default.

=item verbose

=back

=head1 Method: read()

=over 4

=item path to changelog folder


=back

=head1 SEE ALSO

=head2 L<DBIx::Admin::CreateTable>

=over 4

The package from which the idea originated.

=back

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

