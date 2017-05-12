use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests=> 15;}
use ContactSchema;

use ContactTestData;

use AutoCode::ModuleFactory;
ok(1);
my $module_factory = AutoCode::ModuleFactory->new(
    -schema => ContactSchema->new  (-package_prefix => 'MyContact')
);

my $module_package = $module_factory->make_module('Person');

use AutoCode::SymbolTableUtils;

ok AutoCode::SymbolTableUtils::PKG_exists_in_ST($module_package);

ok ! AutoCode::SymbolTableUtils::PKG_exists_in_ST('Bio::Root::Root');
ok $module_package, 'MyContact::Virtual::Person';
my $instance = $module_package->new(
    @ContactTestData::args
);

ok(ref($instance->can('_initialize')), 'CODE');
ok($instance->first_name, $ContactTestData::first_name);
ok($instance->last_name, $ContactTestData::last_name);

my @aliases=$instance->get_aliases;
ok scalar(@aliases), 2;


my @emails=$instance->get_emails;
ok(scalar @emails, 2);
$instance->remove_emails;
ok(scalar $instance->get_emails, 0);
$instance->add_email('foobar.com');
ok(($instance->get_emails)[0], 'foobar.com');

ok ref($instance->can('first_name')), 'CODE';

ok ! $instance->can('name');

my $buddy_module=$module_factory->make_module('Buddy');
my $buddy=$buddy_module->new;
ok UNIVERSAL::isa($buddy, 'MyContact::Virtual::Person');
ok ref($instance->can('first_name')), 'CODE';

