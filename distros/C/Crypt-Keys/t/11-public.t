# $Id: 11-public.t,v 1.2 2001/08/29 03:38:48 btrott Exp $

use Test;
use Crypt::Keys;

use File::Spec::Functions qw( catfile );

use vars qw( $SAMPLES );
my %ALG;
BEGIN {
    unshift @INC, 't/';
    require 'test-common.pl';

    %ALG = (
        DSA_OPENSSH => {
            keyfile => catfile($SAMPLES, 'dsa-pub.openssh'),
            datafields => [ qw( p q g pub_key ) ],
            format => 'Public::DSA::OpenSSH',
            desc => 'DSA Public Key, OpenSSH-encoded',
            skip => 0,
        },
        RSA_OPENSSH => {
            keyfile => catfile($SAMPLES, 'rsa-pub.openssh'),
            datafields => [ qw( e n ) ],
            format => 'Public::RSA::OpenSSH',
            desc => 'RSA Public Key, OpenSSH-encoded',
            skip => 0,
        },
        RSA_SSH1 => {
            keyfile => catfile($SAMPLES, 'rsa-pub.ssh1'),
            datafields => [ qw( e n ) ],
            format => 'Public::RSA::SSH1',
            desc => 'RSA Public Key, SSH1-encoded',
            skip => 0,
        },
    );

    my $num_tests = 0;
    for my $alg (keys %ALG) {
        next if $ALG{$alg}{skip};
        $num_tests += 11;  ## static tests
        $num_tests += @{ $ALG{$alg}{datafields} } * 2;
    }

    plan tests => $num_tests;
}

for my $alg (keys %ALG) {
    my $rec = $ALG{$alg};
    next if $rec->{skip};

    my $type_data = Crypt::Keys->detect( Filename => $rec->{keyfile} );
    ok($type_data && ref($type_data) eq "HASH");
    ok($type_data->{Format} & $type_data->{Description});
    ok($type_data->{Format}, $rec->{format});
    ok($type_data->{Description}, $rec->{desc});

    my $key_data = Crypt::Keys->read( Filename => $rec->{keyfile} );
    ok($key_data && ref($key_data) eq "HASH");
    ok($key_data->{Format} && $key_data->{Data});
    ok($key_data->{Format}, $rec->{format});
    for my $df (@{ $rec->{datafields} }) {
        ok($key_data->{Data}{$df});
    }

    my $temp = $rec->{keyfile} . ".tmp";
    ok(Crypt::Keys->write(
                      Filename => $temp,
                      Data     => $key_data,
               ));

    my $key_data2 = Crypt::Keys->read( Filename => $temp );
    ok($key_data2 && ref($key_data2) eq "HASH");
    ok($key_data2->{Format} && $key_data2->{Data});
    ok($key_data2->{Format}, $rec->{format});
    for my $df (@{ $rec->{datafields} }) {
        ok($key_data->{Data}{$df}, $key_data2->{Data}{$df});
    }

    unlink $temp or die "Can't unlink $temp: $!";
}
