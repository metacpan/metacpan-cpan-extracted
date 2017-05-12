#!/usr/bin/env perl
use strict;
use warnings;

{
    package MyApp;
    use Moose;
    use Catalyst;
    no Moose;

    sub _is_this_the_app { 'oh yeah' }
}

{
    package Foo;
    use base qw/Catalyst::Component::ACCEPT_CONTEXT Catalyst::Component/;

    sub new {
        my $class = shift;
        return $class->next::method(@_);
    }
}

use Test::More tests => 4;
use Scalar::Util qw/refaddr/;

my $app_class = 'MyApp';

my $foo = Foo->COMPONENT($app_class, { args => 'yes' });
is $foo->{args}, 'yes', 'foo created';
is $foo->context->_is_this_the_app, 'oh yeah', 'got app';

my $ctx = { };
my $foo2 = $foo->ACCEPT_CONTEXT($ctx);
is refaddr($foo), refaddr($foo2), 'foo and foo2 are the same ref';
is refaddr($foo->context), refaddr($ctx), 'got ctx';

