#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Test::More tests => 34;
use App::WRT;

chdir 'example/blog';

my $es = App::WRT::EntryStore->new('archives');

# listing out of all source files:

  my (@all_source_files) = $es->all();
  note("got " . scalar @all_source_files . " source files.");
  ok(
    scalar @all_source_files > 0,
    "got some nonzero set of source files from all()"
  );

# checking an entry exists:

  ok(
    $es->is_extant('2014'),
    '2014 exists'
  );

# checking entries are renderable or not:

  ok(
    $es->is_renderable('2014'),
    '2014 is renderable'
  );

  ok(
    $es->is_renderable('i_do_not_exist'),
    'a nonexistent entry path is theoretically renderable'
  );

# listing entries like 2014/1/1 for an individual day:

  my (@all_day_entries) = $es->all_days();
  ok(
    scalar @all_day_entries == 3,
    'got 3 day entries from example archive, as expected'
  );

# listing entries like 2014/1 for a month:

  my (@all_month_entries) = $es->all_months();
  ok(
    scalar @all_month_entries == 4,
    'got 4 month entries from example archive, as expected'
  );

# listing entries like 2014 for a year:

  my (@all_year_entries) = $es->all_years();
  ok(
    scalar @all_year_entries == 4,
    'got 4 year entries from example archive, as expected'
  );

# listing days contained by a month or year:

  my (@days_for_jan) = $es->days_for('2014/1');
  my @expected_days_for_jan = ('2014/1/1', '2014/1/2');
  is_deeply(
    \@days_for_jan,
    \@expected_days_for_jan,
    'got expected days for january 2014'
  );

  my (@days_for_1952) = $es->days_for('1952');
  my @expected_days_for_1952 = ('1952/2/13');
  is_deeply(
    \@days_for_1952,
    \@expected_days_for_1952,
    'got expected days for 1952'
  );

# listing months contained by a year:

  my (@months_for_2013) = $es->months_for('2013');
  my @expected_months_for_2013 = ('2013/1', '2013/2');
  is_deeply(
    \@months_for_2013,
    \@expected_months_for_2013,
    'got expected months for 2013'
  );

# next / previous

  ok(
    $es->next('2014/1/1') eq '2014/1/2',
    'got a next day for 2014/1/1'
  );

  ok(
    $es->previous('2014/1/2') eq '2014/1/1',
    'got a prev day for 2014/1/2'
  );

# property finding by entry / entry finding by property

  ok(
    ($es->by_prop('tag.something'))[0] eq '2014/1/2',
    'found 2014/1/2 for tag.something.prop'
  );

  ok(
    $es->has_prop('2014/1/2', 'tag.something'),
    '2014/1/2 has tag.something.prop'
  );

  # diag(Dumper($es->by_prop('something')));
  # diag(scalar($es->by_prop('something')));
  ok(
    scalar($es->by_prop('something')) == 0,
    'did not find any entries for something.prop'
  );

  ok(
    'tag.something' eq ($es->props_for('2014/1/2'))[0],
    'found tag.something for 2014/1/2'
  );

  my @all_props = $es->all_props();
  ok(
    scalar(@all_props) == 5,
    'found 3 properties for example repo'
  ) or diag(join ', ', @all_props);

# property values:

  my $foo_prop = $es->prop_value('prop_value_test', 'foo');
  chomp($foo_prop);
  note('Property: ' . $foo_prop);
  is(
    'bar',
    $foo_prop,
    'got expected property value for prop_value_test'
  );

  ok(
    ! defined $es->prop_value('title_test', 'no-such-prop'),
    'nonexistent property is undefined'
  );

# finding parents of entries:

  my $date_parent = $es->parent('2014/1/2');
  ok(
    $date_parent eq '2014/1',
    'found correct parent for 2014/1/2'
  ) or diag($date_parent);

  my $icon_parent = $es->parent('icon_test');
  ok(
    ! defined $icon_parent,
    'found no parent for icon_test'
  ) or diag($icon_parent);

  eval {
    $es->parent('i_do_not_exist');
  };
  ok(
    $@,
    "croaked on trying to find parent of a nonexistent entry"
  );

# finding children of entries, sub-entries

  my @children = $es->children('2013');
  ok(
    @children == 4,
    "got 4 children for 2013"
  ) or diag(join ', ', @children);

  my @children_2012 = $es->children('2012');
  ok(
    @children_2012 == 0,
    "got no children for 2012"
  ) or diag(join ', ', @children_2012);

  my @children_basenames = $es->children_basenames('2013');
  ok(
    (! grep { m/\// } @children_basenames),
    "children_basenames() output doesn't include slashes"
  ) or diag(join ', ', @children_basenames);

  my (@sub_entries) = $es->get_sub_entries('icon_test');
  my (@expected_sub_entries) = ('dir', 'textfile');
  is_deeply(
    \@sub_entries,
    \@expected_sub_entries,
    'expected 2 alphabetically sorted sub-entries for icon_test'
  ) or diag(join ', ', @sub_entries);

# checking whether entries are directories, flatfiles, etc.

  ok(
    $es->is_dir('2014'),
    '2014 is a directory, as expected'
  );

  ok(
    ! $es->is_dir('2014/1/1/test_entry'),
    '2014/1/1/test_entry is not a directory, as expected'
  );

  ok(
    $es->is_file('2014/1/1/test_entry'),
    '2014/1/1/test_entry is a flatfile, as expected'
  );

# checking whether an entry is a directory with an index:

  ok(
    $es->has_index('2014/1/1'),
    '2014/1/1 has an index file'
  );

  ok(
    ! $es->has_index('icon_test/textfile'),
    'icon_test/textfile does not have an index'
  );

# basename of an entry:

  ok(
    $es->basename('1969/2/1') eq '1',
    'got an expected basename for a day'
  );

  ok(
    $es->basename('1969/2') eq '2',
    'got an expected basename for a month' 
  );

  ok(
    $es->basename('1969') eq '1969',
    'got an expected basename for a year' 
  );

  # diag(Dumper($es->{entry_properties}));
  # diag(Dumper($es->{property_entries}));
