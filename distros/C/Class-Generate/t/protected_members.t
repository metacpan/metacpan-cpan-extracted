#! /usr/local/bin/perl

use lib qw(t);
use warnings;
use strict;
use Test_Framework;
use Class::Generate qw(&class &subclass);

use vars qw($o);
Test {
    class Parent => {
	public_m => "\$",
	protected_m => { type => "\$", protected => 1 },
	protected_am => { type => '@', protected => 1 },
	protected_hm => { type => '%', protected => 1 },
	'&undef_in_parent1' => '&undef_protected_m;',
	'&undef_in_parent2' => '&undef_protected_m();',
	'&test_parent_array_accessors' => <<'EOS',
{
    @protected_am = (1, 2, 3);
    die 'Wrong size' unless &protected_am_size == 2;
    die 'Wrong last element' unless &last_protected_am == 3;
    &add_protected_am(4);
    die 'Funny add' unless Arrays_Equal([@protected_am], [1, 2, 3, 4]);
    return;
}
EOS
	'&test_parent_hash_accessors' => <<'EOS',
{
    %protected_hm = ( a => 1, b => 2, c => 3 );
    die 'Wrong keys' unless Arrays_Equal([sort { $a cmp $b } &protected_hm_keys], [qw(a b c)]);
    die 'Wrong values' unless Arrays_Equal([sort { $a <=> $b } &protected_hm_values], [qw(1 2 3)]);
    &delete_protected_hm('a');
    die 'Wrong keys' unless Arrays_Equal([sort { $a cmp $b } &protected_hm_keys], [qw(b c)]);
    die 'Wrong values' unless Arrays_Equal([sort { $a <=> $b } &protected_hm_values], [qw(2 3)]);
    return;
}
EOS
	new => { style => 'positional public_m' }
    }, -use => 'Test_Framework'
};

Test { ($o = (new Parent 1))->public_m == 1 };	# Object creation and access of public members should still work...
Test_Failure { $o->protected_m == 1 };		# But you can't access a protected member...
Test_Failure { defined $o->protected_am(0) };
Test_Failure { defined $o->protected_hm(0) };
Test_Failure { $o->undef_protected_m };		# Or use its accessors.
Test_Failure { $o->add_protected_am(1) };
Test_Failure { defined $o->protected_am_size };
Test_Failure { defined $o->last_protected_am };
Test_Failure { defined $o->protected_hm_keys };
Test_Failure { defined $o->protected_values };
Test_Failure { defined $o->delete_protected_hm(1) };

Test { ! defined $o->test_parent_array_accessors };
Test { ! defined $o->test_parent_hash_accessors };

Test {
    subclass Child => {
	'&sub' => '$public_m += 1; $protected_m -= 1 if defined $protected_m;',
	'&rpm' => 'return $protected_m;',
	'&undef_in_child1' => '&undef_protected_m;',
	'&undef_in_child2' => '&undef_protected_m();',
	new => { style => 'positional', post => '$protected_m = 3;' }
    }, -parent => 'Parent'
};

Test { (new Child 1)->rpm == 3 };
Test { $o = new Child 1; $o->sub; $o->public_m == 2 && $o->rpm == 2 };
Test { $o = new Child 1; $o->undef_in_child1; ! defined $o->rpm };
Test { $o = new Child 1; $o->undef_in_child2; ! defined $o->rpm };
Test { $o = new Child 1; $o->undef_in_parent1; ! defined $o->rpm };
Test { $o = new Child 1; $o->undef_in_parent2; ! defined $o->rpm };

Test {
    class Array_Parent => [
	prot_amem => { type => '@', protected => 1 },
	prot_hmem => { type => '%', protected => 1 },
	new => { post => '@prot_amem = (1, 2, 3);' }
    ], -exclude => 'undef copy equal';
};
Test {
    subclass Array_Child => [
	'&set_hsub' => '$prot_hmem{$_[0]} = $_[1];',
	'&set_asub' => '$prot_amem[$_[0]] = $_[1];',
	'&get_sub' => <<'EOS'
{
    my $hmem = '{' . join(',', map "$_=>$prot_hmem{$_}", sort { $a cmp $b } keys %prot_hmem) . '}';
    my $amem = '[' . join(',', @prot_amem) . ']';
    return "amem = $amem; hmem = $hmem";
}
EOS
    ], -parent => 'Array_Parent', -exclude => 'undef copy equal';
};

Test { $o = new Array_Child };
Test { $o->get_sub eq 'amem = [1,2,3]; hmem = {}' };
Test { $o->set_asub(3, 4); $o->get_sub eq 'amem = [1,2,3,4]; hmem = {}' };
Test { $o->set_hsub(1,1); $o->set_hsub(2,2); $o->get_sub eq 'amem = [1,2,3,4]; hmem = {1=>1,2=>2}' };

Test {
    class Parent_With_Default => {
	prot_smem => { type => '$', default => 1, protected => 1 },
	'&smem' => 'return $prot_smem;'
    };
    subclass Child_Of_Parent_With_Default => {
	'&also_smem' => 'return $prot_smem;'
    }, -parent => 'Parent_With_Default';
    (new Parent_With_Default)->smem == 1 && (new Child_Of_Parent_With_Default)->also_smem == 1
};

Report_Results;
