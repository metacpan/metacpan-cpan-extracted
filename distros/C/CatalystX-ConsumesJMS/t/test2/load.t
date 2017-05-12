#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use ok 'Test2';

my $components=Test2->components;
cmp_deeply($components,
           {
               Test2 => ignore(),
               'Test2::Controller::base_url' => all(
                   isa('Catalyst::Controller'),
                   methods(
                       action_namespace => 'base_url',
                       path_prefix => 'base_url',
                   ),
               ),
               'Test2::Foo::One' => ignore(),
           },
           'components loaded'
);

done_testing();
