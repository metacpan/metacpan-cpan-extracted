package UNIVERSAL;
sub new { bless {}, $_[0] };
sub DESTROY {}

sub Base1::b1 { print "Called b1\n" }
sub Base1::dump_info { print "Called dump_info 1\n" }

sub Base2::b2 { print "Called b2\n" }
sub Base2::dump_info { print "Called dump_info 2\n" }

package Derived;
use Class::Delegation
	send => 'dump_info',
	  to => -ALL,
	  
	send => -OTHER,
	  to => 'base1',

	send => -OTHER,
	  to => 'base2',
	;

# sub ::DEBUG { 1 };

sub new {
	my ($class, %named_args) = @_;
	bless { base1 => Base1->new(%named_args),
		base2 => Base2->new(%named_args),
	      }, $class;
}


package main;

my $obj = Derived->new();

$obj->dump_info();
$obj->b1();
$obj->b2();
