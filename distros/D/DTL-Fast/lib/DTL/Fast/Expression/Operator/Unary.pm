package DTL::Fast::Expression::Operator::Unary;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Entity';

use DTL::Fast::Template;

sub new
{
    my ( $proto, $argument, %kwargs ) = @_;
    $kwargs{a} = $argument;

    return $proto->SUPER::new(%kwargs);
}

sub render
{
    my ( $self, $context) = @_;

    return $self->dispatch(
        $self->{a}->render($context, 1)
        , $context
    );
}

sub dispatch
{
    my ( $self, $arg1 ) = @_;
    die 'Abstract method dispatch was not overriden in subclass '.(ref $self);
}
1;