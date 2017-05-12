package DTL::Fast::Filter::DefaultIfNone;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter::Default';

$DTL::Fast::FILTER_HANDLERS{'default_if_none'} = __PACKAGE__;

#@Override
sub filter
{
    my $self = shift;  # self
    shift;  # filter_manager
    my $value = shift;
    my $context = shift;
    
    return $value // $self->{'default'}->render($context);
}

1;