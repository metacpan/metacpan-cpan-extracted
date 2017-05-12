#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use ok 'Test1';

my $components=Test1->components;
cmp_deeply($components,
           {
               Test1 => ignore(),
               'Test1::Controller::base_url' => all(
                   isa('Catalyst::Controller'),
                   methods(
                       action_namespace => 'base_url',
                       path_prefix => 'base_url',
                   ),
               ),
               'Test1::Controller::base_url2' => all(
                   isa('Catalyst::Controller'),
                   methods(
                       action_namespace => 'base_url2',
                       path_prefix => 'base_url2',
                   ),
               ),
               'Test1::Foo::One' => ignore(),
               'Test1::Foo::Two' => ignore(),
           },
           'components loaded'
);

done_testing();
