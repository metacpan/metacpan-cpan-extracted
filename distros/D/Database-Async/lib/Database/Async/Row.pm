package Database::Async::Row;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

=head1 NAME

Database::Async::Row - represents a single row response

=head1 DESCRIPTION


=cut

=head1 METHODS

=cut

=head2 new

=cut

sub new {
    my $self = shift;
    bless { @_ }, $self
}

=head2 field

=cut

sub field {
    my ($self, $name) = @_;
    $self->{data}[$self->{index_by_name}{$name} // die 'unknown field ' . $name]->{data}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >>

=head1 LICENSE

Copyright Tom Molesworth 2011-2020. Licensed under the same terms as Perl itself.

