# $Id: 10-private.t,v 1.5 2002/02/16 18:26:44 btrott Exp $

use Test;
use Crypt::Keys;

my($no_pem, $no_ssh1);
BEGIN {
    eval "use Convert::PEM;";
    $no_pem = $@;

    eval "use Crypt::CBC; use Crypt::DES;";
    $no_ssh1 = $@;
}

use File::Spec::Functions qw( catfile );

use vars qw( $SAMPLES );
my %ALG;
BEGIN {
    unshift @INC, 't/';
    require 'test-common.pl';

    %ALG = (
        DSA_PEM => {
            keyfile => catfile($SAMPLES, 'dsa-priv.pem'),
            datafields => [ qw( p q g pub_key priv_key ) ],
            format => 'Private::DSA::PEM',
            desc => 'DSA Private Key, PEM-encoded',
            skip => $no_pem,
        },
        RSA_PEM => {
            keyfile => catfile($SAMPLES, 'rsa-priv.pem'),
            datafields => [ qw( e n p q d dp dq iqmp ) ],
            format => 'Private::RSA::PEM',
            desc => 'RSA Private Key, PEM-encoded',
            skip => $no_pem,
        },
        DSA_SSH2 => {
            keyfile => catfile($SAMPLES, 'dsa-priv.ssh2'),
            datafields => [ qw( p q g pub_key priv_key ) ],
            format => 'Private::DSA::SSH2',
            desc => 'DSA Private Key, SSH2-encoded',
            skip => 0,
        },
        RSA_SSH1 => {
            keyfile => catfile($SAMPLES, 'rsa-priv.ssh1'),
            datafields => [ qw( e n p q d dp dq iqmp ) ],
            format => 'Private::RSA::SSH1',
            desc => 'RSA Private Key, SSH1-encoded',
            skip => $no_ssh1,
        },
    );

    my $num_tests = 0;
    for my $alg (keys %ALG) {
        next if $ALG{$alg}{skip};
        $num_tests += 15;  ## static tests
        $num_tests += @{ $ALG{$alg}{datafields} } * 3;
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

    ok(Crypt::Keys->write(
                      Filename   => $temp,
                      Data       => $key_data,
                      Passphrase => 'foo',
               ));

    $key_data2 = Crypt::Keys->read( Filename => $temp, Passphrase => 'foo' );
    ok($key_data2 && ref($key_data2) eq "HASH");
    ok($key_data2->{Format} && $key_data2->{Data});
    ok($key_data2->{Format}, $rec->{format});
    for my $df (@{ $rec->{datafields} }) {
        ok($key_data->{Data}{$df}, $key_data2->{Data}{$df});
    }

    unlink $temp or die "Can't unlink $temp: $!";
}
