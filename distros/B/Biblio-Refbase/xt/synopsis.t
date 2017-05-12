#!perl -T
#
#  xt/synopsis.t 0.01 hma Sep 16, 2010
#
#  Test your SYNOPSIS code
#

use strict;
use warnings;

use Test::More;

#  adopted Best Practice for Author Tests, as proposed by Adam Kennedy
#  http://use.perl.org/~Alias/journal/38822

plan skip_all => 'Author tests not required for installation'
  unless $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING};

my $MIN_PERL = 5.008_001;

plan skip_all => "Perl $MIN_PERL required"
  if $] < $MIN_PERL;

my %MODULES = (
  'Test::Synopsis' => '0.05',
);

while (my ($module, $version) = each %MODULES) {
  $module .= ' ' . $version if $version;
  eval "use $module";
  next unless $@;

  die "Could not load required release testing module $module:\n$@"
    if $ENV{RELEASE_TESTING};

  plan skip_all => "$module required";
}

all_synopsis_ok();
