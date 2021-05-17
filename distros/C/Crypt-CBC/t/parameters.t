#!/usr/bin/perl

use strict;
use lib '../lib','./lib','./blib/lib';

sub test ($$); 

my $plaintext = <<END;
Mary had a little lamb,
Its fleece was black as coal,
And everywere that Mary went,
That lamb would dig a hole.
END
    ;

print "1..82\n";

eval "use Crypt::CBC";
test(!$@,"Couldn't load module");

my ($crypt,$ciphertext1,$ciphertext2);

# test whether a bad parameter is caught
$crypt = eval {Crypt::CBC->new(-bad_parm=>1,-pass=>'test')};
test(!$crypt,"new() accepted an unknown parameter");
test($@ =~ /not a recognized argument/,"bad parameter error message not emitted");

$crypt = eval {Crypt::CBC->new(
		   -cipher => 'Crypt::Crypt8',
		   -key    => 'test key',
		   -nodeprecate=>1)
    };
test(defined $crypt,"$@Can't continue!");
test($crypt->header_mode eq 'salt',"Default header mode is not 'salt'");
exit 0 unless $crypt;


# tests for the salt header
$crypt = eval {Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			       -key    => 'test key',
			       -header => 'salt',
			       -nodeprecate=>1,
		   ) };
test(defined $crypt,"$@Can't continue!");
exit 0 unless $crypt;

test(!defined $crypt->iv,  "IV is defined after new() but it shouldn't be");
test(!defined $crypt->salt,"salt is defined after new() but it shouldn't be");
test(!defined $crypt->key, "key is defined after new() but it shouldn't be");

$ciphertext1 = $crypt->encrypt($plaintext);
test($ciphertext1 =~ /^Salted__/s,"salted header not present");
test(defined $crypt->iv,   "IV not defined after encrypt");
test(defined $crypt->salt, "salt not defined after encrypt");
test(defined $crypt->key,  "key not defined after encrypt");

my ($old_iv,$old_salt,$old_key) = ($crypt->iv,$crypt->salt,$crypt->key);
$ciphertext2 = $crypt->encrypt($plaintext);
test($ciphertext2 =~ /^Salted__/s,"salted header not present");
test($old_iv   ne $crypt->iv,   "IV didn't change after an encrypt");
test($old_salt ne $crypt->salt, "salt didn't change after an encrypt");
test($old_key  ne $crypt->key,  "key didn't change after an encrypt");

test($plaintext eq $crypt->decrypt($ciphertext1),"decrypted text doesn't match original");
test($old_iv    eq $crypt->iv,    "original IV wasn't restored after decryption");
test($old_salt  eq $crypt->salt,  "original salt wasn't restored after decryption");
test($old_key   eq $crypt->key,   "original key wasn't restored after decryption");

test($crypt->passphrase eq 'test key',"get passphrase()");
$crypt->passphrase('new key');
test($crypt->passphrase eq 'new key',"set passphrase()");

test(length($crypt->random_bytes(20)) == 20,"get_random_bytes()");

# tests for the randomiv header
$crypt = eval {Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			       -key    => 'test key',
			       -header => 'randomiv',
			       -nodeprecate=>1,
		   ) };
test(defined $crypt,"$@\nCan't continue!");
exit 0 unless $crypt;

test($crypt->header_mode eq 'randomiv',"wrong header mode");
test($crypt->pbkdf       eq 'randomiv',"wrong key derivation mode");
test(!defined $crypt->iv,  "IV is defined after new() but it shouldn't be");
test(!defined $crypt->salt,"salt is defined after new() but it shouldn't be");
test(!defined $crypt->key, "key is defined after new() but it shouldn't be");

$ciphertext1 = $crypt->encrypt($plaintext);
test($ciphertext1 =~ /^RandomIV/s,"RandomIV header not present");
test(defined $crypt->iv,   "IV not defined after encrypt");
test(!defined $crypt->salt, "there shouldn't be a salt after randomIV encryption");
test(defined $crypt->key,  "key not defined after encrypt");

($old_iv,$old_salt,$old_key) = ($crypt->iv,$crypt->salt,$crypt->key);
$ciphertext2 = $crypt->encrypt($plaintext);
test($ciphertext2 =~ /^RandomIV/s,"RandomIV header not present");
test($old_iv   ne $crypt->iv,   "IV didn't change after an encrypt");
test($old_key  eq $crypt->key,  "key changed after an encrypt");

test($plaintext eq $crypt->decrypt($ciphertext1),"decrypted text doesn't match original");
test($old_iv   eq $crypt->iv,    "original IV wasn't restored after decryption");

# tests for headerless operation
$crypt = eval {Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			       -key    => 'test key',
			       -iv     => '01234567',
			       -nodeprecate=>1,
			       -header => 'none') };
