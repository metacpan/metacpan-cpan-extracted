#!usr/bin/env perl
use strict;
use warnings;
use Crypt::RSA;
$|=1;
$SIG{'INT'} = \&gotsig;

# From http://www.perl.com/pub/2001/09/26/crypto1.html

my $keylen = 384;

my $message = "Writing a book is an adventure. To begin with, it is a toy and an amusement; then it becomes a mistress, and then it becomes a master, and then a tyrant. The last phase is that just as you are about to be reconciled to your servitude, you kill the monster, and fling him out to the public.";

{
  print "Test 1...";
  my $rsa = new Crypt::RSA;
  print "generating...";
  my ($public, $private) = $rsa->keygen(Size => $keylen) or die $rsa->errstr();
  print "encrypting...";
  my $c = $rsa->encrypt(Message=>$message, Key=>$public) || die $rsa->errstr();
  print "decrypting...";
  my $plaintext = $rsa->decrypt( Ciphertext => $c, Key => $private );
  die $rsa->errstr() if ($rsa->errstr() && !$plaintext);
  print "", ($message eq $plaintext) ? "success" : "FAIL", "\n";;
}

{
  print "Test 2...";
  my $rsa = new Crypt::RSA (ES => 'PKCS1v15');
  print "generating...";
  my ($public, $private) = $rsa->keygen(Size => $keylen) or die $rsa->errstr();
  print "encrypting...";
  my $c = $rsa->encrypt(Message=>$message, Key=>$public) || die $rsa->errstr();
  print "decrypting...";
  my $plaintext = $rsa->decrypt( Ciphertext => $c, Key => $private );
  die $rsa->errstr() if ($rsa->errstr() && !$plaintext);
  print "", ($message eq $plaintext) ? "success" : "FAIL", "\n";;
}

{
  print "Test 3...";

  # Generate keys
  my $rsa = new Crypt::RSA; 
  print "generating...";
  my ( $public, $private ) = $rsa->keygen(
      Identity => 'alice@wonderland.org',
      Size     => $keylen,
      Password => 'alice always awesome',
    ) or die $rsa->errstr();

  print "writing...";
  $private->write( Filename => 'alice.private' );
  $public->write( Filename => 'alice.public' );
  print "success\n";
}

{
  print "Test 4...";
  print "read private...";
  my $private = new Crypt::RSA::Key::Private( 
                  Filename => "alice.private", 
                  Password => 'alice always awesome' 
               );  
  my $rsa = new Crypt::RSA; 
  print "sign...";
  my $signature = $rsa->sign ( Message => $message, Key => $private );

  print "read public...";
  my $public = new Crypt::RSA::Key::Public( 
                  Filename => "alice.public", 
              );
  print "verify...";
  $rsa->verify( Message => $message, Signature => $signature,
                  Key => $public ) || 
                  die "Signature doesn't verify!\n";
  print "success\n";
}

sub gotsig { my $sig = shift; die "Die because SIG$sig\n"; }
END {
  unlink 'alice.private' if -e 'alice.private';
  unlink 'alice.public' if -e 'alice.public';
}
