use strict;
use warnings;

use Test::More;

# FILENAME: attach.t
# CREATED: 07/24/14 17:13:46 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test attaching data to a release
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
plan tests => 4;
local $TODO;
if ( not eval "CPAN::Changes->VERSION(q[0.500]); 1" ) {
  $TODO = "Legacy serialization scheme";
}

use Test::Differences qw( eq_or_diff );
use CPAN::Changes::Group::Dependencies::Stats;
use CPAN::Changes::Release;

eq_or_diff( $sample_changes->serialize,                                       $sample,         'Guard: Whole file same' );
eq_or_diff( $sample_changes->release('1.7.5')->serialize,                     $release_sample, 'Guard: release same' );
eq_or_diff( $sample_changes->release('1.7.5')->get_group('Group')->serialize, $group_sample,   'Guard: group same' );

my $release = CPAN::Changes::Release->new(
  version => '0.01',
  date    => '2009-07-06',
);

my $stats = CPAN::Changes::Group::Dependencies::Stats->new(
  old_prereqs => {},
  new_prereqs => { runtime => { requires => { 'Moo' => 2 } } },
);

my $other_stats = CPAN::Changes::Group::Dependencies::Stats->new(
  name        => "Other::Name",
  old_prereqs => {},
  new_prereqs => {},
);

$release->attach_group($stats)       if $stats->has_changes;
$release->attach_group($other_stats) if $other_stats->has_changes;

my $string = $release->serialize;

eq_or_diff $string, <<'EOF', 'Serialize as expected';
0.01 2009-07-06
 [Dependencies::Stats]
 - runtime: +1
EOF
