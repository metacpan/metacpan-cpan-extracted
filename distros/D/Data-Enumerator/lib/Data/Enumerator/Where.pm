package Data::Enumerator::Where;
use strict;
use warnings;
use List::MoreUtils qw/all natatime/;
use base qw/Data::Enumerator::Base/;

sub iterator {
    my ( $self ) = @_;
    my ($object,$filter ) = @{$self->object};
    my $object_iterator = $object->iterator;
    return sub{
        while(1){
            my $value = $object_iterator->();
            return $self->LAST if $self->is_last( $value );
            my $result = $filter->($value);
            return $self->LAST if $self->is_last( $result );
            return $value if $result;
        }
    };
}

sub __compose_filter {
    my ( $filter ) = @_;
    return $filter if ref $filter eq 'CODE';
    my $iter = natatime(2,@$filter);
    my @funcs;
    while( my ( $column , $expression ) = $iter->() ){
        my $sub = sub {
            my $value = shift;
            my $target = $value->{$column};
            return ($target == $expression );
        };
        push @funcs,$sub;
    }
    return sub {
        my @request = @_;
        all{ $_->(@request)} @funcs
    }
}
1;

