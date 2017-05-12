package DTL::Fast::Filter::Numberformat;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'numberformat'} = __PACKAGE__;

#@Override
sub filter
{
    my( $self, $filter_manager, $value, $context) = @_;

    die $self->get_render_error($context, 'unable to numberformat undef value')
        if not defined $value;
    
    my @num = split /\./, $value;
    $num[0] =~ s/
        (\d)(?=
            (\d{3})+(?!\d)
        )
        /$1 /gsx;
    
    return join '.', @num;
}

1;