package DTL::Fast::Filter::Cut;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'cut'} = __PACKAGE__;

use DTL::Fast::Variable;


#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no substitute specified for removing")
        if not scalar @{$self->{'parameter'}};
    $self->{'remove'} = $self->{'parameter'}->[0];
    return $self;
}

#@Override
sub filter
{
    my ($self, $filter_manager, $value, $context) = @_;
    
    my $remove = $self->{'remove'}->render($context);
    $value =~ s/\Q$remove\E//gs;
    
    return $value;
}

1;