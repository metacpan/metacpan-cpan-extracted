#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Moose';
use lib 't/lib';
use Test::Class::Refresh;

use Class::Refresh;

my $dir = prepare_temp_dir_for('other-api');
push @INC, $dir->dirname;

require Foo;
require Foo::Bar;

Class::Refresh->refresh;

is_deeply([Class::Refresh->modified_modules], [],
          "got the right list of modified modules");

sleep 2;
update_temp_dir_for('other-api', $dir);

is_deeply([sort Class::Refresh->modified_modules], ['Foo', 'Foo::Bar'],
          "got the right list of modified modules");

Class::Refresh->refresh;

ok(Class::Load::is_class_loaded('Foo'), "Foo is loaded");

Class::Refresh->unload_module('Foo');

ok(!Class::Load::is_class_loaded('Foo'), "Foo is not loaded");
ok(!Class::MOP::class_of('Foo'), "Foo no longer has a metaclass");
ok(!exists $INC{'Foo.pm'}, "Foo isn't in \%INC");

is_deeply([Class::Refresh->modified_modules], [],
          "got the right list of modified modules");

Class::Refresh->load_module('Foo');

ok(Class::Load::is_class_loaded('Foo'), "Foo is loaded");
ok(Class::MOP::class_of('Foo'), "Foo has a metaclass");
ok(exists $INC{'Foo.pm'}, "Foo is in \%INC");

is_deeply([Class::Refresh->modified_modules], [],
          "got the right list of modified modules");

my $meta = Class::MOP::class_of('Foo');
Class::Refresh->refresh_module('Foo');

ok(Class::Load::is_class_loaded('Foo'), "Foo is loaded");
ok(Class::MOP::class_of('Foo'), "Foo has a metaclass");
ok(exists $INC{'Foo.pm'}, "Foo is in \%INC");

isnt($meta, Class::MOP::class_of('Foo'), "metaclass was reinitialized");

done_testing;
