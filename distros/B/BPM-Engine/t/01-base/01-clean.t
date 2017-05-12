use strict;
use warnings;
use Test::More;
use Test::Exception;
use Class::MOP;
use File::Find;

my @modules;
find( sub { push @modules, $File::Find::name if /\.pm$/ }, './lib' );
@modules = sort map { s!/!::!g; s/\.pm$//; s/\.:://; s/^lib:://; $_ } grep { !/ShipIt/} @modules; ## no critic (MutatingListFunctions)

ok scalar(@modules), 'Have some modules';
foreach my $module (@modules) {
    lives_ok { Class::MOP::load_class($module) } "Load $module";
    next if $module =~ /YAMLWorkflowLoader/; # base Class::Workflow::YAML is not clean
    ok ! $module->can('has'), "$module is clean";
    ok ! $module->can('requires'), "$module is clean";
}

done_testing;
