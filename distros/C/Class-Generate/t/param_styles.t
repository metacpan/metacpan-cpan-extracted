#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;
use Class::Generate qw(&class &subclass);

# Test the different constructor styles (key/value, positional, mix).

use constant SPEC => { type => "\$", readonly => 1, required => 1 };

sub members_valid($$) {
    my ($obj, $max) = @_;
    for ( my $i = 1; $i <=  $max; $i++ ) {
	return 0 if ! eval "\$obj->m$i == $i";
    }
    return 1;
}

Test {
    class KV_Class => {
	map(($_ => SPEC), qw(m1 m2 m3))
    };
    class Pos_Class => {
	map(($_ => SPEC), qw(m1 m2 m3)),
	new => { style => 'positional m1 m2 m3' }
    };
    class Mix_Class => {
	map(($_ => SPEC), qw(m1 m2 m3 m4)),
	new => { style => 'mix m1 m2' }
    };
    1
};

Test { members_valid KV_Class->new(m1 => 1, m2 => 2, m3 => 3), 3 };
Test { members_valid KV_Class->new(m2 => 2, m1 => 1, m3 => 3), 3 };
Test { members_valid Pos_Class->new(1, 2, 3), 3 };
Test { members_valid Mix_Class->new(1, 2, m3 => 3, m4 => 4), 4 };
Test { members_valid Mix_Class->new(1, 2, m4 => 4, m3 => 3), 4 };

Test {
    subclass KV_Subclass => {
	map(($_ => SPEC), qw(m4))
    }, -parent => 'KV_Class';
    subclass Pos_Subclass => {
	map(($_ => SPEC), qw(m4)),
	new => { style => 'positional m4' }
    }, -parent => 'Pos_Class';
    subclass Mix_Subclass => {
	map(($_ => SPEC), qw(m5 m6)),
	new => { style => 'mix m5' }
    }, -parent => 'Mix_Class';
    1
};

Test { members_valid KV_Subclass->new(m1 => 1, m2 => 2, m3 => 3, m4 => 4), 4 };
Test { members_valid Pos_Subclass->new(4, 1, 2, 3), 4 };
Test { members_valid Mix_Subclass->new(5, m6 => 6, 1, 2, m3 => 3, m4 => 4), 6 };

Test {
    class Mix_Parent => {
	map(($_ => SPEC), qw(m1 m2 m3)),
	new => { style => 'mix m1' }
    };
    class Mix_Child_1 => {
	new => { style => 'mix' }
    }, -parent => 'Mix_Parent';
    class Mix_Child_2 => {
	map(($_ => SPEC), qw(m4)),
	new => { style => 'mix' }
    }, -parent => 'Mix_Parent';
    1
};

Test { members_valid Mix_Child_1->new(1, m2 => 2, m3 => 3), 3 };
Test { members_valid Mix_Child_2->new(m4 => 4, 1, m2 => 2, m3 => 3), 4 };
Test_Failure { Mix_Child_2->new(1, m2 => 2, m3 => 3, m4 => 4) };

Test {
    class Own_Class => {
	m1 => SPEC,
	m2 => SPEC,
	new => { style => 'own',
		 post => q{$m1 = $_[0]; $m2 = $_[1];} }
    };
    1
};

Test { members_valid Own_Class->new(1, 2), 2 };

Test {
    class Own_Parent => {
	m1 => SPEC
    };
    1
};

Test {
    class Own_Child_1 => {
	new => { style => 'own @_' }
    }, -parent => 'Own_Parent';
    members_valid Own_Child_1->new(m1 => 1), 1
};

Test_Failure {
    class Own_Child_2 => {
	new => { style => 'own' }	# Doesn't pass anything to parent.
    }, -parent => 'Own_Parent';
    Own_Child_2->new(m1 => 1)		# Therefore, parent croaks.
};

Test {
    class Own_Child_3 => {
	m2 => SPEC,
	new => { style => q{own 'm1' $_[1]},
		 post => q{$m2 = $_[0];} }
    }, -parent => 'Own_Parent';
    members_valid Own_Child_3->new(2, 1), 2
};

Test {
    # Initialize superclass member to a constant.
    # Use a constant with an embedded quote to make sure Class::Generate is
    # quoting strings properly.
    class Own_Child_4 => {
	new => { style => q{own 'm1' "embeded'quote"} }
    }, -parent => 'Own_Parent';
    Own_Child_4->new->m1 eq "embeded'quote"
};

Report_Results;
