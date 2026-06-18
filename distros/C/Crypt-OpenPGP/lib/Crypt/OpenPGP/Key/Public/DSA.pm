package Crypt::OpenPGP::Key::Public::DSA;
use strict;

our $VERSION = '1.21'; # VERSION

use Crypt::DSA::GMP::Key;
use parent qw( Crypt::OpenPGP::Key::Public Crypt::OpenPGP::ErrorHandler );

sub can_sign { 1 }
sub abbrev { 'D' }

sub init {
    my $key = shift;
    $key->{key_data} = shift || Crypt::DSA::GMP::Key->new;
    $key;
}

sub keygen {
    my $class = shift;
    my %param = @_;
    require Crypt::DSA::GMP;
    my $dsa = Crypt::DSA::GMP->new;
    my $sec = $dsa->keygen( %param );
    my $pub = bless { }, 'Crypt::DSA::GMP::Key';
    for my $e (qw( p q g pub_key )) {
        $pub->$e( $sec->$e() );
    }
    ($pub, $sec);
}

sub public_props { qw( p q g y ) }
sub sig_props { qw( r s ) }

sub y { $_[0]->{key_data}->pub_key(@_[1..$#_]) }

sub size { $_[0]->{key_data}->size }

sub verify {
    my $key = shift;
    my($sig, $dgst) = @_;
    require Crypt::DSA::GMP;
    my $dsa = Crypt::DSA::GMP->new;
    my $dsa_sig = Crypt::DSA::GMP::Signature->new;
    $dsa_sig->r($sig->{r});
    $dsa_sig->s($sig->{s});
    $dsa->verify(
                  Key => $key->{key_data},
                  Digest => $dgst,
                  Signature => $dsa_sig
              );
}

1;
