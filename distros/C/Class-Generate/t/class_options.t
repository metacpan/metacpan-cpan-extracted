#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;

# Test some options associated with classes:
#   --	save.
#   --	accept_refs.
#   --	instance_variable and class variable names.
#   --	creating new objects from instances.

use Class::Generate qw(&class);

use vars qw($o);

Test {
    class Not_Saved => [ mem => "\$" ], -options => { save => 0 };
    ! -e "Saved.pm";
};
Test {	# Assumes current directory is writeable.
    class Saved => [ mem => "\$" ], -options => { save => 1 };
    -e "Saved.pm";
};
unlink "Saved.pm" if -e "Saved.pm";

Test {
    class No_Refs => {
	mem_a => '@',
	mem_h => '%'
    }, -options => { accept_refs => 0 };
    1;
};
$o = new No_Refs;
Test_Failure { $o->mem_a([]) };
Test_Failure { $o->mem_h({}) };

Test {
    class Names_Changed => {
	mem => "\$",
	'&f' => 'return $this->mem;',
	'&g' => { class_method => 1, body => 'return $c;' }
    }, -options => { instance_var => 'this', class_var => 'c' };
    $o = new Names_Changed mem => 1;
    $o->f == 1 && Names_Changed->g eq 'Names_Changed';
};

Test {
    class From_Instances => { mem => "\$" }, -options => { nfi => 1 };
    $o = new From_Instances mem => 1;
    ($o->new(mem => 2))->mem == 2;
};

Report_Results;
