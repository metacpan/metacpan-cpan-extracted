#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 37;
use Test::Exception;

BEGIN { 
    use_ok('Date::Formatter')
}

use overload;

my $date = Date::Formatter->now();

can_ok($date, 'equal');
can_ok($date, 'notEqual');
can_ok($date, 'compare');
# test overloaded operators
ok(overload::Method($date, '=='), '... overload ==');
ok(overload::Method($date, '!='), '... overload !=');
ok(overload::Method($date, '<=>'), '... overload <=>');

my $other_date = $date;
# test the operators
ok($date == $other_date, '... they should logically be equal then');
ok(!($date != $other_date), '... they are equal so they shouldnt show up as not equal');	
cmp_ok(($date <=> $other_date), '==', 0, '... they are equal so they should produce 1 when compared with <=>');	
# test that the operators and the methods that implement 
# them produce the same results
cmp_ok(($date == $other_date), '==', $date->equal($other_date), '... they should logically be equal then');
cmp_ok(($date != $other_date), '==', $date->notEqual($other_date), '... they should logically be not equal then');
cmp_ok(($date <=> $other_date), '==', $date->compare($other_date), '... they should logically be the same');


can_ok($date, 'toString');
can_ok($date, 'stringValue');
# test overloaded operators
ok(overload::Method($date, '""'), '... overload ""');	
# check that it does what it is supposed to do
is($date->toString(), "$date", '... toString and "" operator should produce the same thing');

can_ok($date, 'add');
can_ok($date, 'subtract');
# check the overloaded operators
ok(overload::Method($date, '+'), '... overload +');	
ok(overload::Method($date, '-'), '... overload -');	

my $interval = Date::Formatter->createTimeInterval(seconds => 100);

# test the + operator

my $later_date = $date + $interval;
cmp_ok((($date->getSeconds() + 100) % 60), '==', $later_date->getSeconds(), 
	   '... later date is 10 minutes later');
	   
# test the compare functions again

ok(!($date == $later_date), '... they should logically not be equal then');
ok($date != $later_date, '... they should logically be not equal then');
cmp_ok(($date <=> $later_date), '==', -1, '... they should logically be the same');	 

# now go back to the - operator test	   
	   
my $former_date = $date - $interval;
cmp_ok((($date->getSeconds() - 100) % 60), '==', $former_date->getSeconds(), 
	   '... former date is 10 minutes before');  
	   
# check the compare functions	   
cmp_ok(($date <=> $former_date), '==', 1, '... they should logically be the same');		   
	
# check that the overload result in exceptions	      
throws_ok {
	$date + 10
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	10 + $date
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	$date - 10
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	10 - $date
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	(10 == $date)
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	($date == 10)
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	(10 != $date)
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	($date != 10)
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	(10 <=> $date)
} qr/^Illegal Operation/, '... this should throw an exception';

throws_ok {
	($date <=> 10)
} qr/^Illegal Operation/, '... this should throw an exception';
