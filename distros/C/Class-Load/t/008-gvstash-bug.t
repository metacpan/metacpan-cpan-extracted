use strict;
use warnings;
use Test::Fatal;
use Test::More 0.88;
use lib 't/lib';
use Test::Class::Load 'load_class';

is( exception {
    load_class('Class::Load::Stash::Sub');
}, undef, 'Loaded Class::Load::Stash::Sub' );

Class::Load::Stash->can('a_method');

is( exception {
    load_class('Class::Load::Stash');
}, undef, 'Loaded Class::Load::Stash' );

is( exception {
    Class::Load::Stash->a_method;
}, undef,
'Actually loaded Class::Load::Stash - we were not fooled by mention of this stash in Class::Load::Stash::Sub' );

done_testing;
