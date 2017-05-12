#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use ok 'Test3';

my $components=Test3->components;
cmp_deeply($components,
           {
               Test3 => ignore(),
               'Test3::Controller::input_queue' => all(
                   isa('Catalyst::Controller::JMS'),
                   methods(
                       action_namespace => 'input_queue',
                       path_prefix => 'input_queue',
                   ),
               ),
               'Test3::Foo::One' => ignore(),
           },
           'components loaded'
);

done_testing();
