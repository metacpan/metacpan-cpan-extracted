package DTL::Fast::Expression::Operator::Binary;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Expression::Operator::Unary';

sub new
{
    my ( $proto, $argument1, $argument2, %kwargs ) = @_;
    $kwargs{b} = $argument2;

    my $self = $proto->SUPER::new($argument1, %kwargs);

    return $self;
}

sub render
{
    my ( $self, $context ) = @_;

    return $self->dispatch(
        $self->{a}->render($context, 1)
        , $self->{b}->render($context, 1)
        , $context
    );
}

sub dispatch
{
    my ( $self, $arg1, $arg2 ) = @_;
    die 'Abstract method dispatch was not overriden in subclass '.(ref $self);
}

1;