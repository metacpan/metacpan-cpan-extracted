#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use ok 'Test4';

my $components=Test4->components;
cmp_deeply($components,
           {
               Test4 => ignore(),
               'Test4::Controller::input_queue' => all(
                   isa('Catalyst::Controller::JMS'),
                   methods(
                       action_namespace => 'input_queue',
                       path_prefix => 'input_queue',
                   ),
               ),
               'Test4::Foo::One' => ignore(),
           },
           'components loaded'
);

done_testing();
