#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Class::Superclasses;

my $obj = bless {}, 'MyTest';

my $parser = Class::Superclasses->new;

my $error;
eval {
    $parser->document( $obj );
    1;
} or $error = $@;

ok $error;

done_testing();
