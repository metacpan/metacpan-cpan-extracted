package DBIx::Schema::Changelog::Actions;

=head1 NAME

DBIx::Schema::Changelog::Action - Abstract action class.

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use strict;
use warnings;
use Moose;
use MooseX::HasDefaults::RO;

use DBIx::Schema::Changelog::Action::Columns;
use DBIx::Schema::Changelog::Action::Constraint::ForeignKeys;
use DBIx::Schema::Changelog::Action::Constraint::PrimaryKeys;
use DBIx::Schema::Changelog::Action::Constraint::Uniques;
use DBIx::Schema::Changelog::Action::Indices;
use DBIx::Schema::Changelog::Action::Sequences;
use DBIx::Schema::Changelog::Action::Sql;
use DBIx::Schema::Changelog::Action::Tables;
use DBIx::Schema::Changelog::Action::Views;

=head1 ATTRIBUTES

=head2 constraints

Connected dbh object.

=cut

has constraints => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Constraints->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=head2 dbh

Connected dbh object.

=cut

has dbh => ();

=head2 driver

    Loaded DBIx::Schema::Changelog::Role::Driver module.

=cut

has driver => ();

=head2 entries

Connected dbh object.

=cut

has entries => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Entries->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=head2 foreigns

Connected dbh object.

=cut

has foreigns => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Constraint::ForeignKeys->new(
            dbh    => $self->dbh,
            driver => $self->driver
        );
    },
);

=head2 functions

Connected dbh object.

=cut

has functions => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Functions->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=head2 indices

Connected dbh object.

=cut

has indices => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Indices->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=head2 primaries

Connected dbh object.

=cut

has primaries => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Constraint::PrimaryKeys->new(
            dbh    => $self->dbh,
            driver => $self->driver
        );
    },
);

=head2 sequences

Connected dbh object.

=cut

has sequences => (
    is      => 'rw',
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Sequences->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=head2 sql

Connected dbh object.

=cut

has sql => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Sql->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=head2 tables

Connected dbh object.

=cut

has tables => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Tables->new(
            dbh    => $self->dbh,
            driver => $self->driver
        );
    },
);

=head2 trigger

Connected dbh object.

=cut

has trigger => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Trigger->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=head2 uniques

Connected dbh object.

=cut

has uniques => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Constraint::Uniques->new(
            dbh    => $self->dbh,
            driver => $self->driver
        );
    },
);

=head2 views

Connected dbh object.

=cut

has views => (
    lazy    => 1,
    does    => 'DBIx::Schema::Changelog::Role::Action',
    default => sub {
        my $self = shift;
        DBIx::Schema::Changelog::Action::Views->new(
            driver => $self->driver(),
            dbh    => $self->dbh()
        );
    },
);

=head1 SUBROUTINES/METHODS

=cut

no Moose;

__PACKAGE__->meta->make_immutable;

1;    # End of DBIx::Schema::Changelog::Role::Actions

__END__

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

