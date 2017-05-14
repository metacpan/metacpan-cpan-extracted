package DTL::Fast::Filter::Title;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{title} = __PACKAGE__;

use locale;

#@Override
sub filter
{
    shift;  # self
    shift;  # filter_manager
    my $value = lc(shift); # value

    $value =~ s/\b(.)/\U$1/gs;

    return $value;
}

1;