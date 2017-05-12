#!perl
use warnings;
use strict;

use Test::More;

eval 'use Test::Exception';
plan skip_all => 'Test::Exception required' if $@;
plan tests => 4;

sub _action_cache { return [] }

use CatalystX::Imports ();

lives_ok(sub {
    CatalystX::Imports->export_into('Foo', Vars => {});
}, 'export_into works with an even number of arguments');

throws_ok(sub {
    CatalystX::Imports->export_into('Foo', 'Vars');
}, qr{expects a key/value list}, 'export_into fails with an odd number of arguments');

throws_ok(sub {
    CatalystX::Imports->export_into('Foo', Vars => []);
}, qr/1 or a hash reference expected/, 'Vars export_into fails with something not 1 or hashref (arrayref)');

throws_ok(sub {
    CatalystX::Imports->export_into('Foo', Vars => 0);
}, qr/1 or a hash reference expected/, 'Vars export_into fails with somethong not 1 or hashref (0)');
