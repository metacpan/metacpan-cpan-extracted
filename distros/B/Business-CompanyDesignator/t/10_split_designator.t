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

my $data = LoadFile("$Bin/t10/data.yml");

my @bad = (
  # Check we are only matching literal periods, not any character
  'Open Fusion Pty1 Ltd2',
);

my ($bcd, $bcd_data, $records);

# Allow running just a single set of tests
my $only = @ARGV ? $ARGV[0] : undef;

ok($bcd = Business::CompanyDesignator->new, 'constructor ok');
ok($bcd_data = $bcd->data, 'data method ok');

my $i = 3;
for my $t (@$data) {
  next if $t->{skip} || $t->{skip_unless_lang};

  my $exp_before    = $t->{before}  // '';
  my $exp_des       = $t->{des}     // '';
  my $exp_des_std   = $t->{des_std} // '';
  my $exp_after     = $t->{after}   // '';
  my $short_name    = $exp_before || $exp_after || '';
  my $extra         = $exp_before ? ($exp_after || '') : '';

  # Array-context split_designator
  my ($before, $des, $after, $normalised_des) = $bcd->split_designator($t->{name});

  if (! $only || ($only >= $i && $only <= $i+2)) {
    is($before, $exp_before, "(array) $t->{name}: before ok: $before");
    is($des, $exp_des, "(array) $t->{name} designator ok: " . ($des // 'undef'));
    is($normalised_des, $exp_des_std, "(array) $t->{name} normalised_des ok: " . ($normalised_des // 'undef'));
  }
  $i += 3;
  if ($exp_after || $after) {
    if (! $only || $only == $i) {
      is($after, $exp_after, "(array) $t->{name} after ok: " . ($after // 'undef'));
    }
    $i += 1;
  }

  # Test that $normalised_des maps back to one or more records
  if ($normalised_des) {
    my @records = $bcd->records($normalised_des);
    if (! $only || $only == $i) {
      ok(scalar @records, 'records returned ' . scalar(@records) . ' record(s): '
        . join(',', map { $_->long } @records));
    }
    $i += 1;
  }

  # Scalar-context split_designator
  my $res = $bcd->split_designator($t->{name});
  if (! $only || ($only >= $i && $only <= $i+4)) {
    is($res->before, $exp_before, "(scalar) $t->{name}: before ok: " . $res->before);
    is($res->designator, $exp_des // '', "(scalar) $t->{name} designator ok: " . ($res->designator // 'undef'));
    is($res->designator_std, $exp_des_std // '', "(scalar) $t->{name} designator_std ok: " . ($res->designator_std // 'undef'));
    is($res->short_name, $short_name, "(scalar) $t->{name} short_name ok: " . $res->short_name);
    is($res->extra, $extra, "(scalar) $t->{name} extra ok: " . $res->extra);
  }
  $i += 5;
  if ($res->after || $exp_after) {
    if (! $only || $only == $i) {
      is($res->after, $exp_after, "(scalar) $t->{name} after ok: " . ($res->after // 'undef'));
    }
    $i += 1;
  }
  if ($res->designator_std) {
    if (! $only || ($only >= $i && $only <= $i+2)) {
      ok($records = $res->records, "(scalar) $t->{name} result object includes records: " . scalar(@$records));
      ok($records->[0]->long, 'record 0 long exists: ' . $records->[0]->long);
      ok($records->[0]->lang, 'record 0 lang exists: ' . $records->[0]->lang);
    }
    $i += 3;
  }
}

for my $company_name (@bad) {
  my ($before, $des, $after, $normalised_des) = $bcd->split_designator($company_name);
  if (! $only || ($only >= $i && $only <= $i+2)) {
    is($before, $company_name, "non-matching $company_name: before is company name");
    is($des, '', "non-matching $company_name: designator undef");
    is($normalised_des, '', "non-matching $company_name: normalised_des undef");
  }
  $i += 3;
}

done_testing;

