use strict;
use warnings;

use Test::More;

# FILENAME: format.t
# CREATED: 07/26/14 20:47:10 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test format is expected

use CPAN::Changes;

my ( $sample_version, $sample, $release_sample, $group_sample, $sample_changes );

BEGIN {
  $sample_version = '0.500001';
  $sample         = <<'EOF';
1.7.5 2013-08-01T09:48:11Z
 [Group]
 - Child Entry Line 1
 - Child Entry Line 2
EOF
  $release_sample = <<'EOF';
1.7.5 2013-08-01T09:48:11Z
 [Group]
 - Child Entry Line 1
 - Child Entry Line 2
EOF
  $group_sample = <<'EOF';
[Group]
 - Child Entry Line 1
 - Child Entry Line 2
EOF
  $sample_changes = CPAN::Changes->load_string($sample);
  return if $ENV{AUTHOR_TESTING};
  return
        if $sample_changes->serialize eq $sample
    and $sample_changes->release('1.7.5')->serialize eq $release_sample
    and $sample_changes->release('1.7.5')->get_group('Group')->serialize eq $group_sample;
  plan
    skip_all => sprintf "Serialization scheme of CPAN::Changes %s is different to that of %s",
    $CPAN::Changes::VERSION, $sample_version;
}
plan tests => 6;
local $TODO;
if ( not eval "CPAN::Changes->VERSION(q[0.500]); 1" ) {
  $TODO = "Legacy serialization scheme";
}
use CPAN::Changes::Release;
use CPAN::Changes::Group;
use CPAN::Meta::Prereqs::Diff;
use CPAN::Changes::Group::Dependencies::Details;
use Test::Differences qw( eq_or_diff );

eq_or_diff( $sample_changes->serialize,                                       $sample,         'Guard: Whole file same' );
eq_or_diff( $sample_changes->release('1.7.5')->serialize,                     $release_sample, 'Guard: release same' );
eq_or_diff( $sample_changes->release('1.7.5')->get_group('Group')->serialize, $group_sample,   'Guard: group same' );

my $release = CPAN::Changes::Release->new(
  version => '0.01',
  date    => '2014-07-26',
);

my $diff = CPAN::Meta::Prereqs::Diff->new(
  old_prereqs => {
    runtime => {
      requires => {},
    }
  },
  new_prereqs => {
    runtime => {
      requires   => { 'Moo' => '1.0' },
      suggests   => { 'Moo' => '1.2' },
      recommends => { 'Moo' => '1.3' },
    },
    develop => {
      requires   => { 'Moo' => '1.0' },
      suggests   => { 'Moo' => '1.2' },
      recommends => { 'Moo' => '1.3' },
    }
  },
);

my $details_a = CPAN::Changes::Group::Dependencies::Details->new(
  all_diffs   => [ $diff->diff ],
  change_type => 'Added',
  phase       => 'runtime',
  type        => 'requires',
);

my $details_b = CPAN::Changes::Group::Dependencies::Details->new(
  all_diffs   => [ $diff->diff ],
  change_type => 'Added',
  phase       => 'runtime',
  type        => 'recommends',
);

$details_b->serialize;

{
  my $expected = <<'EOF';
[Added / runtime requires]
 - Moo 1.0
EOF

  eq_or_diff( $details_a->serialize, $expected, 'Group serialization' );
}
$release->attach_group($details_a) if $details_a->has_changes;
{
  my $expected = <<'EOF';
0.01 2014-07-26
 [Added / runtime requires]
 - Moo 1.0
EOF

  eq_or_diff( $release->serialize, $expected, 'Release serialization' );
}
pass("ok");
