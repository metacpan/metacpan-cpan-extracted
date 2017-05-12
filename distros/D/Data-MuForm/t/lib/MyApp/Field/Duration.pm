package MyApp::Field::Duration;

use Moo;
extends 'Data::MuForm::Field::Compound';
use Data::MuForm::Meta;
use DateTime;

=head1 SubFields

Subfield names:

  years, months, weeks, days, hours, minutes, seconds, nanoseconds

For example:

   has_field 'duration'         => ( type => 'Duration' );
   has_field 'duration.hours'   => ( type => 'Hour' );
   has_field 'duration.minutes' => ( type => 'Minute' );

Customize error message 'duration_invalid' (default 'Invalid value for [_1]: [_2]')

=cut

our $class_messages = {
    'duration_invalid' => 'Invalid value for {field_label}: {child_label}',
};

sub get_class_messages  {
    my $self = shift;
    return {
        %{ $self->next::method },
        %$class_messages,
    }
}


sub validate {
    my ($self) = @_;

    my @dur_parms;
    foreach my $child ( $self->all_fields ) {
        unless ( $child->has_value && $child->value =~ /^\d+$/ ) {
            $self->add_error( $self->get_message('duration_invalid'), field_label => $self->loc_label, child_label => $child->loc_label );
            next;
        }
        push @dur_parms, ( $child->accessor => $child->value );
    }

    # set the value
    my $duration = DateTime::Duration->new(@dur_parms);
    $self->value($duration);
}

1;

