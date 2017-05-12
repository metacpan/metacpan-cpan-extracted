#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Requires 'Moose';
use lib 't/lib';
use Test::Class::Refresh;

use Class::Refresh;

my $dir = prepare_temp_dir_for('moose-roles');
push @INC, $dir->dirname;

our %reloads;

require Foo;
require Bar;
require Baz;

Class::Refresh->refresh;

is_deeply([sort map { $_->name } Foo->meta->get_all_attributes],
          ['foo', 'foo_role1'],
          "correct starting attr list");
is_deeply([sort map { $_->name } Bar->meta->get_all_attributes],
          ['bar', 'bar_role', 'foo_role1'],
          "correct starting attr list");
is_deeply([sort map { $_->name } Baz->meta->get_all_attributes],
          ['bar_role', 'baz', 'baz_role', 'foo_role1'],
          "correct starting attr list");
is_deeply(\%reloads,
          { foo => 1, foo_role => 1,
            bar => 1, bar_role => 1,
            baz => 1, baz_role => 1 },
          "everything loaded");


sleep 2;
update_temp_dir_for('moose-roles', $dir);

Class::Refresh->refresh;

is_deeply([sort map { $_->name } Foo->meta->get_all_attributes],
          ['foo', 'foo_role2'],
          "correct starting attr list");
is_deeply([sort map { $_->name } Bar->meta->get_all_attributes],
          ['bar', 'bar_role', 'foo_role2'],
          "correct starting attr list");
is_deeply([sort map { $_->name } Baz->meta->get_all_attributes],
          ['bar_role', 'baz', 'baz_role', 'foo_role2'],
          "correct starting attr list");
is_deeply(\%reloads,
          { foo => 2, foo_role => 2,
            bar => 2, bar_role => 2,
            baz => 2, baz_role => 1 },
          "everything reloaded");

done_testing;
