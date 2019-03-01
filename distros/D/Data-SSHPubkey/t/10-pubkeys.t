#!perl
use 5.010;
use strict;
use warnings;
use File::Spec ();
use Test::More;    # plan is down at bottom

use Data::SSHPubkey;

can_ok( 'Data::SSHPubkey', qw(pubkeys) );

my @keyfiles =
  (qw(PEM.pub PKCS8.pub RFC4716.pub ecdsa.pub ed25519.pub rsa.pub));

my %types = (
    ecdsa   => { type => 'ecdsa-sha2-nistp256', keyre => qr{^ecdsa-sha2-nistp256} },
    ed25519 => { type => 'ssh-ed25519',         keyre => qr{^ssh-ed25519} },
    rsa     => { type => 'ssh-rsa',             keyre => qr{^ssh-rsa} },
    PEM     => { type => 'PEM',     keyre => qr{^-----BEGIN RSA PUBLIC KEY-----} },
    PKCS8   => { type => 'PKCS8',   keyre => qr{^-----BEGIN PUBLIC KEY-----} },
    RFC4716 => { type => 'RFC4716', keyre => qr{^---- BEGIN SSH2 PUBLIC KEY ----} },
);

for my $f (@keyfiles) {
    ( my $type = $f ) =~ s/\.pub//;
    my $ret = Data::SSHPubkey::pubkeys( File::Spec->catfile( 't', $f ) );
    is( scalar @$ret, 1, "only one key in $f" );
    my ( $parse_type, $data ) = @{ $ret->[0] };
    is( $parse_type, $types{$type}->{type}, "bad type for $f" );
    ok( $data =~ m/$types{$type}->{keyre}/, "pub key data for $f" );
}

# TODO probably should check input that has two, or possibly maybe even
# three keys in it, but we don't want to get too crazy here...

plan tests => 1 + 3 * scalar @keyfiles
