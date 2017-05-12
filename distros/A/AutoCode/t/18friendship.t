use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests => 4}

use ContactSchema;
use AutoCode::ModuleFactory;
my $module_factory = AutoCode::ModuleFactory->new(
    -schema => ContactSchema->new  (-package_prefix => 'MyContact')
);
ok(1);

my $person_pkg = $module_factory->make_module('Person');

ok ref(UNIVERSAL::can($person_pkg, 'get_ContactGroups')), 'CODE';
my $group_pkg=$module_factory->make_module('ContactGroup');
ok ref(UNIVERSAL::can($group_pkg, 'get_Persons')), 'CODE';

my ($group1, $group)=map{$group_pkg->new(-name=>$_)} qw(group1 group2);

my $person=$person_pkg->new(-first_name=>'foo');

$person->add_ContactGroup($group1);

my %persons_by_group = $group1->get_Persons;

ok exists $persons_by_group{$person};

