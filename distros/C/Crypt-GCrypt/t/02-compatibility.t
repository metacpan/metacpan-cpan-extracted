# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01-use.t'

#########################

use Test;
BEGIN {
  plan tests => 1;   # <--- number of tests
  $HAVE_CRYPT_CBC = eval "use Crypt::CBC (); 1;";
  $HAVE_CAST5 = eval "use Crypt::CAST5 (); 1;";
};

use ExtUtils::testlib;
use Crypt::GCrypt;

#########################

skip(!($HAVE_CRYPT_CBC && $HAVE_CAST5), sub {
       my $c = Crypt::GCrypt->new(
                                  type => 'cipher', 
                                  algorithm => 'cast5',
                                  mode => 'cbc',
                                  padding => 'standard'
                                 );
       $c->start('encrypting');
       $c->setkey(my $key = "the key, the key");
       $c->setiv("12345678");

       my $p = 'plain text';
       my $e = $c->encrypt($p);
       $e .= $c->finish;

       my $cipher = Crypt::CBC->new(
                                    -key => $key,
                                    -literal_key => 1,
                                    -cipher => 'CAST5',
                                    -padding => 'standard',
                                    -iv => "12345678",
                                    -header => "none"
                                   );
       $cipher->start('decrypting');
       my $d = $cipher->crypt($e);
       $d .= $cipher->finish;
       return ($d eq $p);
});
