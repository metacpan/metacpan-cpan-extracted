#!/usr/bin/perl
use strict;
use warnings;

# generate public/private Crypt::OpenPGP keys.
# encrypt some data
# decrypt some data

use Crypt::OpenPGP;

my $size  = 1024;
my $ident = 'Me <me@example.com>';
my $pass  = 'my passphrase';
my $public_file  = 'public.pgp';
my $private_file = 'private.pgp';

my $keychain = Crypt::OpenPGP->new;

my ($public, $private) = $keychain->keygen (
                                             Type => 'RSA',
                                             Size      => $size,
                                             Identity  => $ident,
                                             Passphrase  => $pass,
                                             Verbosity => 1,
                                           ) or die $keychain->errstr();
my $public_str = $public->save;
my $private_str = $private->save;

print "\n";
print "Public encrypting_key: ".$public->encrypting_key ."\n";
print "Private encrypting_key: ".$private->encrypting_key ."\n";

open( PUB, '>', $public_file ) or die $!;
  print PUB $public_str;
close(PUB);

open( PRIV, '>', $private_file ) or die $!;
  print PRIV $private_str;
close(PRIV);

my $pgp = Crypt::OpenPGP->new( PubRing => $public_file );
my $cyphertext = $pgp->encrypt ( Data    => 'Encrypt This',
                                 Recipients => $ident,
                                 Armour     => 1,
                               ) || die $pgp->errstr();
print $cyphertext;

$pgp = new Crypt::OpenPGP( SecRing => $private_file );
my $plaintext = $pgp->decrypt (
                               Data => $cyphertext,
                               Passphrase => $pass,
                              ) || die $pgp->errstr();

print "plaintext: $plaintext\n";


sub gotsig { my $sig = shift; die "Die because SIG$sig\n"; }
END {
  unlink 'private.pgp' if -e 'private.pgp';
  unlink 'public.pgp' if -e 'public.pgp';
}

