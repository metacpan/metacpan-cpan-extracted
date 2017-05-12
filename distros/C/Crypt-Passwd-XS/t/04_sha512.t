use strict;
use warnings;

use Test::More 'tests' => 12;
use Crypt::Passwd::XS ();

my $checks = [
    [ 'Hello world!',        '$6$saltstring',                        '$6$saltstring$svn8UoSVapNtMuq1ukKS4tPQd8iKwSMHWjl/O817G3uBnIFNjnQJuesI68u4OTLiBFdcbYEdFCoEOfaS35inz1' ],
    [ 'Hello world!',        'saltstring',                           '$6$saltstring$svn8UoSVapNtMuq1ukKS4tPQd8iKwSMHWjl/O817G3uBnIFNjnQJuesI68u4OTLiBFdcbYEdFCoEOfaS35inz1' ],
    [ 'Hello world!',        '$6$rounds=10000$saltstringsaltstring', '$6$rounds=10000$saltstringsaltst$OW1/O6BYHV6BcXZu8QVeXbDWra3Oeqh0sbHbbMCVNSnCM/UrjmM0Dp8vOuZeHBy/YTBmSK6H9qs/y3RnOaw5v.' ],
    [ 'This is just a test', '$6$rounds=5000$toolongsaltstring',     '$6$rounds=5000$toolongsaltstrin$lQ8jolhgVRVhY4b5pZKaysCLi0QBxGoNeKQzQ3glMhwllF7oGDZxUhx1yxdYcz/e1JSbq3y6JMxxl8audkUEm0' ],
    [
        'a very much longer text to encrypt.  This one even stretches over morethan one line.', '$6$rounds=1400$anotherlongsaltstring',
        '$6$rounds=1400$anotherlongsalts$POfYwTEok97VWcjxIiSOjiykti.o/pQs.wPvMxQ6Fm7I6IoYN3CmLs66x9t0oSwbtEW7o7UmJEiDwGqd8p4ur1'
    ],
    [ 'we have a short salt string but not a short password', '$6$rounds=77777$short',             '$6$rounds=77777$short$WuQyW2YR.hBNpjjRhpYD/ifIw05xdfeEyQoMxIXbkvr0gge1a1x3yRULJ5CCaUeOxFmtlcGZelFl5CxtgfiAc0' ],
    [ 'a short string',                                       '$6$rounds=123456$asaltof16chars..', '$6$rounds=123456$asaltof16chars..$BtCwjqMJGx5hrJhZywWvt0RLE8uZ4oPwcelCjmw2kSYu.Ec6ycULevoBK25fs2xXgMNrCzIMVcgEJAstJeonj1' ],
    [ 'the minimum number is still observed',                 '$6$rounds=10$roundstoolow',         '$6$rounds=1000$roundstoolow$kUMsbe306n21p9R.FRkW3IGn.S9NPN0x50YhH1xhLsPuWGsUSklZt58jaTfF4ZEQpyUNGc0dqbpBYYBaHHrsX.' ],
    [ 'test1234',                                             '',                                  '$6$$XHu9fB3LkQSyG0r.FKxZjQlfe/lTi.Vq4qY0fCfJmN0JrDiG8Lv9eYhLuMlnTXFVcSbW/0hPyeKsVpjsk66qo.' ],
    [ '',                                                     'test1234',                          '$6$test1234$Dq2xtzGWFK5sgkWSp15mKK/uN14ZEUr9rFlPJ1NtQSnXUkQRz/jvz4iWpFGE/eLPuQH2L6rB.VOQPP.3GC0cv1' ],
    [ 'test1234',                                             undef,                               '$6$$XHu9fB3LkQSyG0r.FKxZjQlfe/lTi.Vq4qY0fCfJmN0JrDiG8Lv9eYhLuMlnTXFVcSbW/0hPyeKsVpjsk66qo.' ],
    [ undef,                                                  'test1234',                          '$6$test1234$Dq2xtzGWFK5sgkWSp15mKK/uN14ZEUr9rFlPJ1NtQSnXUkQRz/jvz4iWpFGE/eLPuQH2L6rB.VOQPP.3GC0cv1' ],
];

foreach my $check_ref (@$checks) {
    my $pass    = $check_ref->[0];
    my $salt    = $check_ref->[1];
    my $crypted = $check_ref->[2];
    my $result  = Crypt::Passwd::XS::unix_sha512_crypt( $pass, $salt );
    is( $result, $crypted, q{Hashed with pass:} . ( defined $pass ? qq{"$pass"} : q{(undef)} ) . q{ salt:} . ( defined $salt ? qq{"$salt"} : q{(undef)} ) );
}

