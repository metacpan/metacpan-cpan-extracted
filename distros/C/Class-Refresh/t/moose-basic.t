#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Moose';
use lib 't/lib';
use Test::Class::Refresh;

use Class::Refresh;

my $dir = prepare_temp_dir_for('moose-basic');
push @INC, $dir->dirname;

require Foo;
require Foo::Immutable;

Class::Refresh->refresh;

is_deeply([Foo->meta->get_attribute_list], ['foo'],
          "correct starting attr list");
can_ok('Foo', 'meth');
ok(!Foo->can('other_meth'), "!Foo->can('other_meth')");

is_deeply([Foo::Immutable->meta->get_attribute_list], ['foo'],
          "correct starting attr list");
can_ok('Foo::Immutable', 'meth');
ok(!Foo::Immutable->can('other_meth'), "!Foo::Immutable->can('other_meth')");


sleep 2;
update_temp_dir_for('moose-basic', $dir);

Class::Refresh->refresh;

is_deeply([Foo->meta->get_attribute_list], ['bar'],
          "correct refreshed attr list");
can_ok('Foo', 'other_meth');
ok(!Foo->can('meth'), "!Foo->can('meth')");

is_deeply([Foo::Immutable->meta->get_attribute_list], ['bar'],
          "correct refreshed attr list");
can_ok('Foo::Immutable', 'other_meth');
ok(!Foo::Immutable->can('meth'), "!Foo::Immutable->can('meth')");

done_testing;
