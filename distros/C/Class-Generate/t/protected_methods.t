#! /usr/local/bin/perl

use lib qw(.. t);
use warnings;
use strict;
use Test_Framework;
use Class::Generate qw(&class &subclass);

# Test user-defined protected methods, and use of accessors of
# protected members.

use vars qw($o);

Test {
    class Parent => {
	mem => "\$",
	prot_mem => { type => '@', protected => 1 },
	priv_mem => { type => '%', private => 1 },
	'&meth' => 'return $#prot_mem >= 0 ? $prot_mem[0] + 1 : $mem + 2',
	'&prot_meth_1' => {
	    body => 'return $#prot_mem >= 0 ? $prot_mem[0] + 2 : $mem + 2',
	    protected => 1
	},
	'&prot_meth_2' => {
	    body => '$priv_mem{$mem} = $#prot_mem;',
	    protected => 1
	},
	'&set_prot_mem' => '@prot_mem = @_;',
        '&use_prot_meths' => '@prot_mem = localtime;
			      &prot_meth_2();
			      $priv_mem{&prot_meth_1} = &last_prot_mem;
			      return 1;',
	new => { style => 'positional mem' }
    }
};

Test { ($o = (new Parent 1))->mem == 1 };		# Object creation and access of public members should still work...
Test { $o->meth == 3 };					# Access of protected member works from public method.
Test {							# Ditto.
    $o->set_prot_mem(2, 3, 4);
    $o->meth == 3;
};
Test { $o->use_prot_meths };				# Ditto.
Test_Failure { (new Parent 1)->prot_meth_1 == 1 };	# But you can't access a protected method.

Test {
    subclass Child => {
	cmem => { type => "\$", assert => '&prot_meth_1 != $cmem && &prot_meth_1() != $cmem' },
	new => { style => 'positional cmem', post => '@prot_mem = (3, 4, 5);' }
    }, -parent => 'Parent'
};

Test { ($o = (new Child 1, 2))->cmem == 1 && $o->mem == 2 };
Test { ! defined $o->cmem(10) };
Test { $o->use_prot_meths };
Test_Failure { $o->cmem(5) };				# The assertion should fail.
Test_Failure { $o->prot_meth_1 };			# You can't access a protected method from a child, either.
Test_Failure { $o->prot_meth_2 };			# Ditto.

Report_Results;
