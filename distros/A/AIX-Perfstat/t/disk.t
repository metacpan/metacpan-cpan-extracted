#
#
# Copyright (C) 2006 by Richard Holden
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#######################################################################

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl disk.t'

#########################

use Test::More;
BEGIN { use_ok('AIX::Perfstat') };

#########################


use AIX::Perfstat;

########################
#Compute number of tests to run.

plan tests => 15; #18

########################


#Using anonymous blocks to avoid polluting the symbol table.
{
	my $x = AIX::Perfstat::disk_total();
	ok( defined $x, 'disk_total returned a defined value');
	ok( exists $x->{'number'} );
	ok( exists $x->{'size'} );
	cmp_ok( $x->{'number'}, '>', 0, 'disk_total number > 0' );
}

cmp_ok(AIX::Perfstat::disk_count(), '>=', 1, 'disk_count must be at least 1');
cmp_ok(AIX::Perfstat::disk_count(), '==', `lsdev -C -t scsd | wc -l` + `lsdev -C -t osdisk | wc -l`, 'disk_count agrees with the commandline lsdev count of disks');

{
	my $disk_count = AIX::Perfstat::disk_count();
	cmp_ok(@{AIX::Perfstat::disk()}+0, '==', 1, 'disk called with default arguments returns 1 record');
	cmp_ok(@{AIX::Perfstat::disk($disk_count)} + 0, '==', $disk_count, 'disk called with disk_count for desired number returns disk_count records');
	cmp_ok(@{AIX::Perfstat::disk($disk_count+1)} +0, '==', $disk_count, 'disk called with disk_count +1 for desired number returns disk_count records');
	ok( !defined(AIX::Perfstat::disk(1,"Foo")), 'disk called with name that does not exist returns undef');

#	SKIP: {
#		 skip "These tests rely on having more than one disk\n", 2 if ($disk_count < 2);
#
#		 my $name = "";
#		 my $x = AIX::Perfstat::disk(1,$name);
#		 cmp_ok($name, 'eq', "hdisk1", 'disk called with a variable of the empty string returns the second disk name in $name');

#		 $name = "hdisk0";
#		 $x = AIX::Perfstat::disk(1,$name);
#		 cmp_ok($name, 'eq', "hdisk1", 'disk called with a variable of the first disk name returns the second disk name in $name');
#	}
#	#setup name so we are asking for the last disk.
#	my $name = "";
#	my $x = AIX::Perfstat::disk($disk_count-1,$name);

#	$x = AIX::Perfstat::disk(1,$name);
#	cmp_ok($name, 'eq', "", 'disk called with a variable of the last disk name returns the empty string in $name');

	$name = "";
	my $x = AIX::Perfstat::disk($disk_count, $name);
	cmp_ok($name, 'eq', "", 'disk called with the empty string and requesting all disks returns the empty string in $name');
}

eval { AIX::Perfstat::disk(1,"aaabbbcccdddeeefffggghhhiiijjjkkklllmmmnnnooopppqqqrrrssstttuuu") };
ok( !$@, 'disk called with name with 63 characters does not cause die to be called');
eval { AIX::Perfstat::disk(1,"aaabbbcccdddeeefffggghhhiiijjjkkklllmmmnnnooopppqqqrrrssstttuuuv") };
ok( $@, 'disk called with name with 64 characters does not cause die to be called');

eval { AIX::Perfstat::disk(-1) };
ok( $@, 'disk called with -1 for desired_number causes a die.');
eval { AIX::Perfstat::disk(0) };
ok( $@, 'disk called with 0 for desired_number causes a die.');
