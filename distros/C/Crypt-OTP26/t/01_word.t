#!/usr/bin/perl
use strict; use warnings;
use Data::Dumper;

use Test::More tests=>38;

BEGIN {
  use_ok( 'Crypt::OTP26' );
}

ok (my $onetime = Crypt::OTP26->new( offset => 0) );

SKIP: {
    can_ok ( $onetime, 'char2int' )
        or skip 'char2int not implemented', 3;
        is ($onetime->char2int('a'),  0);
        is ($onetime->char2int('A'),  0);
        is ($onetime->char2int('s'), 18);
}
SKIP: {
    can_ok ( $onetime, 'int2char' )
        or skip 'int2char not implemented', 3;
        is ($onetime->int2char(  0), 'a');
        is ($onetime->int2char( 26), 'a');
        is ($onetime->int2char(-26), 'a');
        is ($onetime->int2char( 18), 's');
}
SKIP: {
    can_ok ( $onetime, 'crypt_char' )
        or skip 'crypt_char not implemented', 1;
    is ($onetime->crypt_char('b', 's') => 't');
}
SKIP: {
    can_ok ( $onetime, 'mk_stream' )
        or skip 'mk_stream not implemented', 1;
    ok( my $stream = $onetime->mk_stream('hello', 'world') );
    isa_ok( $stream, 'CODE' );

    my @chars = qw/ h w e o l r l l o d /;
    while (my @next = splice(@chars, 0,2)) {
        my @res = $stream->();
        is_deeply( \@res, \@next, "Got @res" );
    }
    ok (! $stream->(), 'undef at end of stream' );
}

SKIP: {
    can_ok ( $onetime, 'crypt' )
        or skip 'crypt not implemented', 2;
    is ($onetime->crypt('b', 's') => 't');

    is ($onetime->crypt('aced', 'scam')     => 'seep',     'equal length');
    is ($onetime->crypt('aced', 'sca')      => 'see',      'pad more than long enough');
    is ($onetime->crypt('aced', 'scamscam') => 'seepseep', 'repeating');
    is ($onetime->crypt('ace',  'scamscam') => 'seemugao', 'another repeating');
}
SKIP: {
    can_ok ( $onetime, 'decrypt_char' )
        or skip 'decrypt_char not implemented', 1;
    is ($onetime->decrypt_char('t', 's') => 'b');
    is ($onetime->decrypt_char('t', 'b') => 's');
}

SKIP: {
    can_ok ( $onetime, 'decrypt' )
        or skip 'decrypt not implemented', 2;
    is ($onetime->decrypt('s', 't') => 'b');

    is ($onetime->decrypt('aced', 'seep')     => 'scam',     'equal length');
    is ($onetime->decrypt('scam', 'seep')     => 'aced',     'and back again');
    is ($onetime->decrypt('aced', 'see')      => 'sca',      'pad more than long enough');
    is ($onetime->decrypt('aced', 'seepseep') => 'scamscam', 'repeating');
    is ($onetime->decrypt('ace',  'seemugao') => 'scamscam', 'another repeating');
}
