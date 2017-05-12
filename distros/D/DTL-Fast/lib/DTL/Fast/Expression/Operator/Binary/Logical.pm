package DTL::Fast::Expression::Operator::Binary::Logical;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Expression::Operator::Binary';

use DTL::Fast::Utils qw(as_bool);

#@Override
sub render
{
    my( $self, $context ) = @_;
    
    return $self->dispatch( 
        as_bool($self->{'a'}->render($context, 1))
        , $context 
    );
}

sub get_b
{
    my( $self, $context) = @_;
    return as_bool($self->{'b'}->render($context, 1));
}

1;