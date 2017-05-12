=head1 NAME

Data::ICal::TimeZone::Object - base class for Data::ICal::TimeZone timezone objects

=head1 METHODS

=over

=item timezone

Returns the timezone identifier for the current zone object

=item definition

Returns a Data::ICal::Entry::TimeZone which defines the given zone.

=back

=HEAD1 SEE ALSO

L<Data::ICal::TimeZone>

=cut

package Data::ICal::TimeZone::Object;
use strict;
use base qw( Class::Singleton Class::Accessor );
__PACKAGE__->mk_accessors(qw( _cal ));
use Data::ICal;

sub new {
    my $self = shift;
    return $self->instance;
}

sub definition {
    my $self = shift;
    my @zones = grep {
        $_->ical_entry_type eq 'VTIMEZONE'
    } @{ $self->_cal->entries };
    return $zones[0];
}

sub timezone {
    my $self = shift;
    return $self->definition->property('tzid')->[0]->value;
}

sub _load {
    my $self = shift;
    my $ics = shift;
    my $cal = Data::ICal->new( data => $ics );
    $self->_cal( $cal );
    return;
}

1;
