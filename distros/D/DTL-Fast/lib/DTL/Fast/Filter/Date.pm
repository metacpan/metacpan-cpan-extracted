package DTL::Fast::Filter::Date;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'date'} = __PACKAGE__;

use DTL::Fast::Utils;

#@Override
#@todo make pre-defined formats from Django
sub parse_parameters
{
    my $self = shift;
    push @{$self->{'parameter'}}, DTL::Fast::Variable->new('"DATE_FORMAT"')
        if not scalar @{$self->{'parameter'}};
    $self->{'format'} = $self->{'parameter'}->[0];
    return $self;
}

#@Override
sub filter
{
    my $self = shift;  # self
    shift;  # filter_manager
    my $value = shift;
    my $context = shift;
    
    my $format = $self->{'format'}->render($context);
    
    return DTL::Fast::Utils::time2str_php($format, $value);
}

1;