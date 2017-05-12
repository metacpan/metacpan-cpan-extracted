#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';

{package MyApp::Foo::Fail;
 use Moose;
 extends 'Test1::Base::Foo';
}
package main;

my $comp = MyApp::Foo::Fail->new();
ok($comp,'bad component can be instantiated');
throws_ok { $comp->expand_modules('',{}) }
    qr{\Athe 'routes' method needs to be implemented in class MyApp::Foo::Fail\Z},
    'but it dies calling expand_modules';

done_testing();
