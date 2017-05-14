package DTL::Fast::Filter::Slugify;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{slugify} = __PACKAGE__;

#@Override
#@todo this should translit locales symbols
sub filter
{
    shift;  # self
    shift;  # filter manager
    my $value = shift; # value

    $value =~ s/[^\w]+/-/gs;
    $value =~ s/(^\-+|\-+$)//gs;

    return lc($value);
}

1;