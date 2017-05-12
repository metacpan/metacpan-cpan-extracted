# $Id: PEM.pm,v 1.3 2001/07/11 04:40:47 btrott Exp $

package Crypt::Keys::Private::RSA::PEM;
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
    return unless $pkey;
    $pkey->{RSAPrivateKey};
}

sub serialize {
    my $class = shift;
    my %param = @_;

    my $pkey = { RSAPrivateKey => $param{Data} };
    $pkey->{RSAPrivateKey}->{version} = 0;

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
              Name => 'RSA PRIVATE KEY',
              ASN  => qq(
                  RSAPrivateKey SEQUENCE {
                      version INTEGER,
                      n INTEGER,
                      e INTEGER,
                      d INTEGER,
                      p INTEGER,
                      q INTEGER,
                      dp INTEGER,
                      dq INTEGER,
                      iqmp INTEGER
                  }
           ));
        $_pem->asn->configure( decode => { bigint => 'Math::Pari' },
                               encode => { bigint => 'Math::Pari' } );
    }
    $_pem;
}
}

1;
