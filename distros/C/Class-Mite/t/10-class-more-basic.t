#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use lib 'lib';

# Test 1: Basic class creation
{
    package Test::Simple;
    use Class::More;

    has 'name';
    has 'age';

    sub get_info {
        my $self = shift;
        return $self->name . " is " . $self->age . " years old";
    }
}

# Check if methods are available
ok(Test::Simple->can('new'), 'new method is available');
ok(Test::Simple->can('name'), 'name accessor is available');
ok(Test::Simple->can('age'), 'age accessor is available');

done_testing;
