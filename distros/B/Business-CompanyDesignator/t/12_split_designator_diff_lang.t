#!perl

use 5.010;
use strict;
use utf8;
use open qw(:std :utf8);
use Test::More;
use YAML qw(LoadFile);
use Data::Dump qw(dd pp dump);

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Business::CompanyDesignator;

# Use a bogus language code, so none of our designators should match
my $lang = 'zz';

my $data = LoadFile("$Bin/t10/data.yml");

my ($bcd, $bcd_data, $records);

# Allow running just a single set of tests
my $only = @ARGV ? $ARGV[0] : undef;

ok($bcd = Business::CompanyDesignator->new, 'constructor ok');
ok($bcd_data = $bcd->data, 'data method ok');

my $i = 3;
for my $t (@$data) {
  next if ! $t->{lang} || $t->{skip};

  # Array-context split_designator
  if (! $only || ($only >= $i && $only < $i+4)) {
    my ($before, $des, $after, $normalised_des) = $bcd->split_designator($t->{name}, lang => $lang);
    is($before, $t->{name}, "(array) $t->{name}: before ok: $before");
    is($des, '', "(array) $t->{name} designator ok: " . ($des // 'undef'));
    is($normalised_des, '', "(array) $t->{name} normalised_des ok: " . ($normalised_des // 'undef'));
    is($after, '', "(array) $t->{name} after ok: " . ($after // 'undef'));
  }
  $i += 4;

  # Scalar-context split_designator
  if (! $only || ($only >= $i && $only < $i+4)) {
    my $res = $bcd->split_designator($t->{name}, lang => $lang);
    is($res->before, $t->{name}, "(scalar) $t->{name}: before ok: " . $res->before);
    is($res->designator, '', "(scalar) $t->{name} designator ok: " . ($res->designator // 'undef'));
    is($res->designator_std, '', "(scalar) $t->{name} designator_std ok: " . ($res->designator_std // 'undef'));
    is($res->after, '', "(scalar) $t->{name} after ok: " . ($res->after // 'undef'));
  }
  $i += 4;
}

done_testing;

