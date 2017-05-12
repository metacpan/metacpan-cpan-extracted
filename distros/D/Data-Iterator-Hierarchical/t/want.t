#!perl

# Test that Want::howmany gets used and that Want module absence is
# handled gracefully.

use Test::More tests => 12;

use strict;
use warnings;

use Data::Iterator::Hierarchical;

my @test_data= map { [ "A$_","B$_","C$_" ] } 1 .. 100;
my $it = hierarchical_iterator(\@test_data);


sub test_Want_not_installed {
    my ($want) = @_;
    local $@;
    ok( !eval { () = $it->(my $inner); 1}, "$want not installed fails");
    like($@,qr/not installed/,"$want not installed error");
}

# To test the 'not installed' error even if Want is installed we
# need to fake it not being installed Hmmm... is there not a
# Test:: for this?

sub fake_Want_not_installed {
    require Data::Iterator::Hierarchical::FakeWant::WillFail
	if $_[1] eq 'Want.pm';
}

# To test the 'not installed' error we need to fake Want not being installed
# Hmmm... is there not a Test:: for this?
unshift @INC, \&fake_Want_not_installed;
test_Want_not_installed 'fake Want';
shift @INC;

SKIP: {
    skip 'Want is installed', 2 if eval { require Want; 1 };
    test_Want_not_installed 'Want';
}

our $howmany;
my $want = 'Want::howmany';

sub do_tests {

    {
	local $howmany = 1;
	my($one)=$it->(my $inner);
	my($two)=$inner->();
	like($two,qr/^B/,"$want 1");
    }
    
    {
	local $howmany = 2;
	my($one,$two)=$it->(my $inner);
	my($three)=$inner->();
	like($three,qr/^C/,"$want 2");
    }

    {
	local $howmany;
	local $@;
	ok( !eval { my @stuff = $it->(my $inner); 1}, "$want undef fails");
	like($@,qr/not implicit/,"$want undef error");
    }
}

SKIP: {
    skip 'Want not installed', 4 unless eval { require Want; 1 };
    do_tests;
}

# Run the fake tests even when Want *is* installed to test the tests

no warnings 'redefine';
*Want::howmany = sub () { $howmany };
$want = "fake $want";
$INC{'Want.pm'} ||= '';
do_tests;


