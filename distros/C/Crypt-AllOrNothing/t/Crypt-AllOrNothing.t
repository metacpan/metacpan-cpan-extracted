use Test::More tests => 6;
BEGIN { use_ok('Crypt::AllOrNothing') };

my $AllOrNothing_blank = Crypt::AllOrNothing->new();
isa_ok($AllOrNothing_blank, Crypt::AllOrNothing);
can_ok($AllOrNothing_blank, q/new/);
is($AllOrNothing_blank->size(),128,'Size of block for $AllOrNothing');
is(length $AllOrNothing_blank->K_0(), 16, 'Length of default K_0');
#my $AllOrNothing_badsize = Crypt::AllOrNothing->new(size=>12);
#isa_ok($AllOrNothing_badsize, Crypt::AllOrNothing, '$AON_badsize is an Crypt::AON');
#is($AllOrNothing_badsize->size(),128,'Size of block for $AllOrNothing_badsize');
#my $AllOrNothing_1024 = Crypt::AllOrNothing->new(size=>1024);
#isa_ok($AllOrNothing_1024, Crypt::AllOrNothing, '$AON_1024 is an Crypt::AON');
#is($AllOrNothing_1024->size(),1024,'Size of block for $AllOrNothing_1024');
#is(length $AllOrNothing_1024->K_0(), 128, 'Length of 1024 K_0');
#is($AllOrNothing_1024->size(140),1024,'Size of block for $AllOrNothing_1024, should warn');

my @transformed_alphabet_blank = $AllOrNothing_blank->encrypt(plaintext=>"abcdefghijklmnopqrstuvwxyz");
my $unstransformed_alphabet_blank = $AllOrNothing_blank->decrypt(cryptotext=>\@transformed_alphabet_blank);

is($unstransformed_alphabet_blank, "abcdefghijklmnopqrstuvwxyz", "untransform(tranform(alphabet)) works");

