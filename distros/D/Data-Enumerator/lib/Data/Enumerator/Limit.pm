package Data::Enumerator::Limit;
use strict;
use warnings;
use base qw/Data::Enumerator::Base/;


sub iterator {
    my ( $self ) = @_;
    my ( $object, $offset, $limit ) = @{ $self->object };
    my $object_iterator = $object->iterator;
    my $current_offset  = 0;
    my $current_limit   = 0;
    return sub {
        while (1) {
            my $value = $object_iterator->();
            next if ( $current_offset++ < $offset );
            return $self->LAST if ( $current_limit++ >= $limit );
            return $value;
        }
    };
}

1;

