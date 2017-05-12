package Data::Enumerator::Mapper;
use strict;
use warnings;
use List::MoreUtils qw/zip/;
use base qw/Data::Enumerator::Base/;

sub iterator {
    my ( $self ) = @_;
    my ($object,$mapper ) = @{$self->object};
    my $mapper_func = __compose_mapper($mapper);
    my $object_iter = $object->iterator;
    return sub{
        my $value = $object_iter->();
        return $self->LAST if $self->is_last( $value );
        return $mapper_func->( $value );
    }
}

sub __compose_mapper{
    my ( $mapper ) = @_;
    return $mapper if ref $mapper eq 'CODE';
    return sub{
        my ( $value ) = @_;
        return +{ 
            zip @$mapper,@$value
        }
    }
}
1;
