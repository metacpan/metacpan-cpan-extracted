#
#
# Copyright (C) 2006 by Richard Holden
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#######################################################################

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl memory.t'

#########################

use Test::More;
BEGIN { use_ok('AIX::Perfstat') };

#########################

use AIX::Perfstat;

########################
#Compute number of tests to run.

plan tests => 2;

########################


#Using anonymous blocks to avoid polluting the symbol table.
{
	my $x = AIX::Perfstat::memory_total();
	ok( defined $x, 'memory_total returned a defined value');
	ok( exists $x->{'virt_total'} );
}
