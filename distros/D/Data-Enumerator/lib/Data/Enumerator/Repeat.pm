package Data::Enumerator::Repeat;
use strict;
use warnings;
use base qw/Data::Enumerator::Base/;

sub iterator {
    my ($self) = @_;
    my $object_iterator = $self->object->iterator;
    my $repeated_iterator;
    $repeated_iterator = sub {
        my $value = $object_iterator->();
        if ( $self->is_last($value) ) {
            $object_iterator = $self->object->iterator;
            return $repeated_iterator->();
        }
        return $value;
    };
    return $repeated_iterator;
}
1;
