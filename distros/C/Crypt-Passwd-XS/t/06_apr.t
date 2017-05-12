use strict;
use warnings;

use Test::More 'tests' => 7;
use Crypt::Passwd::XS ();

my $checks = [
    [ 'test1234', 'test1234',                              '$apr1$test1234$/XUxRsbs/UKum2fGgxyhu/' ],
    [ 'test1234', '$apr1$test1234$/XUxRsbs/UKum2fGgxyhu/', '$apr1$test1234$/XUxRsbs/UKum2fGgxyhu/' ],
    [ 'test1234', '',                                      '$apr1$$T4M71QIQ3202kpuq1FD.D/' ],
    [ '',         '',                                      '$apr1$$J/S5FGXXjRRxbhIznTb/E1' ],
    [ '',         'test1234',                              '$apr1$test1234$7DM1LH/akkGH1ZWnprvXd1' ],
    [ 'test1234', undef,                                   '$apr1$$T4M71QIQ3202kpuq1FD.D/' ],
    [ undef,      'test1234',                              '$apr1$test1234$7DM1LH/akkGH1ZWnprvXd1' ],
];

foreach my $check_ref (@$checks) {
    my $pass    = $check_ref->[0];
    my $salt    = $check_ref->[1];
    my $crypted = $check_ref->[2];
    my $result  = Crypt::Passwd::XS::apache_md5_crypt( $pass, $salt );
    is( $result, $crypted, q{Hashed with pass:} . ( defined $pass ? qq{"$pass"} : q{(undef)} ) . q{ salt:} . ( defined $salt ? qq{"$salt"} : q{(undef)} ) );
}

