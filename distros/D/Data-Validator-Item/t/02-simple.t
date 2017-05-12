#02-simple.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

local( $SIG{__WARN__} )= sub { warn "# ",@_ };

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();

#Test the name
ok($Validator->name("Fred"), "Now we've given it a name");
is($Validator->name(),"Fred","We called it ".$Validator->name());
ok($Validator->name("Janet"), "Now we've changed the name");
is($Validator->name(),"Janet","the new name() is ".$Validator->name());

#Test the error
ok($Validator->error("Fred"), "Now we've given it a name");
is($Validator->error(),"Fred","We called it ".$Validator->error());
ok($Validator->error("Janet"), "Now we've changed the name");
is($Validator->error(),"Janet","the new name() is ".$Validator->error());

#Test zap() again
ok($Validator->zap(),"We can still zap it");
ok(!defined($Validator->name()),"Now it's undefined");
ok(!defined($Validator->error()),"Now it's still undefined");

#Test the min and max functions
ok($Validator->min(-50.5464564), "min(set)");
is($Validator->min(),-50.5464564,"min() is ".$Validator->min());
ok($Validator->max(123456789123456), "max(set)");
is($Validator->max(),123456789123456,"max() is ".$Validator->max());

#Test the missing function
ok($Validator->missing("*"), "missing(set)to *");
is($Validator->missing(),"*","missing() is ".$Validator->missing());
isnt($Validator->missing(),"-","missing() isn't '-'");
is($Validator->missing(),"\*","missing() is '*'");

#Test the values function
my @values=[5,6,7,8];
ok($Validator->values(\@values), "Values(set)");
ok($Validator->values([1,2,2,2,2,2,3]), "Values(set)");
isnt(($Validator->values(4)), "Won't accept scalar values");
isnt(($Validator->values({})), "Won't accept hash values");
