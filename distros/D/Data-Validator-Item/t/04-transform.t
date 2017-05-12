#04-transform.t
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
ok($Validator->transform(\&test),"Transform set to test");
ok($Validator->transform() eq \&test,"Transform is really set to test() - ".\&test." is ".$Validator->transform()."\n");

ok($Validator->zap(),"We can zap it");
ok(!($Validator->transform(\@values)),"Won't accept an arrayref");

ok($Validator->zap(),"We can zap it");
ok(!($Validator->transform(4)),"Won't accept a scalar");

ok($Validator->zap(),"We can zap it");
ok(!($Validator->transform({})),"Won't accept a hash");


