#!perl
use 5.010;
use strict;
use warnings;
use Data::SSHPubkey;
use File::Spec ();
use File::Which qw(which);
use Test::Most;    # plan is down at bottom

my $deeply = \&eq_or_diff;

my @keyfiles = qw(PEM.pub PKCS8.pub RFC4716.pub ecdsa.pub ed25519.pub rsa.pub);

my %types = (
    ecdsa   => qr{^ecdsa-sha2-nistp256 AAAAE2},
    ed25519 => qr{^ssh-ed25519 AAAAC3},
    rsa     => qr{^ssh-rsa AAAAB3},
    PEM     => qr{^-----BEGIN RSA PUBLIC KEY-----${/}MIIBC},
    PKCS8   => qr{^-----BEGIN PUBLIC KEY-----${/}MIIBI},
    RFC4716 => qr{^---- BEGIN SSH2 PUBLIC KEY ----${/}AAAAB3},
);

my $allkeys = '';

for my $f (@keyfiles) {
    ( my $type = $f ) =~ s/\.pub//;
    my $ret = Data::SSHPubkey::pubkeys( File::Spec->catfile( 't', $f ) );
    is( scalar @$ret, 1, "only one key in $f" );
    my ( $parse_type, $data ) = @{ $ret->[0] };
    is( $parse_type, $type, "bad type for $f" );
    ok( $data =~ m/$types{$type}/, "pub key data for $f" )
      or diag "$type >>>$data<<<";
    ok( $data !~ m/\s$/, "no ultimate newline on parsed pubkey" );
    $allkeys .= $data . $/;
}

my $ret;

my $too_many = <<'EOF';
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjB5THCVJS6H6fJeXwf3DEm+FlkgWrcFniFCHuAg6Z/
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjB5THCVJS6H6fJeXwf3DEm+FlkgWrcFniFCHuAg6Z/
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjB5THCVJS6H6fJeXwf3DEm+FlkgWrcFniFCHuAg6Z/
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjB5THCVJS6H6fJeXwf3DEm+FlkgWrcFniFCHuAg6Z/
EOF
dies_ok { Data::SSHPubkey::pubkeys( \$too_many ) };

my $total_keys = scalar keys %types;

$Data::SSHPubkey::max_keys = $total_keys;
ok( $Data::SSHPubkey::max_keys == $total_keys );

# scalar reference parse
lives_ok { $ret = Data::SSHPubkey::pubkeys( \$allkeys ) };
is( scalar @$ret, $total_keys, "string parse of all the public keys" );

my %onlytypes;
@onlytypes{ keys %types } = ();
$deeply->(
    \%Data::SSHPubkey::ssh_pubkey_types,
    \%onlytypes, "all types tested for"
);

my @pubkeys = map { $_->[0] =~ m/^(ecdsa|ed25519|rsa)$/ ? $_->[1] : () } @$ret;
#use Data::Dumper; diag Dumper \@pubkeys;
is( scalar @pubkeys, 3 );

my $conv = 2;
my $skg  = which('ssh-keygen');
if ( defined $skg and length $skg ) {
    eval {
        my $rsakeys =
          Data::SSHPubkey::convert_pubkeys( [ grep { $_->[0] =~ m/^[PR]/ } @$ret ] );
        is( scalar @$rsakeys, 3 );
        is( scalar( grep { $_ =~ m/^ssh-rsa / } @$rsakeys ), 3 );
    };
    if ($@) {
        # olden versions of ssh-keygen(1) do not support -m flag (or
        # something else is awry, such as selinux backstabbing you as
        # per usual, or ...)
        diag("ssh-keygen error? convert_pubkeys may be unusable on this platform: $@");
        $conv = 0;
    }
} else {
    diag("could not find ssh-keygen, skipping convert test");
    $conv = 0;
}

# filehandle parse
open my $fh, '<', File::Spec->catfile( 't', $keyfiles[0] ) or die "huh? $!";
binmode $fh;
$ret = Data::SSHPubkey::pubkeys($fh);
is( scalar @$ret, 1,     "one key" );
is( $ret->[0][0], "PEM", "first key is PEM" );

dies_ok { Data::SSHPubkey::pubkeys };

plan tests => 9 + $conv + 4 * scalar @keyfiles
