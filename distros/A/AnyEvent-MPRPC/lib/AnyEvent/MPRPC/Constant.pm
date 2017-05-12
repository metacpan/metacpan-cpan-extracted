package AnyEvent::MPRPC::Constant;
use strict;
use warnings;

sub import {
    my %a = (
        MP_TYPE_REQUEST  => 0,
        MP_TYPE_RESPONSE => 1,

        MP_RES_TYPE   => 0,
        MP_RES_MSGID  => 1,
        MP_RES_ERROR  => 2,
        MP_RES_RESULT => 3,

        MP_REQ_TYPE   => 0,
        MP_REQ_MSGID  => 1,
        MP_REQ_METHOD => 2,
        MP_REQ_PARAMS => 3,
    );

    no strict 'refs';
    my $pkg = caller(0);
    while (my ($k, $v) =  each %a) {
        *{"$pkg\::$k"} = sub () { $v }; ## no critic
    }
}

1;
