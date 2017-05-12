package DTL::Fast::Tag::Autoescape;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag';  

$DTL::Fast::TAG_HANDLERS{'autoescape'} = __PACKAGE__;

#@Override
sub get_close_tag{ return 'endautoescape';}

#@Override
sub parse_parameters
{
    my $self = shift;
    
    if( $self->{'parameter'} eq 'on' )
    {
        $self->{'safe'} = 0;
    }
    elsif( $self->{'parameter'} eq 'off' )
    {
        $self->{'safe'} = 1;
    }
    else
    {
        die $self->get_parse_error("autoescape tag undertands only `on` and `off` parameters");
    }
    return $self;
}

#@Override
sub render
{
    my $self = shift;
    my $context = shift;

    $context->push_scope()->set('_dtl_safe' => $self->{'safe'}); 
    my $result = $self->SUPER::render($context);
    $context->pop_scope();
    
    return $result;
}

1;