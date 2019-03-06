#!perl
use 5.010;
use strict;
use warnings;
use Data::SSHPubkey;
use File::Spec ();
use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

can_ok( 'Data::SSHPubkey', qw(pubkeys) );

my @keyfiles =
  (qw(PEM.pub PKCS8.pub RFC4716.pub ecdsa.pub ed25519.pub rsa.pub));

my %types = (
    ecdsa => {
        type  => 'ecdsa-sha2-nistp256',
        keyre => qr{^ecdsa-sha2-nistp256 AAAAE2},
    },
    ed25519 => {
        type  => 'ssh-ed25519',
        keyre => qr{^ssh-ed25519 AAAAC3},
    },
    rsa => {
        type  => 'ssh-rsa',
        keyre => qr{^ssh-rsa AAAAB3},
    },
    PEM => {
        type  => 'PEM',
        keyre => qr{^-----BEGIN RSA PUBLIC KEY-----${/}MIIBC},
    },
    PKCS8 => {
        type  => 'PKCS8',
        keyre => qr{^-----BEGIN PUBLIC KEY-----${/}MIIBI},
    },
    RFC4716 => {
        type  => 'RFC4716',
        keyre => qr{^---- BEGIN SSH2 PUBLIC KEY ----${/}AAAAB3},
    },
);

my $allkeys = '';

for my $f (@keyfiles) {
    ( my $type = $f ) =~ s/\.pub//;
    my $ret = Data::SSHPubkey::pubkeys( File::Spec->catfile( 't', $f ) );
    is( scalar @$ret, 1, "only one key in $f" );
    my ( $parse_type, $data ) = @{ $ret->[0] };
    is( $parse_type, $types{$type}->{type}, "bad type for $f" );
    ok( $data =~ m/$types{$type}->{keyre}/, "pub key data for $f" )
      or diag "$type >>>$data<<<";
    ok( $data !~ m/\s$/, "no ultimate newline on parsed pubkey" );
    $allkeys .= $data . $/;
}

my $ret = Data::SSHPubkey::pubkeys( \$allkeys );
is( scalar @$ret, scalar keys %types, "string parse of all the public keys" );

my %onlytypes;
@onlytypes{ keys %types } = ();
$deeply->(
    \%Data::SSHPubkey::ssh_pubkey_types,
    \%onlytypes, "all types tested for"
);

open my $fh, '<', File::Spec->catfile( 't', $keyfiles[0] ) or die "huh? $!";
binmode $fh;
$ret = Data::SSHPubkey::pubkeys($fh);
is( scalar @$ret, 1,     "one key" );
is( $ret->[0][0], "PEM", "first key is PEM" );

dies_ok { Data::SSHPubkey::pubkeys };

plan tests => 6 + 4 * scalar @keyfiles
