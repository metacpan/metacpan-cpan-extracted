# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Crypt-Fernet.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 12;
BEGIN { 
    use_ok('Crypt::CBC');
    use_ok('Digest::SHA');
    use_ok('MIME::Base64::URLSafe');
    use_ok('Crypt::Fernet') 
};

my $key = Crypt::Fernet::generate_key();
my $plaintext = 'This is a test';
my $token = Crypt::Fernet::encrypt($key, $plaintext);
my $verify = Crypt::Fernet::verify($key, $token);
my $decrypttext = Crypt::Fernet::decrypt($key, $token);

my $old_key = 'cJ3Fw3ehXqef-Vqi-U8YDcJtz8Gv-ZHyxultoAGHi4c=';
my $old_token = 'gAAAAABT8bVcdaked9SPOkuQ77KsfkcoG9GvuU4SVWuMa3ewrxpQdreLdCT6cc7rdqkavhyLgqZC41dW2vwZJAHLYllwBmjgdQ==';

my $ttl = 10;
my $old_verify = Crypt::Fernet::verify($old_key, $old_token, $ttl);
my $old_decrypttext = Crypt::Fernet::decrypt($old_key, $old_token, $ttl);

my $ttl_verify = Crypt::Fernet::verify($key, $token, $ttl);
my $ttl_decrypttext = Crypt::Fernet::decrypt($key, $token, $ttl);

ok( $key );
ok( $token );
ok( $verify );
ok( $decrypttext eq $plaintext );
ok( $old_verify == 0);
ok( !defined $old_decrypttext);
ok( $ttl_verify );
ok( $ttl_decrypttext eq $plaintext );


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

