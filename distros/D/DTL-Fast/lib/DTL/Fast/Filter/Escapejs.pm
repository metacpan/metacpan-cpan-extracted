package DTL::Fast::Filter::Escapejs;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{escapejs} = __PACKAGE__;

our $CHARMAP = {
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
    "\0" => '\0',
    "\'" => '\'',
    "\"" => '\"',
};

#@Override
sub filter
{
    shift;  # self
    my $filter_manager = shift;  # filter_manager
    my $value = shift;  # value
    shift;  # context

    $filter_manager->{safe} = 1;
    $value =~ s/([\n\r\t\0'"])/$CHARMAP->{$1}/gs;

    return $value;
}

1;