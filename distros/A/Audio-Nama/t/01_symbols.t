use Test2::Bundle::More;
use strict;

use Audio::Nama::Globals qw($ui);
use Audio::Nama::Log;
Audio::Nama::Log::initialize_logger();

package Foo;

use Audio::Nama::Globals qw(:all);

package main;

use Audio::Nama::Assign qw(:all);
# `make test'. After `make install' it should work as `perl 1.t'

#diag ("TESTING $0\n");

my @test_classes = qw( :: main:: main); # SKIP_PREPROC
use vars qw( $foo  @face $name %dict);
my @var_list = qw( $foo @face $name %dict);
my $struct2 = { 
	'$foo' => 2, 
	'$name' => 'John', 
	'@face' => [1,5,7,12],
	'%dict' => {fruit => 'melon'}
};	
my $struct = { 
	foo => 2, 
	name => 'John', 
	face => [1,5,7,12],
	dict => {fruit => 'melon'}
};	
for my $c (@test_classes) {
	#diag ("testing for class $c");

	assign (data => $struct, class => $c, vars => \@var_list);
		my $serialized = serialize( class => $c, vars => \@var_list);  

	my $expected = <<WANT;
{
   "dict" : {
      "fruit" : "melon"
   },
   "face" : [
      1,
      5,
      7,
      12
   ],
   "foo" : 2,
   "name" : "John"
}
WANT

	is( $foo, 2, "Scalar number assignment");
	is( $name, 'John', "Scalar string assignment");
	my $sum;
	map{ $sum += $_ } @face;
	is ($sum, 25, "Array assignment");
	is( $dict{fruit}, 'melon', "Hash assignment");
	is ($serialized, $expected, "Serialization round trip");
}
	my $nulls = { 
		foo => 2, 
		name => undef,
		face => [],
		dict => {},
	};	
	#diag("scalar array: ",scalar @face, " scalar hash: ", scalar %dict); 
	assign (data => $nulls, class => 'main', vars => \@var_list);
	is( scalar @face, 0, "Null array assignment");
	is( scalar %dict, 0, "Null hash assignment");
	

done_testing();
__END__