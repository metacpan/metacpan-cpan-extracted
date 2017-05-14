package DTL::Fast::Tag::Debug;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{debug} = __PACKAGE__;

#@Override
sub render
{
    my $self = shift;
    my $context = shift;

    require Data::Dumper;
    my $result = Data::Dumper->Dump([ $context ], [ 'context' ]);

    return $result;
}

1;