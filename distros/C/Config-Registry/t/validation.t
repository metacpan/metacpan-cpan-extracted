#!/usr/bin/env perl
use Test2::V0;
use strictures 2;

use Test2::Require::Module 'Types::Standard';

package Bar;
    use Types::Standard -types;
    use Moo;
    extends 'Config::Registry';
    __PACKAGE__->schema({
        ary => ArrayRef[
            Tuple[ Str, Int ],
        ],
    });
    __PACKAGE__->publish();
package main;

is(
    dies{ Bar->new( ary=>[['asd',3]] ) },
    undef,
    'validation passed'
);

isnt(
    dies{ Bar->new( ary=>[['asd',3,2]] ) },
    undef,
    'validation failed',
);

isnt(
    dies{ Bar->new( ary=>[['asd',3],2] ) },
    undef,
    'validation failed',
);

done_testing;
