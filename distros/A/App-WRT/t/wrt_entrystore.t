#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Test::More tests => 21;
use App::WRT;

chdir 'example';

# configuration

  ok(
    my $w = App::WRT::new_from_file('wrt.json'),
    "got parent WRT object"
  );

# individual method tests

# listing out of all source files:

  my (@all_source_files) = $w->{entries}->all();
  my $expected_count = 31;
  diag("got " . scalar @all_source_files . " source files.");
  ok(
    scalar @all_source_files == $expected_count,
    "got $expected_count source files from example archive, as expected"
  );

# checking an entry exists:

  ok(
    $w->{entries}->is_extant('2014'),
    '2014 exists'
  );

# listing entries like 2014/1/1 for an individual day:

  my (@all_day_entries) = $w->{entries}->all_days();
  ok(
    scalar @all_day_entries == 2,
    'got 2 day entries from example archive, as expected'
  );

# listing entries like 2014/1 for a month:

  my (@all_month_entries) = $w->{entries}->all_months();
  ok(
    scalar @all_month_entries == 3,
    'got 3 month entries from example archive, as expected'
  );

# listing entries like 2014 for a year:

  my (@all_year_entries) = $w->{entries}->all_years();
  ok(
    scalar @all_year_entries == 3,
    'got 3 year entries from example archive, as expected'
  );

# next / previous

  ok(
    $w->{entries}->next('2014/1/1') eq '2014/1/2',
    'got a next day for 2014/1/1'
  );

  ok(
    $w->{entries}->previous('2014/1/2') eq '2014/1/1',
    'got a prev day for 2014/1/2'
  );

# property finding by entry / entry finding by property

  ok(
    ($w->{entries}->by_prop('tag-something'))[0] eq '2014/1/2',
    'found 2014/1/2 for tag-something.prop'
  );

  ok(
    $w->{entries}->has_prop('2014/1/2', 'tag-something'),
    '2014/1/2 has tag-something.prop'
  );

  # diag(Dumper($w->{entries}->by_prop('something')));
  # diag(scalar($w->{entries}->by_prop('something')));
  ok(
    scalar($w->{entries}->by_prop('something')) == 0,
    'did not find any entries for something.prop'
  );

  ok(
    'tag-something' eq ($w->{entries}->props_for('2014/1/2'))[0],
    'found tag-something for 2014/1/2'
  );

  my @all_props = $w->{entries}->all_props();
  ok(
    scalar(@all_props) == 2,
    'found 2 properties for example repo'
  );
  # diag(join ', ', @all_props);

# finding parents of entries:

  my $date_parent = $w->{entries}->parent_of('2014/1/2');
  ok(
    $date_parent eq '2014/1',
    'found correct parent for 2014/1/2'
  );
  # diag($date_parent);

  my $icon_parent = $w->{entries}->parent_of('icon_test');
  ok(
    ! defined $icon_parent,
    'found no parent for icon_test'
  );
  # diag($icon_parent);

  eval {
    $w->{entries}->parent_of('i_do_not_exist');
  };
  ok(
    $@,
    "croaked on trying to find parent of a nonexistent entry"
  );

# checking whether entries are directories, flatfiles, etc.

  ok(
    $w->{entries}->is_dir('2014'),
    '2014 is a directory, as expected'
  );

  ok(
    ! $w->{entries}->is_dir('2014/1/1/test_entry'),
    '2014/1/1/test_entry is not a directory, as expected'
  );

  ok(
    $w->{entries}->is_file('2014/1/1/test_entry'),
    '2014/1/1/test_entry is a flatfile, as expected'
  );

# checking whether an entry is a directory with an index:

  ok(
    $w->{entries}->has_index('2014/1/1'),
    '2014/1/1 has an index file'
  );

  ok(
    ! $w->{entries}->has_index('icon_test/textfile'),
    'icon_test/textfile does not have an index'
  );

  # diag(Dumper($w->{entries}->{entry_properties}));
  # diag(Dumper($w->{entries}->{property_entries}));
