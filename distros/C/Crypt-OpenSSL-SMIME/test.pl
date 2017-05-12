# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use Test::Simple tests => 5;

use Crypt::OpenSSL::SMIME;

my $pass = '123456';
my $from_email = 'sender@test.com';

{
	  my $obj = new Crypt::OpenSSL::SMIME({
                  From                => $from_email,
                  rootCA              => 't/ca.crt',
                  signerfile          => 't/sender.crt',
                  signer_key_file     => 't/sender.key',
                  pass_for_root_CA    => $pass,
                  pass_for_signer_key => $pass,
                  outfile             =>  't/MailEncrypted.txt'
            });

        ok( defined $obj, 'new() returned something' );
		ok( $obj->isa('Crypt::OpenSSL::SMIME'), "  and it's the right class" );
		ok( !$obj->failed(), "  and it's not failed" );
		if (-e 't/MailForSend.txt') {
			ok( $obj->loadDataFile('t/MailForSend.txt'), "  loadDataFile()" );
			ok( $obj->encryptData('t/recipient.crt', 'recipient@test.com', 'Some subject'), "  encryptData()" );
		}
}

print "done\n";
