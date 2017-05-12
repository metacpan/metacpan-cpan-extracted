package DTL::Fast::Filter::Linenumbers;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{'linenumbers'} = __PACKAGE__;

#@Override
sub filter
{
    shift;  # self
    shift;  # filter_manager
    my $value = shift;  # value
    shift;  # context

    
    my $counter = 1;
    my $nextcounter = sub{
        return $counter++.". ";
    };

    $value =~ s/^/$nextcounter->()/gme;
    
    return $value;
}

1;