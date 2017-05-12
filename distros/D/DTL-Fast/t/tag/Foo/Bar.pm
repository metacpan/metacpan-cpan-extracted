package Foo::Bar;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{'foobar'} = __PACKAGE__;

#@Override
sub render
{
    my $self = shift;
    my $context = shift;
    
    return 'FooBar was here!';
}

1;