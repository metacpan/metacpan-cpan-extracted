# make test
# perl Makefile.PL; make; perl -Iblib/lib t/33_refsubs.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 26;

my $ref_to_array  = [1,2,3];
my $ref_to_hash   = {1,100,2,200,3,300};
my $ref_to_scalar = \"String";

ok( refa $ref_to_array  );
ok( refh $ref_to_hash   );
ok( refs $ref_to_scalar );

my $ref_to_array_of_arrays = [ [1,2,3], [2,4,8], [10,100,1000] ];
my $ref_to_array_of_hashes = [ {1=>10, 2=>100}, {first=>1, second=>2} ];
my $ref_to_hash_of_arrays  = { alice=>[1,2,3], bob=>[2,4,8], eve=>[10,100,1000] };
my $ref_to_hash_of_hashes  = { alice=>{a=>22,b=>11}, bob=>{a=>33,b=>66} };

ok( refaa $ref_to_array_of_arrays );
ok( refah $ref_to_array_of_hashes );
ok( refha $ref_to_hash_of_arrays );
ok( refhh $ref_to_hash_of_hashes );

my $a=[2,3,4];

pushr $a, 5;      ok( join("",@$a) eq "2345" ); #print "@$a\n";
pushr $a, 6, 77;  ok( join("",@$a) eq "2345677" );
my $p=popr $a;    ok( join("",@$a) eq "23456" && $p==77 );
my $s=shiftr $a;  ok( join("",@$a) eq "3456"  && $s==2 );
unshiftr $a, 22;  ok( join("",@$a) eq "223456" );
unshiftr $a, 9,8; ok( join("",@$a) eq "98223456" );

#--splicer
my @s=splicer $a,2,3,9,100; ok(join("",@$a,'+',@s) eq "98910056+2234", "--> ".join(" ",@$a,' ',@s) );
@s=splicer $a,3,2;          ok(join("",@$a,'+',@s) eq "9896+1005",     "--> ".join(" ",@$a,'+',@s) );
@s=splicer $a,2;            ok(join("",@$a,'+',@s) eq "98+96",         "--> ".join(" ",@$a,'+',@s) );
pushr$a,44,55;              ok(join("",@$a) eq "984455");
my $last=splicer $a,1,2;    ok(join("",@$a) eq "955" && $last==44);

my $h={3=>4, 5=>6, 7=>8};
my @k=sort(keysr($h));
my @v=sort(valuesr($h));
ok( join("",@k) eq '357', "--> ".join(" ",@k) );
ok( join("",@v) eq '468', "--> ".join(" ",@v) );

while ( my($key, $val) = eachr $h) {
  deb "eachr key=$key val=$val\n";
  ok( in($key,@k) );
  ok( in($val,@v) );
}
