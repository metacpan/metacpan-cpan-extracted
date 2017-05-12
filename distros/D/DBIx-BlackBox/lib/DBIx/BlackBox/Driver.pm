
package DBIx::BlackBox::Driver;

use Moose;
use namespace::autoclean;

=encoding utf8

=head1 NAME

DBIx::BlackBox::Driver - base class for database drivers.

=cut

our $VERSION = '0.01';

=head1 ATTRIBUTES

=head2 connector

Database connector.

isa: L<DBIx::Connector>.

=cut

has 'connector' => (
    is => 'rw',
    isa => 'DBIx::Connector',
);

has '_result_types' => (
    is => 'ro',
    isa => 'HashRef[Str]',
);

=head1 AUTHOR

Alex J. G. Burzyński, E<lt>ajgb at cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alex J. G. Burzyński.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;

