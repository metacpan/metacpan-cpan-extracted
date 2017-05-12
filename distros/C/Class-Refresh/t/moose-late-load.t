#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::Class::Refresh;

use Class::Refresh track_require => 1;

my $dir;
BEGIN {
    $dir = prepare_temp_dir_for('moose-late-load');
    push @INC, $dir->dirname;

    Class::Refresh->refresh;
}

# have to do this later
use Test::Requires 'Moose';

require Foo;
require Foo::Immutable;

is_deeply([Foo->meta->get_attribute_list], ['foo'],
          "correct starting attr list");
can_ok('Foo', 'meth');
ok(!Foo->can('other_meth'), "!Foo->can('other_meth')");

is_deeply([Foo::Immutable->meta->get_attribute_list], ['foo'],
          "correct starting attr list");
can_ok('Foo::Immutable', 'meth');
ok(!Foo::Immutable->can('other_meth'), "!Foo::Immutable->can('other_meth')");


sleep 2;
update_temp_dir_for('moose-late-load', $dir, 'middle');

Class::Refresh->refresh;

is_deeply([Foo->meta->get_attribute_list], ['bar'],
          "correct refreshed attr list");
can_ok('Foo', 'other_meth');
ok(!Foo->can('meth'), "!Foo->can('meth')");

is_deeply([Foo::Immutable->meta->get_attribute_list], ['bar'],
          "correct refreshed attr list");
can_ok('Foo::Immutable', 'other_meth');
ok(!Foo::Immutable->can('meth'), "!Foo::Immutable->can('meth')");


sleep 2;
update_temp_dir_for('moose-late-load', $dir, 'after');

Class::Refresh->refresh;

is_deeply([Foo->meta->get_attribute_list], ['baz'],
          "correct refreshed attr list");
can_ok('Foo', 'other_other_meth');
ok(!Foo->can('meth'), "!Foo->can('meth')");
ok(!Foo->can('other_meth'), "!Foo->can('other_meth')");

is_deeply([Foo::Immutable->meta->get_attribute_list], ['baz'],
          "correct refreshed attr list");
can_ok('Foo::Immutable', 'other_other_meth');
ok(!Foo::Immutable->can('meth'), "!Foo::Immutable->can('meth')");
ok(!Foo::Immutable->can('other_meth'), "!Foo::Immutable->can('other_meth')");

done_testing;
