#!perl -T

use strict;
use warnings;

use Test::More tests => 11 + 2 * 5 + 7;

use CPANPLUS::Dist::Gentoo::Maps;

*vc2g = sub {
 unshift @_, undef if @_ == 1;
 goto &CPANPLUS::Dist::Gentoo::Maps::version_c2g
};

is vc2g('1'),       '1.0.0',      "version_c2g('1')";
is vc2g('v1'),      '1',          "version_c2g('v1')";
is vc2g('..1'),     '1.0.0',      "version_c2g('..1')";
is vc2g('1.0'),     '1.0.0',      "version_c2g('1.0')";
is vc2g('v1.0'),    '1.0',        "version_c2g('v1.0')";
is vc2g('1._0'),    '1.0.0_rc',   "version_c2g('1._0')";
is vc2g('1_1'),     '11.0.0_rc',  "version_c2g('1_1')";
is vc2g('1_.1'),    '1.100.0_rc', "version_c2g('1_.1')";
is vc2g('1_.1._2'), '1.1.2_rc',   "version_c2g('1_.1._2')";
is vc2g('1_.1_2'),  '1.120.0_rc', "version_c2g('1_.1_2')";
is vc2g('1_.1_.2'), '1.1.2_rc',   "version_c2g('1_.1_.2')";

for my $test ([ '0.12' => '0.12' ], [ '0.1234' => '0.1234' ]) {
 my @dists = qw<
  ExtUtils-Install
  File-Path
  I18N-LangTags
  IO
  Time-Piece
 >;
 for my $dist (@dists) {
  is vc2g($dist, $test->[0]), $test->[1], "'version_c2g('$dist', '$test->[0]')";
 }
}

*pvc2g = \&CPANPLUS::Dist::Gentoo::Maps::perl_version_c2g;

is pvc2g('5'),       '5',       "perl_version_c2g('5')";
is pvc2g('5.1'),     '5.1',     "perl_version_c2g('5.1')";
is pvc2g('5.01'),    '5.10',    "perl_version_c2g('5.01')";
is pvc2g('5.10'),    '5.10',    "perl_version_c2g('5.10')";
is pvc2g('5.1.2'),   '5.1.2',   "perl_version_c2g('5.1.2')";
is pvc2g('5.01.2'),  '5.1.2',   "perl_version_c2g('5.01.2')";
is pvc2g('5.01002'), '5.10.20', "perl_version_c2g('5.01002')";
