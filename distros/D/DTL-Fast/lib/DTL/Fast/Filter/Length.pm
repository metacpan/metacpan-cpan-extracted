package DTL::Fast::Filter::Length;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'length'} = __PACKAGE__;

#@Override
sub filter
{
    shift;  # self
    shift;  # filter_manager
    my $value = shift;  # value
    shift;  # context

    if( ref $value eq 'ARRAY' )
    {
        $value = scalar @$value;
    }
    else
    {
        $value = length( $value // '' );
    }
    
    return $value;
}

1;
