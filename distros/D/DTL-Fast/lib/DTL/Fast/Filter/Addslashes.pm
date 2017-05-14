package DTL::Fast::Filter::Addslashes;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{addslashes} = __PACKAGE__;

#@Override
sub filter
{
    shift;  # self
    shift;  # filter_manager
    my $value = shift;
    $value =~ s/(?<!\\)(["'])/\\$1/gs;
    return $value;
}

1;