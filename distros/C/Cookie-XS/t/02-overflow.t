use strict;
use warnings;

#use Smart::Comments;
use Test::More tests => 7;
BEGIN { use_ok('Cookie::XS'); }

my $COOKIE_LEN_LIMIT = 1024 * 4;

{
    my $val_len = $COOKIE_LEN_LIMIT - 3;
    my $cookie = 'a=' . ('a' x $val_len);
    my $res = Cookie::XS->parse($cookie);
    ok $res, 'res okay';
    ok $res->{a}, 'var a parsed';
    is $res->{a}->[0], 'a' x $val_len, "value okay for var a";
}

{
    my $val_len = $COOKIE_LEN_LIMIT - 3;
    my $cookie = 'a=' . ('a' x $COOKIE_LEN_LIMIT);
    my $res = Cookie::XS->parse($cookie);
    ok $res, 'res okay';
    ok $res->{a}, 'var a parsed';
    ### Len: length($res->{a}->[0])
    is $res->{a}->[0], 'a' x $val_len, "value okay for var a";
}

