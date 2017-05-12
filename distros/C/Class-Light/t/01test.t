package SubClass;
use base qw(Class::Light);

sub _init {
	my $self = shift;
	my $data = shift;
	$self->{'data'} = $data;
}

package main;
use Test::More 'no_plan';

my $str = "epiphany";
my $obj = SubClass->new($str);

# Test object creation
ok(defined($obj), "new() returned something");
ok($obj->isa('SubClass'), "object is of correct type");
ok($obj->isa('Class::Light'), "object inherits from parent");

# Test autovivified accessor methods
is($obj->getData, $str, "getData form of accessor works");
is($obj->get_data, $str, "get_data form of accessor works");
is($obj->get_Data, $str, "get_Data form of accessor works");

# Test mutator methods
$obj->setData(33);
is($obj->getData, 33, "setData form of mutator works");
$obj->set_data(42);
is($obj->getData, 42, "set_data form of mutator works");
$obj->set_Data(88);
is($obj->getData, 88, "set_Data form of mutator works");
