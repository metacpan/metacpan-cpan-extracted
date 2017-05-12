# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Class-Superclass.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Class::Superclasses') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use FindBin ();
use Class::Superclasses;

my $testfile = $FindBin::Bin . '/test_expression_parent.pm';
my $parser = Class::Superclasses->new();
ok(ref($parser) eq 'Class::Superclasses');

$parser->document($testfile);
my $teststring = 'Expression parent';
my @superclasses = $parser->superclasses();
ok(join(' ',@superclasses) eq $teststring);