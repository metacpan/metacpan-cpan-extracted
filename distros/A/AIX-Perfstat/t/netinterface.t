#
#
# Copyright (C) 2006 by Richard Holden
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#######################################################################

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl netinterface.t'

#########################

use Test::More;
BEGIN { use_ok('AIX::Perfstat') };

#########################

use AIX::Perfstat;

########################
#Compute number of tests to run.

plan tests => 18;

########################


#Using anonymous blocks to avoid polluting the symbol table.
{
	my $x = AIX::Perfstat::netinterface_total();
	ok( defined $x, 'netinterface_total returned a defined value');
	ok( exists $x->{'number'} );
	ok( exists $x->{'ipackets'} );
	cmp_ok( $x->{'ipackets'}, '>=', 0, 'netinterface_total ipackets >= 0' );
}

cmp_ok(AIX::Perfstat::netinterface_count(), '>=', 0, 'netinterface_count >= 0');
cmp_ok(AIX::Perfstat::netinterface_count(), '==', `ifconfig -l | sed -e 's/ /\\\n/g' | wc -l`, 'netinterface_count agrees with the commandline ifconfig count of network interfaces');

{
	my $netinterface_count = AIX::Perfstat::netinterface_count();
	cmp_ok(@{AIX::Perfstat::netinterface()}+0, '==', 1, 'netinterface called with default arguments returns 1 record');
	cmp_ok(@{AIX::Perfstat::netinterface($netinterface_count)} + 0, '==', $netinterface_count, 'netinterface called with netinterface_count for desired number returns netinterface_count records');
	cmp_ok(@{AIX::Perfstat::netinterface($netinterface_count+1)} +0, '==', $netinterface_count, 'netinterface called with netinterface_count +1 for desired number returns netinterface_count records');
	ok( !defined(AIX::Perfstat::netinterface(1,"Foo")), 'netinterface called with name that does not exist returns undef');

	SKIP: {
		 skip "These tests rely on having more than one netinterface\n", 2 if ($netinterface_count < 2);

		 my $name = "";
		 my $x = AIX::Perfstat::netinterface(1,$name);
		 if ($netinterface_count == 2)
		 {
			  #We probably only have en0 and lo0
			  cmp_ok($name, 'eq', "lo0", 'netinterface called with a variable of the empty string returns the second netinterface name in $name');

			  $name = "en0";
			  $x = AIX::Perfstat::netinterface(1,$name);
			  cmp_ok($name, 'eq', "lo0", 'netinterface called with a variable of the first netinterface name returns the second netinterface name in $name');
		 }
		 else
		 {
			  cmp_ok($name, 'eq', "en1", 'netinterface called with a variable of the empty string returns the second netinterface name in $name');

			  $name = "en0";
			  $x = AIX::Perfstat::netinterface(1,$name);
			  cmp_ok($name, 'eq', "en1", 'netinterface called with a variable of the first netinterface name returns the second netinterface name in $name');
		 }
	}
	#setup name so we are asking for the last netinterface.
	my $name = "";
	my $x = AIX::Perfstat::netinterface($netinterface_count-1,$name);

	$x = AIX::Perfstat::netinterface(1,$name);
	cmp_ok($name, 'eq', "", 'netinterface called with a variable of the last netinterface name returns the empty string in $name');

	$name = "";
	$x = AIX::Perfstat::netinterface($netinterface_count, $name);
	cmp_ok($name, 'eq', "", 'netinterface called with the empty string and requesting all netinterfaces returns the empty string in $name');
}

eval { AIX::Perfstat::netinterface(1,"aaabbbcccdddeeefffggghhhiiijjjkkklllmmmnnnooopppqqqrrrssstttuuu") };
ok( !$@, 'netinterface called with name with 63 characters does not cause die to be called');
eval { AIX::Perfstat::netinterface(1,"aaabbbcccdddeeefffggghhhiiijjjkkklllmmmnnnooopppqqqrrrssstttuuuv") };
ok( $@, 'netinterface called with name with 64 characters does not cause die to be called');

eval { AIX::Perfstat::netinterface(-1) };
ok( $@, 'netinterface called with -1 for desired_number causes a die.');
eval { AIX::Perfstat::netinterface(0) };
ok( $@, 'netinterface called with 0 for desired_number causes a die.');
