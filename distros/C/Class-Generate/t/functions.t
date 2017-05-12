#! /usr/local/bin/perl

use lib qw(./t);
use warnings;
use strict;
use Test_Framework;

# Test member functions.

use Class::Generate qw(&class &subclass);

use vars qw($o);

Test {
    class Person => {
	last_name  => { type => '$', required => 1 },
	first_name => '$',
	mi	   => { type => '$', assert => '! defined $mi || length $mi == 1' },
	'&name' => 'my $name = "";
		    $name .= "$first_name " if defined $first_name;
		    $name .= "$mi. " if defined $mi;
		    $name .= $last_name;
		    return $name;',
	new => { style => 'positional last_name first_name mi' }
    };
    (new Person 'Codesmith', 'Sally')->name eq 'Sally Codesmith' &&
    (new Person 'Hacker', 'Fred', 'Q')->name eq 'Fred Q. Hacker' &&
    (new Person 'Madonna')->name eq 'Madonna';
};

Test {
    subclass US_Citizen => {
	ssn => {
	    type     => '$',
	    required => 1,
	    readonly => 1,
	    assert   => '$ssn =~ /^\d{3}-\d{2}-\d{4}$/'
	},
	'&duplicate_ssn' => {
	    private => 1,
	    body => 'return defined $ssns_used{$_[0]};'
	},
	'&number_of_citizens' => {
	    class_method => 1,
	    body => 'return scalar(keys %ssns_used);'
	},
	new => {
	    style => 'positional ssn',
	    post  => 'croak qq|Duplicate SSN "$ssn"| if &duplicate_ssn($ssn);
		      $ssns_used{$ssn} = 1;'
	}
    }, -parent => 'Person',
       -class_vars => '%ssns_used';
    $o = new US_Citizen '123-45-6789', 'Public', 'John', 'Q';
    $o->ssn eq '123-45-6789'
};

Test_Failure { new US_Citizen '123-45-6789', 'Public', 'Jane'; };
Test_Failure { new US_Citizen '111-11-1111'; };
Test_Failure {
    $o = new US_Citizen '222-22-2222', 'Doe', 'John';
    print $o->duplicate_ssn('123-45-6789');
};

Test {
    $o = new US_Citizen '111-11-1111', 'Public', 'John', 'Q';
    $o->name eq 'John Q. Public'
};

Test { US_Citizen->number_of_citizens == 3 };

Report_Results;
