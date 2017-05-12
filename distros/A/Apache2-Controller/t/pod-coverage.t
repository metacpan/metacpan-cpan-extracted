use strict;
use warnings FATAL => 'all';
use Test::More;
use YAML::Syck;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# Directives module cannot be loaded outside of mod_perl apache conf
my %exclude = map {($_=>1)} qw(
    Apache2::Controller::Directives
);

my @modules = grep !$exclude{$_}, all_modules();
#diag("modules testing:\n".Dump(\@modules));
plan tests => scalar(@modules);
pod_coverage_ok($_, "$_ is covered") for @modules;

#all_pod_coverage_ok();
