use strict;
use warnings;

use Test::More 'tests' => 12;
use Crypt::Passwd::XS ();

my $checks = [
    [ 'Hello world!',        '$5$saltstring',                        '$5$saltstring$5B8vYYiY.CVt1RlTTf8KbXBH3hsxY/GNooZaBBGWEc5' ],
    [ 'Hello world!',        'saltstring',                           '$5$saltstring$5B8vYYiY.CVt1RlTTf8KbXBH3hsxY/GNooZaBBGWEc5' ],
    [ 'Hello world!',        '$5$rounds=10000$saltstringsaltstring', '$5$rounds=10000$saltstringsaltst$3xv.VbSHBb41AL9AvLeujZkZRBAwqFMz2.opqey6IcA' ],
    [ 'This is just a test', '$5$rounds=5000$toolongsaltstring',     '$5$rounds=5000$toolongsaltstrin$Un/5jzAHMgOGZ5.mWJpuVolil07guHPvOW8mGRcvxa5' ],
    [
        'a very much longer text to encrypt.  This one even stretches over morethan one line.', '$5$rounds=1400$anotherlongsaltstring',
        '$5$rounds=1400$anotherlongsalts$Rx.j8H.h8HjEDGomFU8bDkXm3XIUnzyxf12oP84Bnq1'
    ],
    [ 'we have a short salt string but not a short password', '$5$rounds=77777$short',             '$5$rounds=77777$short$JiO1O3ZpDAxGJeaDIuqCoEFysAe1mZNJRs3pw0KQRd/' ],
    [ 'a short string',                                       '$5$rounds=123456$asaltof16chars..', '$5$rounds=123456$asaltof16chars..$gP3VQ/6X7UUEW3HkBn2w1/Ptq2jxPyzV/cZKmF/wJvD' ],
    [ 'the minimum number is still observed',                 '$5$rounds=10$roundstoolow',         '$5$rounds=1000$roundstoolow$yfvwcWrQ8l/K0DAWyuPMDNHpIVlTQebY9l/gL972bIC' ],
    [ 'test1234',                                             '',                                  '$5$$LTI8w5KsA5bMCaf3VTEMPeKckTBV4y9mN7la4rjh896' ],
    [ '',                                                     'test1234',                          '$5$test1234$UA0OvNpssFd2pcJm0sJ0ne3E6b518x/YEIPtJO8m841' ],
    [ 'test1234',                                             undef,                               '$5$$LTI8w5KsA5bMCaf3VTEMPeKckTBV4y9mN7la4rjh896' ],
    [ undef,                                                  'test1234',                          '$5$test1234$UA0OvNpssFd2pcJm0sJ0ne3E6b518x/YEIPtJO8m841' ]
];

foreach my $check_ref (@$checks) {
    my $pass    = $check_ref->[0];
    my $salt    = $check_ref->[1];
    my $crypted = $check_ref->[2];
    my $result  = Crypt::Passwd::XS::unix_sha256_crypt( $pass, $salt );
    is( $result, $crypted, q{Hashed with pass:} . ( defined $pass ? qq{"$pass"} : q{(undef)} ) . q{ salt:} . ( defined $salt ? qq{"$salt"} : q{(undef)} ) );
}
