#03-verify.t
#
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

local( $SIG{__WARN__} )= sub { warn "# ",@_ };

my $Validator = Data::Validator::Item->new();

my @values= (2,3,4);
sub test {return 44566;}

#Test the transform section
ok($Validator->verify(\&test),"Verify set to test");
ok($Validator->verify() eq \&test,"Verify is really set to test() - ".\&test." is ".$Validator->verify()."\n");

ok($Validator->zap(),"We can zap it");
ok(!($Validator->verify(\@values)),"Won't accept an arrayref");

ok($Validator->zap(),"We can zap it");
ok(!($Validator->verify(4)),"Won't accept a scalar");

ok($Validator->zap(),"We can zap it");
ok(!($Validator->verify({})),"Won't accept a hash");


