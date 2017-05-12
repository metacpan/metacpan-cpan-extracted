package DTL::Fast::Filter::Truncatechars;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'truncatechars'} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    die $self->get_parse_error("no max string length specified")
        if not scalar @{$self->{'parameter'}};
    $self->{'maxlen'} = $self->{'parameter'}->[0];
    return $self;
}

#@Override
sub filter
{
    my($self, $filter_manager, $value, $context ) = @_;
    
    my $maxlen = $self->{'maxlen'}->render($context);
    if( length $value > $maxlen )
    {
        $value = substr $value, 0, $maxlen;
        $value =~ s/\s*$/.../s;
    }
    
    return $value;
}


1;