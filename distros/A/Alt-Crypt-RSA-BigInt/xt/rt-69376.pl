#!/usr/bin/perl
use warnings;
use strict;
use Crypt::RSA::Key;
use Crypt::RSA::Key::Private::SSH;
use Test::More;

plan tests => 9;

my $obj = new Crypt::RSA::Key;

# Create an unencrypted key
my ($pub, $pri) = $obj->generate( Identity => 'Some User <someuser@example.com>', Size => 1024, KF => 'SSH' );

foreach my $cipher (qw/Blowfish IDEA DES DES3 Twofish2 CAST5 Rijndael RC6 Camellia/) {
  SKIP: {
    my $file = ($cipher eq 'DES3') ? 'Crypt/DES_EDE3.pm' : "Crypt/$cipher.pm";
    eval { require "$file"; 1; };
    skip "$cipher module not found", 1 if $@;

    my ($newpub, $newpri) = $obj->generate( Size => 64, KF => 'SSH' );

    my $crypted = $pri->serialize( Cipher => $cipher, Password => "Hunter2" );
    $newpri->deserialize( String => $crypted, Password => "Hunter2" );

    is_deeply($newpri, $pri, "$cipher serialized");
    #print Dumper($pri);
    #print Dumper($new_pri);
  }
}
