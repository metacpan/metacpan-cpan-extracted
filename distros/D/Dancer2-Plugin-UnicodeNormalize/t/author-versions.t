BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

use autodie;

use Test::More tests => 3;
use Module::Metadata;
use FindBin;

open my $changes, '<', "$FindBin::Bin/../Changes";
my ($changes_latest_version) = grep { s/^([0-9]+\.[0-9]+).*/$1/s } (<$changes>);
close $changes;

open my $dist, '<', "$FindBin::Bin/../dist.ini";
my ($dist_version) = grep { s/^version = ([0-9]+\.[0-9]+).*/$1/is } (<$dist>);
close $dist;

my $module = Module::Metadata->new_from_module('Dancer2::Plugin::UnicodeNormalize', collect_pod => 1);
(my $pod_version = $module->pod('VERSION')) =~ s/.*Version\ ([0-9]+\.[0-9]+).*/$1/is;

is $module->version, $pod_version, 'POD Version matches module $VERSION';
is $module->version, $dist_version, 'dist.ini version matches module $VERSION';
is $module->version, $changes_latest_version, 'Last Changes version matches module $VERSION';

