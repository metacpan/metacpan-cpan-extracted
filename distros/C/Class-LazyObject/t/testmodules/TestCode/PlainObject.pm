package TestCode::PlainObject;
#Not really a class.
#These are the construction-order-independent tests of Simple.

use strict;
use warnings;
use Test::More;

sub test_plain
{
	#takes 2 args:
	#  the class to test. The class's module must be 'use'd already.
	#  (optional). The class to test is-a this argument. Only neccessary if different from the class to test.
	
	my $own_class = shift;
	my $class = shift; #class to test
	my $isa = shift; #what the class is-a.
	
	$isa = defined($isa) ? $isa : $class;
	
	my $first_object = $class->new('first');
	isa_ok($first_object, $isa);
	
	my @methods = qw(get_string set_string);
	my $one_and_a_halfth_object = $class->new('one and a half');
	can_ok($one_and_a_halfth_object, @methods);
	
	my $one_and_two_thirdth_object = $class->new('one and one third');
	eval
	{
		local $SIG{'__DIE__'};#Just in case there's a die handler somewhere, in which case we don't want to trigger it.
		$one_and_two_thirdth_object->nonexistant_method();
	};
	like($@, qq{/Can't locate object method "nonexistant_method" via package /}, 'Nonexistant method call');
	
	my $second_object = $class->new('second');
	is($second_object->get_string(), 'second', 'get_string');
	
	$second_object->set_string('Monkies!');
	is($second_object->get_string(), 'Monkies!', 'set_string');
	
	my $third_object = $class->new('third');
	my $third_object_copy = $third_object;
	is($third_object_copy->get_string(), 'third', 'Copy, both unmodified, then get_string.');
	
	my $fifth_object = $class->new('fifth');
	my $fifth_object_copy = $fifth_object;
	$fifth_object->set_string('Pants: the last hope of humanity.');
	is($fifth_object_copy->get_string(), 'Pants: the last hope of humanity.', 'Copy, modify orig, then get_string.');
	
	my $seventh_object = $class->new('seventh');
	my $seventh_object_copy = $seventh_object;
	$seventh_object_copy->set_string('Inigo Montoya');
	is($seventh_object->get_string(), 'Inigo Montoya', 'Copy, modify copy, then get_string.');
	
	my $eighth_object = $class->new('eighth');
	is($eighth_object->callsub, (caller(0))[4], 'Caller is correct');
}

sub num_tests
{
	return 9;
}

1;