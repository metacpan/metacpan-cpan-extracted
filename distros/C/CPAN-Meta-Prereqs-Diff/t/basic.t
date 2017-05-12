
use strict;
use warnings;

use Test::More tests => 27;

use CPAN::Meta::Prereqs::Diff;

our $context = "";

sub my_subtest ($$) {

  #note "Beginning: $_[0] ]---";
  local $context = " ($_[0])";
  $_[1]->();

  #note "Ending: $_[0] ]---";
}

my_subtest "Addition" => sub {
  my $diff = CPAN::Meta::Prereqs::Diff->new(
    new_prereqs => { runtime => { requires => { "Some::Dependency" => "1.0" } } },
    old_prereqs => { runtime => { requires => {} } },
  );
  my @diffs = $diff->diff;
  is( scalar @diffs, 1, "1 Diff" );
  ok( $diffs[0]->is_addition, "Is addition$context" );
  ok( !$diffs[0]->is_removal, "Not removal$context" );
  ok( !$diffs[0]->is_change,  "Not change$context" );
  note $diffs[0]->describe;
};
my_subtest "Removal" => sub {
  my $diff = CPAN::Meta::Prereqs::Diff->new(
    old_prereqs => { runtime => { requires => { "Some::Dependency" => "1.0" } } },
    new_prereqs => { runtime => { requires => {} } },
  );
  my @diffs = $diff->diff;
  is( scalar @diffs, 1, "1 Diff" );
  ok( !$diffs[0]->is_addition, "Not addition$context" );
  ok( $diffs[0]->is_removal,   "Is removal$context" );
  ok( !$diffs[0]->is_change,   "Not change$context" );
  note $diffs[0]->describe;

};
my_subtest "No Change" => sub {
  my $diff = CPAN::Meta::Prereqs::Diff->new(
    old_prereqs => { runtime => { requires => { "Some::Dependency" => "1.0" } } },
    new_prereqs => { runtime => { requires => { "Some::Dependency" => "1.0" } } },
  );
  my @diffs = $diff->diff;
  is( scalar @diffs, 0, "0 Diffs$context" );

};
my_subtest "Change upgrade Change" => sub {
  my $diff = CPAN::Meta::Prereqs::Diff->new(
    old_prereqs => { runtime => { requires => { "Some::Dependency" => "0.9" } } },
    new_prereqs => { runtime => { requires => { "Some::Dependency" => "1.0" } } },
  );
  my @diffs = $diff->diff;
  is( scalar @diffs, 1, "1 Diffs$context" );
  ok( !$diffs[0]->is_addition, "Not addition$context" );
  ok( !$diffs[0]->is_removal,  "Not removal$context" );
  return unless ok( $diffs[0]->is_change, "Is change$context" );
  ok( $diffs[0]->is_upgrade,    "Is Upgrade$context" );
  ok( !$diffs[0]->is_downgrade, "Not Downgrade$context" );
  note $diffs[0]->describe;

};
my_subtest "Change downgrade Change" => sub {
  my $diff = CPAN::Meta::Prereqs::Diff->new(
    old_prereqs => { runtime => { requires => { "Some::Dependency" => "1.0" } } },
    new_prereqs => { runtime => { requires => { "Some::Dependency" => "0.9" } } },
  );
  my @diffs = $diff->diff;
  is( scalar @diffs, 1, "1 Diffs$context" );
  ok( !$diffs[0]->is_addition, "Not addition$context" );
  ok( !$diffs[0]->is_removal,  "Not removal$context" );
  return unless ok( $diffs[0]->is_change, "Is change$context" );
  ok( !$diffs[0]->is_upgrade,  "Not Upgrade$context" );
  ok( $diffs[0]->is_downgrade, "Is Downgrade$context" );
  note $diffs[0]->describe;

};

my_subtest "Change mixed Change" => sub {
  my $diff = CPAN::Meta::Prereqs::Diff->new(
    old_prereqs => { runtime => { requires => { "Some::Dependency" => "<1.0" } } },
    new_prereqs => { runtime => { requires => { "Some::Dependency" => ">0.9" } } },
  );
  my @diffs = $diff->diff;
  is( scalar @diffs, 1, "1 Diffs$context" );
  ok( !$diffs[0]->is_addition, "Not addition$context" );
  ok( !$diffs[0]->is_removal,  "Not removal$context" );
  return unless ok( $diffs[0]->is_change, "Is change$context" );
  ok( !$diffs[0]->is_upgrade,   "Not Upgrade$context" );
  ok( !$diffs[0]->is_downgrade, "Not Downgrade$context" );
  note $diffs[0]->describe;

};
