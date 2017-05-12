#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Moose';
use lib 't/lib';
use Test::Class::Refresh;

use Class::Refresh;

my $dir = prepare_temp_dir_for('moose-subclasses');
push @INC, $dir->dirname;

our ($superclass_reloads, $subclass_reloads) = (0, 0);

require Foo;
require Foo::Sub;

Class::Refresh->refresh;

is($superclass_reloads, 1, "superclass loaded");
is($subclass_reloads, 1, "subclass loaded");

is_deeply([sort map { $_->name } Foo->meta->get_all_attributes],
          ['foo'],
          "correct starting attr list");
can_ok('Foo', 'meth');
ok(!Foo->can('other_meth'), "!Foo->can('other_meth')");

is_deeply([sort map { $_->name } Foo::Sub->meta->get_all_attributes],
          ['baz', 'foo'],
          "correct starting attr list");
can_ok('Foo::Sub', 'meth');
ok(!Foo::Sub->can('other_meth'), "!Foo::Sub->can('other_meth')");


sleep 2;
update_temp_dir_for('moose-subclasses', $dir);

Class::Refresh->refresh;

is($superclass_reloads, 2, "superclass reloaded");
is($subclass_reloads, 2, "subclass reloaded");

is_deeply([sort map { $_->name } Foo->meta->get_all_attributes],
          ['bar'],
          "correct new attr list");
ok(!Foo->can('meth'), "!Foo->can('meth')");
can_ok('Foo', 'other_meth');

is_deeply([sort map { $_->name } Foo::Sub->meta->get_all_attributes],
          ['bar', 'baz'],
          "correct new attr list");
can_ok('Foo::Sub', 'meth');
can_ok('Foo::Sub', 'other_meth');

done_testing;
