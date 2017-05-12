package Data::Enumerator::Base;
use strict;
use warnings;
use Scalar::Util qw/blessed/;
use constant LAST => bless {},'Data::Enumerator::Base::LAST';

sub new {
    my ( $class,$object) = @_;
    return bless {
        object => $object,
    },$class;
}

sub object {
    shift->{object}
}

sub is_last {
    return (ref $_[1] and ref $_[1] eq 'Data::Enumerator::Base::LAST');
}


sub iterator {
    my ( $self ) = @_;
    my $count = 0;
    return sub{
        return LAST if ($count >= scalar( @{$self->object}));
        $self->object->[$count++];
    };
}

sub each {
    my ( $self,$f) = @_;
    my $iter = $self->iterator;
    while(1){
        my $result = $iter->();
        last if( $self->is_last( $result ));
        my $value = $f->( $result );
        last if( $self->is_last( $value ));
    }
}

sub select {
    my ( $self,$mapper ) = @_;
    require Data::Enumerator::Mapper;
    return Data::Enumerator::Mapper->new([$self,$mapper]);
}

sub where {
    my ( $self,$predicate ) = @_;
    require Data::Enumerator::Where;
    return Data::Enumerator::Where->new([$self,$predicate]);
}

sub take {
    my ( $self,$num ) = @_;
    return $self->limit(0,$num);
}

sub take_while {
    my ( $self, $predicate ) = @_;
    my $flag = 1;
    return $self->where(
        sub {
            return $self->LAST unless $flag;
            my $result =  $predicate->(@_);
            $flag = 0 unless $result;
            return $result;
        }
    );
}

sub skip_while {
    my ( $self, $predicate ) = @_;
    my $flag = 1;
    return $self->where(
        sub {
            return 1 unless $flag;
            my $result = not $predicate->(@_);
            $flag = 0 if $result;
            return $result;
        }
    );
}
sub repeat {
    my ($self) = @_;
    require Data::Enumerator::Repeat;
    return Data::Enumerator::Repeat->new($self);
}

sub to_array {
    return [ shift->list ];
}

sub limit {
    my ( $self,$offset,$limit ) = @_;
    require Data::Enumerator::Limit;
    return Data::Enumerator::Limit->new([$self,$offset,$limit]);
}

sub add {
    my ( $self ,$generator ) = @_;
    require Data::Enumerator::Add;
    return Data::Enumerator::Add->new([$self,$generator]);
}

sub product {
    my ( $self,$generator) = @_;
    require Data::Enumerator::Product;
    return Data::Enumerator::Product->new([$self,$generator]);
}

sub list {
    my ( $self ) = @_;
    my @list;
    $self->each(sub{
        push @list ,shift;
    });
    return @list;
}

1;
