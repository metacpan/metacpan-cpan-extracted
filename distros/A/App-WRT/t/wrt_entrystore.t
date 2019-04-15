#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Test::More tests => 11;
use App::WRT;

chdir 'example';

# 'configuration';

  ok(
    my $w = App::WRT::new_from_file('wrt.json'),
    "Got parent WRT object."
  );

# 'individual method tests';

# listing out of all source files

  my (@all_source_files) = $w->{entries}->all();
  ok(
    scalar @all_source_files == 16,
    'got 16 source files from example archive, as expected'
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
    scalar @all_month_entries == 1,
    'got 2 month entries from example archive, as expected'
  );

# listing entries like 2014 for a year:

  my (@all_year_entries) = $w->{entries}->all_years();
  ok(
    scalar @all_year_entries == 1,
    'got 1 year entry from example archive, as expected'
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

  ok(
    scalar($w->{entries}->all_props()) == 1,
    'found 1 property for example repo'
  );

  # diag(Dumper($w->{entries}->{entry_properties}));
  # diag(Dumper($w->{entries}->{property_entries}));
