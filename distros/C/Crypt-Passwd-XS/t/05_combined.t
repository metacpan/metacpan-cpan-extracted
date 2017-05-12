use strict;
use warnings;

use Test::More 'tests' => 25;
use Crypt::Passwd::XS ();

my $checks = [
    [ 'test1234',            '$1$test1234',                          '$1$test1234$0BvsB10tWW2oD4p7fanjN.',                                           'MD5' ],
    [ 'test1234',            '$1$',                                  '$1$$a/H3O7Gxc.2w21w4XZrCJ0',                                                   'MD5' ],
    [ 'test1234',            'test1234',                             'tesvSclXGCVNk',                                                                'DES' ],
    [ 'test1234',            'aa',                                   'aaGUTMncdkeWY',                                                                'DES' ],
    [ 'test1234',            'bb',                                   'bbO19gCe57B0E',                                                                'DES' ],
    [ 'test1234',            '',                                     undef,                                                                          'DES' ],
    [ 'test1234',            undef,                                  undef,                                                                          'DES' ],
    [ '',                    'test1234',                             'texQN4goIMuj6',                                                                'DES' ],
    [ undef,                 'test1234',                             'texQN4goIMuj6',                                                                'DES' ],
    [ 'test1234',            'test1234',                             'tesvSclXGCVNk',                                                                'DES' ],
    [ 'Hello world!',        '$5$saltstring',                        '$5$saltstring$5B8vYYiY.CVt1RlTTf8KbXBH3hsxY/GNooZaBBGWEc5',                    'SHA256' ],
    [ 'Hello world!',        '$5$rounds=10000$saltstringsaltstring', '$5$rounds=10000$saltstringsaltst$3xv.VbSHBb41AL9AvLeujZkZRBAwqFMz2.opqey6IcA', 'SHA256' ],
    [ 'This is just a test', '$5$rounds=5000$toolongsaltstring',     '$5$rounds=5000$toolongsaltstrin$Un/5jzAHMgOGZ5.mWJpuVolil07guHPvOW8mGRcvxa5',  'SHA256' ],
    [
        'a very much longer text to encrypt.  This one even stretches over morethan one line.', '$5$rounds=1400$anotherlongsaltstring',
        '$5$rounds=1400$anotherlongsalts$Rx.j8H.h8HjEDGomFU8bDkXm3XIUnzyxf12oP84Bnq1',          'SHA256'
    ],
    [ 'we have a short salt string but not a short password', '$5$rounds=77777$short',                '$5$rounds=77777$short$JiO1O3ZpDAxGJeaDIuqCoEFysAe1mZNJRs3pw0KQRd/',                                                       'SHA256' ],
    [ 'a short string',                                       '$5$rounds=123456$asaltof16chars..',    '$5$rounds=123456$asaltof16chars..$gP3VQ/6X7UUEW3HkBn2w1/Ptq2jxPyzV/cZKmF/wJvD',                                           'SHA256' ],
    [ 'the minimum number is still observed',                 '$5$rounds=10$roundstoolow',            '$5$rounds=1000$roundstoolow$yfvwcWrQ8l/K0DAWyuPMDNHpIVlTQebY9l/gL972bIC',                                                 'SHA256' ],
    [ 'Hello world!',                                         '$6$saltstring',                        '$6$saltstring$svn8UoSVapNtMuq1ukKS4tPQd8iKwSMHWjl/O817G3uBnIFNjnQJuesI68u4OTLiBFdcbYEdFCoEOfaS35inz1',                    'SHA512' ],
    [ 'Hello world!',                                         '$6$rounds=10000$saltstringsaltstring', '$6$rounds=10000$saltstringsaltst$OW1/O6BYHV6BcXZu8QVeXbDWra3Oeqh0sbHbbMCVNSnCM/UrjmM0Dp8vOuZeHBy/YTBmSK6H9qs/y3RnOaw5v.', 'SHA512' ],
    [ 'This is just a test',                                  '$6$rounds=5000$toolongsaltstring',     '$6$rounds=5000$toolongsaltstrin$lQ8jolhgVRVhY4b5pZKaysCLi0QBxGoNeKQzQ3glMhwllF7oGDZxUhx1yxdYcz/e1JSbq3y6JMxxl8audkUEm0',  'SHA512' ],
    [
        'a very much longer text to encrypt.  This one even stretches over morethan one line.',                                   '$6$rounds=1400$anotherlongsaltstring',
        '$6$rounds=1400$anotherlongsalts$POfYwTEok97VWcjxIiSOjiykti.o/pQs.wPvMxQ6Fm7I6IoYN3CmLs66x9t0oSwbtEW7o7UmJEiDwGqd8p4ur1', 'SHA512'
    ],
    [ 'we have a short salt string but not a short password', '$6$rounds=77777$short',                 '$6$rounds=77777$short$WuQyW2YR.hBNpjjRhpYD/ifIw05xdfeEyQoMxIXbkvr0gge1a1x3yRULJ5CCaUeOxFmtlcGZelFl5CxtgfiAc0',             'SHA512' ],
    [ 'a short string',                                       '$6$rounds=123456$asaltof16chars..',     '$6$rounds=123456$asaltof16chars..$BtCwjqMJGx5hrJhZywWvt0RLE8uZ4oPwcelCjmw2kSYu.Ec6ycULevoBK25fs2xXgMNrCzIMVcgEJAstJeonj1', 'SHA512' ],
    [ 'the minimum number is still observed',                 '$6$rounds=10$roundstoolow',             '$6$rounds=1000$roundstoolow$kUMsbe306n21p9R.FRkW3IGn.S9NPN0x50YhH1xhLsPuWGsUSklZt58jaTfF4ZEQpyUNGc0dqbpBYYBaHHrsX.',       'SHA512' ],
    [ 'test1234',                                             '$apr1$test1234$/XUxRsbs/UKum2fGgxyhu/', '$apr1$test1234$/XUxRsbs/UKum2fGgxyhu/',                                                                                    'APR1' ],

];

foreach my $check_ref (@$checks) {
    my $pass    = $check_ref->[0];
    my $salt    = $check_ref->[1];
    my $crypted = $check_ref->[2];
    my $scheme  = $check_ref->[3];
    my $result  = Crypt::Passwd::XS::crypt( $pass, $salt );
    is( $result, $crypted, qq{Hashed with scheme:$scheme pass:} . ( defined $pass ? qq{"$pass"} : q{(undef)} ) . q{ salt:} . ( defined $salt ? qq{"$salt"} : q{(undef)} ) );
}

