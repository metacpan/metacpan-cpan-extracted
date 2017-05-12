
package DBIx::BlackBox::Driver::Sybase;

use Moose;
use namespace::autoclean;

extends qw( DBIx::BlackBox::Driver );

=encoding utf8

=head1 NAME

DBIx::BlackBox::Driver::Sybase - Sybase database driver.

=cut

our $VERSION = '0.01';

has '+_result_types' => (
    default => sub {
        +{
            4043 => 'status_result',
            4040 => 'row_result',
        }
    }
);

=head1 METHODS

=head2 result_type

Returns type of given database statement.

=cut

sub result_type {
    my ($self, $sth) = @_;

    return $self->_result_types->{ $sth->{syb_result_type} } || '';
}

=head2 has_more_result_sets

Returns true if there are more resultsets for given statement.

=cut

sub has_more_result_sets {
    my ($self, $sth) = @_;

    return $sth->{syb_more_results};
}

=head2 columns

Returns names of the columns for the statement.

=cut

sub columns {
    my ($self, $sth) = @_;

    return map { $_->{NAME} } $sth->syb_describe;
}

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

