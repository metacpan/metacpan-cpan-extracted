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

my ($bcd, $bcd_data, $records);

# Allow running just a single set of tests
my $only = @ARGV ? $ARGV[0] : undef;

ok($bcd = Business::CompanyDesignator->new, 'constructor ok');
ok($bcd_data = $bcd->data, 'data method ok');

my $i = 3;
for my $t (@$data) {
  die "Entry has no 'lang' attribute: " . dump($t) if ! $t->{lang};
  next if $t->{skip};

  my $exp_before    = $t->{before}  // '';
  my $exp_des       = $t->{des}     // '';
  my $exp_des_std   = $t->{des_std} // '';
  my $exp_after     = $t->{after}   // '';
  my $lang          = $t->{lang};

  # Array-context split_designator
  my ($before, $des, $after, $normalised_des) = $bcd->split_designator($t->{name}, lang => $lang);

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
  my $res = $bcd->split_designator($t->{name}, lang => $lang);
  if (! $only || ($only >= $i && $only <= $i+2)) {
    is($res->before, $exp_before, "(scalar) $t->{name}: before ok: " . $res->before);
    is($res->designator, $exp_des // '', "(scalar) $t->{name} designator ok: " . ($res->designator // 'undef'));
    is($res->designator_std, $exp_des_std // '', "(scalar) $t->{name} designator_std ok: " . ($res->designator_std // 'undef'));
  }
  $i += 3;
  if ($res->after || $after) {
    if (! $only || $only == $i) {
      is($res->after, $after, "(scalar) $t->{name} after ok: " . ($res->after // 'undef'));
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

done_testing;

