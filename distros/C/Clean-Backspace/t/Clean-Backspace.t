# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Clean-Backspace.t'

#########################

use Test::More tests => 3;

# load module
BEGIN { use_ok('Clean::Backspace') };

# check object class
my $obj = Clean::Backspace->new();
isa_ok($obj, 'Clean::Backspace');

# check method interface
my @methods = qw(backspace);
can_ok($obj, @methods);
