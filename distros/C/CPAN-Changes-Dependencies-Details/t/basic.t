
use strict;
use warnings;

use Test::More;
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

use Test::Differences qw( eq_or_diff_text eq_or_diff );

eq_or_diff( $sample_changes->serialize,                                       $sample,         'Guard: Whole file same' );
eq_or_diff( $sample_changes->release('1.7.5')->serialize,                     $release_sample, 'Guard: release same' );
eq_or_diff( $sample_changes->release('1.7.5')->get_group('Group')->serialize, $group_sample,   'Guard: group same' );

# FILENAME: basic.t
# CREATED: 08/01/14 22:58:44 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test basic functionality

require CPAN::Changes::Dependencies::Details;

my $instance = CPAN::Changes::Dependencies::Details->new( preamble => 'This is a test', );

$instance->add_release(
  {
    version     => '0.001',
    date        => '2014-01-01',
    new_prereqs => { runtime => { requires => { 'Moo' => '1.0' } } },
    old_prereqs => {},
  }
);
$instance->add_release(
  {
    version     => '0.002',
    date        => '2014-01-02',
    new_prereqs => { runtime => { requires => { 'Moo' => '1.2' } } },
    old_prereqs => { runtime => { requires => { 'Moo' => '1.0' } } },
  }
);
$instance->add_release(
  {
    version     => '0.003',
    date        => '2014-01-03',
    new_prereqs => {},
    old_prereqs => { runtime => { requires => { 'Moo' => '1.0' } } },
  }
);

use charnames qw( :full );

my $expected = <<"EOF";
This is a test

0.003 2014-01-03
 [Removed / runtime requires]
 - Moo 1.0

0.002 2014-01-02
 [Changed / runtime requires]
 - Moo 1.0\N{NO-BREAK SPACE}\N{RIGHTWARDS ARROW}\N{NO-BREAK SPACE}1.2

0.001 2014-01-01
 [Added / runtime requires]
 - Moo 1.0
EOF

my $result = $instance->serialize;    # returns chars

# eq_or_diff seems to hate literal chars, but seems to be fine with bytes.
# Look into this.
utf8::downgrade($result, 1) or utf8::encode($result);
utf8::downgrade($expected, 1) or utf8::encode($expected);

eq_or_diff_text( $result, $expected, 'Serialize works as intended' );
