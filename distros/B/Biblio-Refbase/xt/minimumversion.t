#!perl
#
#  xt/minimumversion.t 0.01 hma Sep 16, 2010
#
#  Does your code require newer perl than you think?
#

use strict;
use warnings;

use Test::More;

#  adopted Best Practice for Author Tests, as proposed by Adam Kennedy
#  http://use.perl.org/~Alias/journal/38822

plan skip_all => 'Author tests not required for installation'
  unless $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING};

plan skip_all => 'This test does not run in taint mode'
  if $] >= 5.008 &&  ${^TAINT} > 0;

my %MODULES = (
  'Perl::MinimumVersion' => '1.25',
  'Test::MinimumVersion' => '0.101080',
);

while (my ($module, $version) = each %MODULES) {
  $module .= ' ' . $version if $version;
  eval "use $module";
  next unless $@;

  die "Could not load required release testing module $module:\n$@"
    if $ENV{RELEASE_TESTING};

  plan skip_all => "$module required";
}

all_minimum_version_from_metayml_ok();