test(defined $crypt,"$@Can't continue!");
exit 0 unless $crypt;
test($crypt->header_mode eq 'none',"wrong header mode");
test($crypt->iv eq '01234567',  "IV doesn't match settings");
test(!defined $crypt->key, "key is defined after new() but it shouldn't be");
$ciphertext1 = $crypt->encrypt($plaintext);
test(length($ciphertext1) - length($plaintext) <= 8, "ciphertext grew too much");
test($crypt->decrypt($ciphertext1) eq $plaintext,"decrypted ciphertext doesn't match plaintext");
my $crypt2 = Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			     -salt   => $crypt->salt,
			     -key    => 'test key',
			     -iv     => '01234567',
			     -nodeprecate=>1,
			     -header => 'none');
test($crypt2->decrypt($ciphertext1) eq $plaintext,"decrypted ciphertext doesn't match plaintext");
$crypt2 = Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			  -key    => 'test key',
			  -iv     => '76543210',
			  -nodeprecate=>1,
			  -header => 'none');
test($crypt2->decrypt($ciphertext1) ne $plaintext,"decrypted ciphertext matches plaintext but shouldn't");
test($crypt->iv  eq '01234567',"iv changed and it shouldn't have");
test($crypt2->iv eq '76543210',"iv changed and it shouldn't have");

# check various bad combinations of parameters that should cause a fatal error
my $good_key = Crypt::CBC->random_bytes(Crypt::Crypt8->keysize);
my $bad_key  = 'foo';
$crypt = eval {Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			       -key    => $good_key,
			       -iv     => '01234567',
			       -nodeprecate=>1,
			       -pbkdf  => 'none'
		   )};
test(defined $crypt,"$@Can't continue!");
exit 0 unless $crypt;
test($crypt->literal_key,"pbkdf 'none' should set literal key flag, but didn't");
test($crypt->key eq $good_key,"couldn't set literal key");
test($crypt->header_mode eq 'none',"-pbkdf=>'none' should set header_mode to 'none', but didn't");
test(
     !eval{
       Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
		       -header => 'randomiv',
		       -key    => $bad_key,
		       -iv     => '01234567',
		       -nodeprecate=>1,
		       -pbkdf  => 'none',
	   )
       },
     "module accepted a literal key of invalid size");
test(
     !eval{
       Crypt::CBC->new(-cipher => 'Crypt::Crypt16',
		       -header => 'randomiv',
		       -key    => $good_key,
		       -iv     => '01234567',
		       -nodeprecate=>1,
		       -pbkdf  => 'none',
	   )
       },
     "module accepted a literal key of invalid size");
test(
     !eval{
       Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
		       -header => 'randomiv',
		       -key    => $good_key,
		       -iv     => '01234567891',
		       -nodeprecate=>1,
		       -pbkdf  => 'none'
	   )
       },
     "module accepted an IV of invalid size");

test(
     !eval{
       Crypt::CBC->new(-cipher => 'Crypt::Crypt16',
		       -header => 'randomiv',
		       -nodeprecate=>1,
		       -key    => 'test key')
       },
     "module allowed randomiv headers with a 16-bit blocksize cipher");

if (0) {
    $crypt =  Crypt::CBC->new(-cipher                  => 'Crypt::Crypt16',
			      -header                  => 'randomiv',
			      -key                     => 'test key',
			      -nodeprecate             => 1,
			      -insecure_legacy_decrypt => 1);
    test(defined $crypt,"module didn't honor the -insecure_legacy_decrypt flag:$@Can't continue!");
    exit 0 unless $crypt;
    test($crypt->decrypt("RandomIV01234567".'a'x256),"module didn't allow legacy decryption");
    test(!defined eval{$crypt->encrypt('foobar')},"module allowed legacy encryption and shouldn't have");
} else {
    skip ('-insecure_legacy_decrypt is no longer supported') foreach (53..55);
}

test(
     !defined eval {Crypt::CBC->new(-cipher                  => 'Crypt::Crypt16',
				    -header                  => 'salt',
				    -key                     => 'test key',
				    -nodeprecate             => 1,
				    -salt                    => 'bad bad salt!');
		  },
     "module allowed setting of a bad salt");

test(
     defined eval {Crypt::CBC->new(-cipher                  => 'Crypt::Crypt16',
				   -header                  => 'salt',
				   -key                     => 'test key',
				   -nodeprecate             => 1,
				   -salt                    => 'goodsalt');
		 },
     "module did not allow setting of a good salt");

test(
     Crypt::CBC->new(-cipher                  => 'Crypt::Crypt16',
		     -header                  => 'salt',
		     -key                     => 'test key',
		     -nodeprecate             => 1,
		     -salt                    => 'goodsalt')->salt eq 'goodsalt',
     "module did not allow setting and retrieval of a good salt");

test(
     !defined eval {Crypt::CBC->new(-cipher                  => 'Crypt::Crypt16',
				    -header                  => 'badheadermethod',
				    -nodeprecate             => 1,
				    -key                     => 'test key')},
     "module allowed setting of an invalid header method, and shouldn't have");

test(
     !defined eval {Crypt::CBC->new(-cipher                  => 'Crypt::Crypt16',
				    -header                  => 'none',
				    -pbkdf                   => 'none',
				    -key                     => 'a'x16)
     },
     "module allowed initialization of pbkdf method 'none' without an iv");

