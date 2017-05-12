#!/usr/bin/perl
# 02_Shareable.t -- test 'Shared' DBs.
#
use strict;
use warnings;
use diagnostics;
use File::Slurper qw{read_text write_text};
use Cpanel::JSON::XS qw(encode_json decode_json);
use File::ShareDir qw(dist_file);
use Test::More tests => 4;


ok(1);    # load failure check...

my ( $ECO_path, $NIC_path, $Opening_path ) = GetPaths('Chess-PGN-EPD');

my $hECO     = decode_json read_text($ECO_path);
my $hNIC     = decode_json read_text($NIC_path);
my $hOpening = decode_json read_text($Opening_path);

ok( $hECO->{"r1b1kbnr/ppq1pppp/2n5/1Bpp4/2P5/4PN2/PP1P1PPP/RNBQK2R b KQkq -"}
        eq "E38*",
    'test ECO.db'
);
ok( $hNIC->{"r1b1kbnr/ppq1pppp/2n5/1Bpp4/2P5/4PN2/PP1P1PPP/RNBQK2R b KQkq -"}
        eq "NI 22*",
    'test NIC.db'
);
ok( $hOpening->{
        "r1b1k2r/2q1bppp/p2p1n2/npp1p3/P2PP3/2P2N2/1PB2PPP/RNBQR1K1 b kq -"}
        eq "Ruy Lopez: closed, Balla variation",
    'test Opening.db'
);

sub GetPaths {
    my $dist      = shift;
    my $dbECO     = dist_file( $dist, 'ECO.db' );
    my $dbNIC     = dist_file( $dist, 'NIC.db' );
    my $dbOpening = dist_file( $dist, 'Opening.db' );

    return ( $dbECO, $dbNIC, $dbOpening );
}

