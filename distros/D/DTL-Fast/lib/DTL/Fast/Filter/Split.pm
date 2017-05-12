package DTL::Fast::Filter::Split;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'split'} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no split pattern specified")
        if not scalar @{$self->{'parameter'}};
    $self->{'pattern'} = $self->{'parameter'}->[0];
    return $self;
}

#@Override
sub filter
{
    my($self, $filter_manager, $value, $context ) = @_;
    
    my $pattern = $self->{'pattern'}->render($context);
    
    die $self->get_render_error("splitting pattern must be defined and not empty")
        if not $pattern;
        
    $value = [split /$pattern/si, $value // ''];
    
    return $value;
}

1;