test(
     !defined eval {Crypt::CBC->new(-cipher                  => 'Crypt::Crypt16',
				    -header                  => 'none',
				    -nodeprecate             => 1,
				    -iv                      => 'a'x16)
     },
     "module allowed initialization of header_mode 'none' without a key");

$crypt = eval {Crypt::CBC->new(-cipher         => 'Crypt::Crypt8',
			       -literal_key    => 1,
			       -header         => 'none',
			       -key            => 'a'x56,
			       -iv             => 'b'x8,
			       -nodeprecate             => 1,
			      ) };
test(defined $crypt,"unable to create a Crypt::CBC object with the -literal_key option: $@");
test($plaintext eq $crypt->decrypt($crypt->encrypt($plaintext)),'cannot decrypt encrypted data using -literal_key');
test($crypt->passphrase eq '','passphrase should be empty when -literal_key specified');
test($crypt->key eq 'a'x56,'key should match provided -key argument when -literal_key specified');

# test behavior of pbkdf option
test($crypt->pbkdf eq 'none','PBKDF should default to "none" when -literal_key provided, but got '.$crypt->pbkdf);

$crypt = eval {Crypt::CBC->new(-cipher  => 'Crypt::Crypt8',-pass=>'very secret',-nodeprecate=>1)} or warn $@;
test($crypt->pbkdf eq 'opensslv1','PBKDF should default to "opensslv1", but got '.$crypt->pbkdf);

$crypt = eval {Crypt::CBC->new(-cipher  => 'Crypt::Crypt8',-pass=>'very secret',-pbkdf=>'pbkdf2')} or warn $@;
test($crypt->pbkdf eq 'pbkdf2','PBKDF not setting properly. Expected "pbkdf2" but got '.$crypt->pbkdf);

$crypt = eval {Crypt::CBC->new(-cipher  => 'Crypt::Crypt8',
			       -pass=>'very secret',
			       -pbkdf=>'pbkdf2',
			       -hasher=>'HMACSHA3',
			       -iter=>1000)} or warn $@;
my $pbkdf = $crypt->pbkdf_obj;
test(defined $pbkdf,"PBKDF object not created as expected");
test($pbkdf->{hash_class} eq 'HMACSHA3','pbkdf object hasher not initialized to correct class');
test($pbkdf->{iterations} == 1000,'pbkdf object hasher not initialized to correct number of iterations');

test( !eval {Crypt::CBC->new(-cipher  => 'Crypt::Crypt8',
			    -pass=>'very secret',
			    -pbkdf=>'pbkdf2',
			    -iv   => 'b'x8,
			    -header=>'randomiv')
      },
      'module should not allow a header mode of randomiv and a pbkdf not equal to randomiv'
    );

$crypt = eval {Crypt::CBC->new(-cipher  => 'Crypt::Crypt8',
			       -pass=>'very secret',
			       -pbkdf=>'pbkdf2',
			       -iv   => 'b'x8,
			       -header=>'none'),
} or warn $@;
# not sure this test is correct behaviour
# test(73,$crypt->pbkdf eq 'none','pbkdf should be set to "none" when header mode of "none" used');

# now test that setting the -salt generates the same key and IV
$crypt = eval {Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			       -pass   => 'baby knows me well',
			       -pbkdf  => 'pbkdf2',
			       -salt   => '01234567')} or warn $@;
test($crypt->salt eq '01234567',"can't set salt properly");
$crypt->set_key_and_iv();  # need to do this before there is a key and iv
my ($key,$iv) = ($crypt->key,$crypt->iv);
$crypt = eval {Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			       -pass   => 'baby knows me well',
			       -pbkdf  => 'pbkdf2',
			       -salt   => '01234567')} or warn $@;
$crypt->set_key_and_iv();
test($crypt->key eq $key,"key changed even when salt was forced");
test($crypt->iv  eq $iv,"iv changed even when salt was forced");
$crypt = eval {Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
			       -pass   => 'baby knows me well',
			       -pbkdf  => 'pbkdf2',
			       -salt   => '76543210')} or warn $@;
$crypt->set_key_and_iv();
test($crypt->key ne $key,"key didn't change when salt was changed");
$crypt = eval {
    Crypt::CBC->new(-cipher => 'Crypt::Crypt8',
		    -key    => 'xyz',
		    -header => 'salt',
		    -salt   => 1);
};
test($crypt,"-salt=>1 is generating an exception: $@");

exit 0;

my $number = 1;

sub test ($$){
    local($^W) = 0;
    my($true,$msg) = @_;
    $msg =~ s/\n$//;
    ++$number;
    print($true ? "ok $number\n" : "not ok $number # $msg\n");
}

sub skip {
    my ($msg) = @_;
    ++$number;
    print "ok $number # skip $msg\n";
}

package Crypt::Crypt16;

sub new       { return bless {},shift }
sub blocksize { return 16    }
sub keysize   { return 56    }
sub encrypt   { return $_[1] }
sub decrypt   { return $_[1] }

package Crypt::Crypt8;

sub new       { return bless {},shift }
sub blocksize { return 8     }
sub keysize   { return 56    }
sub encrypt   { return $_[1] }
sub decrypt   { return $_[1] }

