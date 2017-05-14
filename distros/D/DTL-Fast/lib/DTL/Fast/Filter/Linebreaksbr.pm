package DTL::Fast::Filter::Linebreaksbr;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{linebreaksbr} = __PACKAGE__;

#@Override
sub filter
{
    shift;  # self
    my $filter_manager = shift;  # filter_manager
    my $value = shift;  # value
    shift;  # context

    $filter_manager->{safe} = 1;
    $value =~ s/\n/<br \/>\n/gsi;

    return $value;
}

1;