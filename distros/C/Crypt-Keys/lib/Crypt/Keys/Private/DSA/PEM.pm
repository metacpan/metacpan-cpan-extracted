# $Id: PEM.pm,v 1.2 2001/07/11 04:40:46 btrott Exp $

package Crypt::Keys::Private::DSA::PEM;
use strict;

use Convert::PEM;

use Crypt::Keys::ErrorHandler;
use base qw( Crypt::Keys::ErrorHandler );

sub deserialize {
    my $class = shift;
    my %param = @_;

    my $pem = $class->_pem;
    my $pkey = $pem->decode( Content  => $param{Content},
                             Password => $param{Passphrase} );
    return $class->error($pem->errstr) unless $pkey;
    $pkey->{DSAPrivateKey};
}

sub serialize {
    my $class = shift;
    my %param = @_;

    my $pkey = { DSAPrivateKey => $param{Data} };
    $pkey->{DSAPrivateKey}->{version} = 0;

    my $pem = $class->_pem;
    my $buf = $pem->encode(
            Content  => $pkey,
            Password => $param{Passphrase}
        ) or return $class->error($pem->errstr);
    $buf;
}

{
my $_pem;
sub _pem {
    unless ($_pem) {
        $_pem = Convert::PEM->new(
             Name => "DSA PRIVATE KEY",
             ASN  => qq(
                 DSAPrivateKey SEQUENCE {
                     version INTEGER,
                     p INTEGER,
                     q INTEGER,
                     g INTEGER,
                     pub_key INTEGER,
                     priv_key INTEGER
                 }
           ));
        $_pem->asn->configure( decode => { bigint => 'Math::Pari' },
                               encode => { bigint => 'Math::Pari' } );
    }
    $_pem;
}
}

1;
