use Test::More tests => 5;
use strict;
use Crypt::Nash;

my $n1;
my $n2;
my $cs;
my $bs2;

my $bs = [ 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1];


# set up key for encryption
# key consists of: red permutation, red bits, blue permutation, blue bits, initial permutation  (see his figure)
ok($n1 = Crypt::Nash->new(6,                         # n = 6
                 [ 0, 5, 0, 4, 1, 6, 2, 3 ],  # red permutation
                 [ 0, 0, 0, 1, 0, 0, 1, 1 ],  # red bits [note assuming arrow to 4 is a "+" ]
                 [ 0, 6, 4, 2, 0, 1, 3, 5 ],  # blue permutation
                 [ 0, 1, 0, 1, 1, 1, 0, 0 ],  # blue bits
                 [ 0, 1, 1, 0, 1, 1, 0, 1 ],  # initial permutation -- initial state P[0...n+1] (arbitrary choice)
                 ), "Created Crypt::Nash object");
                 


ok($cs = $n1->encrypt($bs), "Successfully encrypted bitstream");

ok($n2 = Crypt::Nash->new( 6,                           # n = 6
                 [ 0, 5, 0, 4, 1, 6, 2, 3 ],  # redp
                 [ 0, 0, 0, 1, 0, 0, 1, 1 ],  # redbits [note assuming arrow to 4 is a "+"
                 [ 0, 6, 4, 2, 0, 1, 3, 5 ],  # bluep
                 [ 0, 1, 0, 1, 1, 1, 0, 0 ],  # bluebits
                 [ 0, 1, 1, 0, 1, 1, 0, 1 ],  # initialP -- initial state P[0...n+1] (arbitrary choice)
                 ), "Created second Crypt::Nash object");
                 
ok($bs2 = $n2->decrypt($cs), "Successfully decrypted cypherstream");

is(join("", @$bs), join("", @$bs2), "Decrypted text is same as en claire text");