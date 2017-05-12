package DTL::Fast::Filter::Default;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'default'} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no default value specified")
        if not scalar @{$self->{'parameter'}};
    $self->{'default'} = $self->{'parameter'}->[0];
    return $self;
}

#@Override
sub filter
{
    my ($self, $filter_manager, $value, $context) = @_;
    
    return $value || $self->{'default'}->render($context);
}

1;