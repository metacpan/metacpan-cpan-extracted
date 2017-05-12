package DTL::Fast::Filter::Truncatewordshtml;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter::Truncatewords';

$DTL::Fast::FILTER_HANDLERS{'truncatewords_html'} = __PACKAGE__;

#@Override
sub filter
{
    my $self = shift;  # self
    my $filter_manager = shift;  # filter_manager
    my $value = shift;
    my $context = shift;
    
    my @splitted = split /(<[^>]+?>)/s, $value;

    foreach my $value (@splitted)
    {
        if( $value !~ /^(<[^>]+?>|\s*)$/gs )
        {
            $value = $self->SUPER::filter($filter_manager, $value, $context);
            last;
        }
    }
    
    return join '', @splitted;
}

1;