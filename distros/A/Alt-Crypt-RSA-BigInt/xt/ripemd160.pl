#!/usr/bin/env perl
use warnings;
use strict;

use Crypt::RSA::Key;
use Crypt::RSA::SS::PKCS1v15;
use Crypt::RSA::Key::Public;
use Crypt::RSA::Key::Private;
use Crypt::RSA::Debug qw/debuglevel/;

my $message =  "Fancy this, that we've made a right hash out of things.";

my ($pub, $priv) = Crypt::RSA::Key->new->generate  (
                        Size => 768, 
                        Identity => 'me', 
                        Password => 'oh no you dont', 
                    );

for (qw(RipeMD-160)) { 
   
    my $pkcs = new Crypt::RSA::SS::PKCS1v15 ( Digest => $_ );
 
    my $sig = $pkcs->sign (
                Message => $message,
                Key     => $priv,
    ) || die $pkcs->errstr();

 #{ my $x = $sig; $x =~ s/[^[:print:]]/?/g; warn "   sig = '$x'\n"; }
    #$pkcs->verifyblock(Key => $priv);

    my $verify = $pkcs->verify (
                   Key => $pub, 
                   Message => $message, 
                   Signature => $sig, 
    ) || die $pkcs->errstr;

    print "Digest $_ : SUCCESS\n";
}
