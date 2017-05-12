#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    resource_groups => {
        Group => [ qw<Foo Bar Baz> ],
    },

    rules => {
        Person => {
            Group => [
                [ 1, { name => 'me' } ]
            ],

            NotGroup => [
                [0],
            ],
        },
    },
);

{
    my $person_rules = $auth->{'rules'}{'Person'};
    ok( exists $person_rules->{'Foo'}, 'Group expanded to Foo' );
    ok( exists $person_rules->{'Bar'}, 'Group expanded to Bar' );
    ok( exists $person_rules->{'Baz'}, 'Group expanded to Baz' );
    ok( exists $person_rules->{'NotGroup'}, 'NotGroup resource kept' );
    ok( ! exists $person_rules->{'Group'}, 'Group resource deleted' );
}

my $ruleset = [ 1, { name => 'me' } ];
isa_ok( $auth, 'Authorize::Rule' );

ok(
    $auth->is_allowed( 'Person', 'Foo', { name => 'me' } ),
    'Person is allowed to Foo',
);

ok(
    $auth->is_allowed( 'Person', 'Bar', { name => 'me' } ),
    'Person is allowed to Foo',
);

ok(
    $auth->is_allowed( 'Person', 'Baz', { name => 'me' } ),
    'Person is allowed to Foo',
);

