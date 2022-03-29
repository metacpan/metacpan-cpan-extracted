package App::SpamcupNG::Summary::Receiver;
use warnings;
use strict;
use parent qw(Class::Accessor);
use Hash::Util 'lock_hash';
use Carp 'confess';

use App::SpamcupNG::Summary;

our $VERSION = '0.015'; # VERSION

=pod

=head1 NAME

App::SpamcupNG::Summary::Receiver - representation of a SPAM report receiver

=head1 DESCRIPTION

This class was created to facilitate the handling of submitted SPAM reports for
the interested parties. Sometimes a party doesn't actually receive a report and
that is expected by design.

=head1 ATTRIBUTES

=over

=item email: the "e-mail" of the report

=item report_id: the ID of the sent report

=back

Sometimes a SPAM report is not sent to an e-mail address, Spamcop calls that
"devnull'ing": the report is just stored for statistical reasons, no real
e-mail address receive the report.

In those cases, only the indication of the domain that would receive the SPAM
report is stored, without a report sent ID (actually this ID exists, but the
web interface does not exports that info).

=cut

# TODO: follow best practice
my @fields = ( 'email', 'report_id' );
__PACKAGE__->mk_ro_accessors(@fields);

=head1 METHODS

=head2 new

Creates a new instance.

Expects as parameter a array reference, where the first index is the "email"
and the second the SPAM report sent ID.

The first parameter cannot be C<undef>, while the second is acceptabled.

=cut

sub new {
    my ( $class, $attribs_ref ) = @_;
    confess 'Expects an array reference as parameter'
        unless ( ref($attribs_ref) eq 'ARRAY' );
    confess 'email cannot be undef' unless ( $attribs_ref->[0] );

    my $self = {
        report_id => $attribs_ref->[1],
        email     => $attribs_ref->[0],
    };

    bless $self, $class;
    lock_hash( %{$self} );
    return $self;
}

=head2 as_text

Returns the receiver attributes as strings, separated by commas.

If some of attributes are C<undef>, the string C<not avaialable> will be used
instead.

=cut

sub as_text {
    my $self = shift;
    my @dump;
    push( @dump, $self->{email} );
    push( @dump, ( $self->{report_id} || App::SpamcupNG::Summary->na ) );
    return join( ',', @dump );
}

=head2 is_devnulled

Returns true (1) if the receiver was stored for statistics only or if it was
indeed reported to a domain, false (0) otherwise.

=cut

sub is_devnulled {
    my $self = shift;
    return defined( $self->{report_id} ) ? 0 : 1;
}

=head1 SEE ALSO

=over

=item *

L<Class::Accessor>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 of Alceu Rodrigues de Freitas Junior,
E<lt>arfreitas@cpan.orgE<gt>

This file is part of App-SpamcupNG distribution.

App-SpamcupNG is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

App-SpamcupNG is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
App-SpamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
