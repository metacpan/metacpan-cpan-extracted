use strict;
use warnings;
use File::Spec;

use Test::More tests => 27;
use Astro::Hipparcos;
pass();
chdir('t') if -d 't';

my $catalog = Astro::Hipparcos->new(File::Spec->catfile('data', 'hip_test.dat'));
isa_ok($catalog, 'Astro::Hipparcos');
SCOPE: {
  my $record = Astro::Hipparcos::Record->new();
  isa_ok($record, 'Astro::Hipparcos::Record');
}
pass();

SCOPE: {
  my $record = $catalog->get_record();
  isa_ok($record, 'Astro::Hipparcos::Record');
  my $id = $record->get_HIP();
  is($id, 1, "first record has id 1");
  my $ra = $record->get_RAhms();
  is($ra, "00 00 00.22", "first record has correct ra");
  $record = $catalog->get_record();
  isa_ok($record, 'Astro::Hipparcos::Record');
  $id = $record->get_HIP();
  is($id, 2, "second record has id 2");
  $ra = $record->get_RAhms();
  is($ra, "00 00 00.91", "second record has correct ra");
  ok(!defined($catalog->get_record), "EOF");
}
pass();

SCOPE: { #test get_record with record number
  my $record = $catalog->get_record(1);
  isa_ok($record, 'Astro::Hipparcos::Record');
  my $id = $record->get_HIP();
  is($id, 1, "first record has id 1");
  my $ra = $record->get_RAhms();
  is($ra, "00 00 00.22", "first record has correct ra");
  $record = $catalog->get_record(1);
  isa_ok($record, 'Astro::Hipparcos::Record');
  $id = $record->get_HIP();
  is($id, 1, "first record has id 1");
  $ra = $record->get_RAhms();
  is($ra, "00 00 00.22", "first record has correct ra");
  $record = $catalog->get_record(2);
  isa_ok($record, 'Astro::Hipparcos::Record');
  $id = $record->get_HIP();
  is($id, 2, "second record has id 2");
  $ra = $record->get_RAhms();
  is($ra, "00 00 00.91", "second record has correct ra");
  ok(!defined($catalog->get_record), "EOF");
  $record = $catalog->get_record(2);
  isa_ok($record, 'Astro::Hipparcos::Record');
  $id = $record->get_HIP();
  is($id, 2, "second record has id 2");
  $ra = $record->get_RAhms();
  is($ra, "00 00 00.91", "second record has correct ra");
  ok(!defined($catalog->get_record), "EOF");
}
pass();
