#!perl -T
use utf8;
use strict;
use warnings FATAL => 'all';
use Test::More;

my $class = 'Business::HK::IdentityCard';

# use and can
BEGIN { use_ok('Business::HK::IdentityCard') }
can_ok( $class, qw(new is_valid as_string as_string_no_checksum) );

# Valid ID
my $hkid = new_ok($class, ['A123456(3)']);
ok($hkid->is_valid(), 'Valid HKID');

# Valid ID, alternative formats
$hkid = $hkid->new('A1234563');
ok($hkid->is_valid(), 'Valid HKID, no brackets');

$hkid = $hkid->new('a1234563');
ok($hkid->is_valid(), 'Valid HKID, lower case and no brackets');

# Valid ID with check digit A (10)
$hkid = $hkid->new('A123458(A)');
ok($hkid->is_valid(), 'Valid HKID, check digit A');

# Valid ID with check digit 0
$hkid = $hkid->new('A123466(0)');
ok($hkid->is_valid(), 'Valid HKID, check digit 0');

# Valid ID with two prefix characters
$hkid = $hkid->new('UH456123(7)');
ok($hkid->is_valid(), 'Valid HKID, two prefix characters');

# Try some invalid IDs
$hkid = $hkid->new('A123456(9)');
ok(!$hkid->is_valid(), 'Detect invalid HKID checksum');

$hkid = $hkid->new('A1(2)');
ok(!$hkid->is_valid(), 'Detect wrong length');

$hkid = $hkid->new('123456(3)');
ok(!$hkid->is_valid(), 'Detect missing prefix');

$hkid = $hkid->new(11234563);
ok(!$hkid->is_valid(), 'Detect missing prefix (as number)');

$hkid = $hkid->new();
ok(!$hkid->is_valid(), 'Detect no ID');

$hkid = $hkid->new('');
ok(!$hkid->is_valid(), 'Detect empty ID');

# Methods to extract the validated ID

my $good_hkid = $hkid->new("a1234563");
my $bad_hkid  = $hkid->new("a123");

is($good_hkid->as_string(), "A123456(3)", 'as_string format');
is($bad_hkid->as_string(), undef, 'as_string format for invalid ID');

is($good_hkid->as_string_no_checksum(), 'A123456', 'as_string_no_checksum');
is($bad_hkid->as_string_no_checksum(), undef, 
   'as_string_no_checksum for invalid ID');


done_testing();
