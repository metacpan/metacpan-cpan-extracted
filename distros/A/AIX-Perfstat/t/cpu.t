#
#
# Copyright (C) 2006 by Richard Holden
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#######################################################################

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl cpu.t'

#########################

use warnings;
use strict;

use Test::More;
BEGIN { use_ok('AIX::Perfstat') };

#########################


use AIX::Perfstat;

########################
#Compute number of tests to run.

plan tests => 20;

########################


#Using anonymous blocks to avoid polluting the symbol table.
{
	my $x = AIX::Perfstat::cpu_total();
	ok( defined $x, 'cpu_total returned a defined value');
	ok( exists $x->{'ncpus'} );
	ok( exists $x->{'description'} );
	ok( exists $x->{'processorHZ'} );
	ok( exists $x->{'loadavg'} );
	cmp_ok( $x->{'processorHZ'}, '>', 0, 'cpu_total processorHZ > 0' );
}

cmp_ok(AIX::Perfstat::cpu_count(), '>=', 1, 'cpu_count must be at least 1');
cmp_ok(AIX::Perfstat::cpu_count(), '==', `lsdev -C -c processor | wc -l`, 'cpu_count agrees with the commandline lsdev count of processors');

{
	my $cpu_count = AIX::Perfstat::cpu_count();
	cmp_ok(@{AIX::Perfstat::cpu()}+0, '==', 1, 'cpu called with default arguments returns 1 record');
	cmp_ok(@{AIX::Perfstat::cpu($cpu_count)} + 0, '==', $cpu_count, 'cpu called with cpu_count for desired number returns cpu_count records');
	cmp_ok(@{AIX::Perfstat::cpu($cpu_count+1)} +0, '==', $cpu_count, 'cpu called with cpu_count +1 for desired number returns cpu_count records');
	ok( !defined(AIX::Perfstat::cpu(1,"Foo")), 'cpu called with name that does not exist returns undef');

	SKIP: {
		 skip "These tests rely on having more than one processor\n", 2 if ($cpu_count < 2);

		 my $name = "";
		 my $x = AIX::Perfstat::cpu(1,$name);
		 cmp_ok($name, 'eq', "proc1", 'cpu called with a variable of the empty string returns the second processor name in $name');

		 $name = "proc0";
		 $x = AIX::Perfstat::cpu(1,$name);
		 cmp_ok($name, 'eq', "proc1", 'cpu called with a variable of the first processor name returns the second processor name in $name');
	}
	#setup name so we are asking for the last processor.
	my $name = "proc".($cpu_count-1);
	my $x = AIX::Perfstat::cpu(1,$name);
	cmp_ok($name, 'eq', "", 'cpu called with a variable of the last processor name returns the empty string in $name');

	$name = "";
	$x = AIX::Perfstat::cpu($cpu_count, $name);
	cmp_ok($name, 'eq', "", 'cpu called with the empty string and requesting all processors returns the empty string in $name');
}

eval { AIX::Perfstat::cpu(1,"aaabbbcccdddeeefffggghhhiiijjjkkklllmmmnnnooopppqqqrrrssstttuuu") };
ok( !$@, 'cpu called with name with 63 characters does not cause die to be called');
eval { AIX::Perfstat::cpu(1,"aaabbbcccdddeeefffggghhhiiijjjkkklllmmmnnnooopppqqqrrrssstttuuuv") };
ok( $@, 'cpu called with name with 64 characters does not cause die to be called');


eval { AIX::Perfstat::cpu(-1) };
ok( $@, 'cpu called with -1 for desired_number causes a die.');
eval { AIX::Perfstat::cpu(0) };
ok( $@, 'cpu called with 0 for desired_number causes a die.');
