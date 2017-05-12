package Data::Enumerator::Deeply;
use strict;
use warnings;
use Data::Enumerator::Base;
use Data::Visitor::Lite;
{
    package Data::Enumerator::Deeply::_Swap;
    sub new {
        my ( $class,$id ) = @_;
        return bless \$id , $class;
    }
    sub value {
        my ( $self,$value ) = @_;
        return $value->[$self->id];
    }
    sub id{
        my ( $self ) = @_;
        $$self;
    }
}
{
    package Data::Enumerator::Deeply::_Fixed;
    use base qw/Data::Enumerator::Deeply::_Swap/;
    sub new {
        my ( $class,$generator ) = @_;
        return bless { generator => $generator } , $class;
    }
    sub _generator{
        shift->{generator};
    }
    sub value {
        my $value = shift->_iterator->();
        return if Data::Enumerator::Base->is_last($value);
        return $value;
    }
    sub _iterator {
        my ($self ) = @_;
        return $self->{_iterator} ||= $self->_generator->iterator;
    }
}
sub independ {
    return Data::Enumerator::Deeply::_Fixed->new($_[0]);
}

sub __swapper {
    my ( $id ) = @_;
    return Data::Enumerator::Deeply::_Swap->new($id);
}

sub __product_all {
    my ( @generators ) = @_;
    my $result = shift @generators;
    while( my $gen = shift @generators ) {
        $result = $result->product($gen);
    }
    return $result;
}

sub compose {
    my ( $class,    $struct ) = @_;
    my ( $template, $object ) = __get_template_and_generator($struct);
    return $object->select(sub{
        my $value = shift;
        __convert_by_template( $template,$value );
    });
}

sub __get_template_and_generator{
    my ( $struct ) = @_;
    my @generators;
    my $count = 0;
    my $v     = Data::Visitor::Lite->new(
        ['-instance' => 'Data::Enumerator::Base'=> sub {
            my ($obj) = @_;
            push @generators,$obj;
            return __swapper( $count++);
        }]
    );
    my $template  = $v->visit( $struct );
    my $producted = __product_all(@generators);
    return ($template,$producted);
}

sub __convert_by_template {
    my ( $template, $value ) = @_;
    my $v = Data::Visitor::Lite->new(
        [   -instance => 'Data::Enumerator::Deeply::_Swap' => sub {
                my ($obj ) = @_;
                return $obj->value($value);
                }
        ]
    );
    return $v->visit($template);
}

1;
