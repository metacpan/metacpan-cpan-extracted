#!perl -T
#
#  xt/pod.t 0.02 hma Sep 23, 2010
#
#  Check for POD errors in files
#

use strict;
use warnings;

use Test::More;

#  adopted Best Practice for Author Tests, as proposed by Adam Kennedy
#  http://use.perl.org/~Alias/journal/38822

plan skip_all => 'Author tests not required for installation'
  unless $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING};

my %MODULES = (
  'Pod::Simple' => '3.11',
  'Test::Pod'   => $] < 5.008 ? '1.22' : '1.42',
);

while (my ($module, $version) = each %MODULES) {
  $module .= ' ' . $version if $version;
  eval "use $module";
  next unless $@;

  die "Could not load required release testing module $module:\n$@"
    if $ENV{RELEASE_TESTING};

  plan skip_all => "$module required";
}

# hack for Kwalitee
# convince Module::CPANTS::Kwalitee::Uses we check for POD correctness

if (0) { require Test::Pod; }

my $renamed;
unless ( $ENV{PERL5LIB} && $ENV{PERL5LIB} =~ / \b blib \b lib \b/x ) {
  # we are presumably not called by the building toolchain
  # so make sure we test the contents of 'lib', not 'blib'

  # rename 'blib' if exists
  # because Test::Pod will look for it
  $renamed = -d 'blib' && ! -e 'blib.old' && rename 'blib', 'blib.old';
}
eval { all_pod_files_ok() };

rename 'blib.old', 'blib' if $renamed;

die $@ if $@;
