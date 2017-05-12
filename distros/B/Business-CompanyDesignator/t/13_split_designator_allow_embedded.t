#!perl
#
# split_designator unit tests with 'allow_embedded'
#

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

# Map of designator position => split_designator allow_embedded flags that *should* match
my %ae_match = (
  end   => [ 1, 0, undef ],
  begin => [ 1, 0, undef ],
  mid   => [ 1, undef ],
);
# Map of designator position => split_designator allow_embedded flags that *should not* match
my %ae_nonmatch = (
  end   => [],
  begin => [],
  mid   => [ 0 ],
);

my $data = LoadFile("$Bin/t10/data.yml");

my ($bcd, $bcd_data, $records);

# Allow running just a single set of tests
my $only = @ARGV ? $ARGV[0] : undef;

ok($bcd = Business::CompanyDesignator->new, 'constructor ok');
ok($bcd_data = $bcd->data, 'data method ok');

my $i = 3;
for my $t (@$data) {
  if (! $only || ($only >= $i && $only < $i+12)) {
    my $des_posn = $t->{position} // 'end';
    my $ae_match = $ae_match{ $des_posn };
    my $ae_nonmatch = $ae_nonmatch{ $des_posn };

    # Should match with all @$ae_match
    for my $ae (@$ae_match) {
      my $res = $bcd->split_designator($t->{name}, allow_embedded => $ae);
      is($res->before, $t->{before} // '', "$t->{name}, allow_embedded '$ae' before ok: " . $res->before);
      is($res->designator, $t->{des}, "$t->{name}, allow_embedded '$ae' designator ok: " . ($res->designator // 'undef'));
      is($res->designator_std, $t->{des_std}, "$t->{name}, allow_embedded '$ae' designator_std ok: " . ($res->designator_std // 'undef'));
      is($res->after, $t->{after} // '', "$t->{name}, allow_embedded '$ae' after ok: " . ($res->after // 'undef'));
      $i += 4;
    }

    # Should NOT match with any @$ae_nonmatch
    for my $ae (@$ae_nonmatch) {
      my $res = $bcd->split_designator($t->{name}, allow_embedded => $ae);
      is($res->before, $t->{name}, "$t->{name}, allow_embedded '$ae' before ok: " . $res->before);
      is($res->designator, '', "$t->{name}, allow_embedded '$ae' designator ok: " . ($res->designator // 'undef'));
      is($res->designator_std, '', "$t->{name}, allow_embedded '$ae' designator_std ok: " . ($res->designator_std // 'undef'));
      is($res->after, '', "$t->{name}, allow_embedded '$ae' after ok: " . ($res->after // 'undef'));
      $i += 4;
    }
  }
  else {
    $i += 12;
  }
}

done_testing;

