use strict;
use Test::More;
use Cookie::Baker;

my $longkey = 'x'x1024;

my @tests = (
    [ 'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
    [ 'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
    [ 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=0; YYY=3;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
    [ 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=0; YYY=3;   ', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
    [ 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar' }],
    [ 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar' }],
    [ 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY; ', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar' }],
    [ 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY=>"" }],
    [ 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY=>"" }],
    [ 'Foo=Bar; Bar=Baz;  XXX=Foo%20Bar   ; YYY=; ', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar',YYY=>"" }],
    [ "Foo=Bar; $longkey=Bar", { Foo => 'Bar', $longkey => 'Bar'}],
    [ "Foo=Bar; $longkey=Bar; Bar=Baz", { Foo => 'Bar', $longkey => 'Bar', 'Bar'=>'Baz'}],

    # from https://github.com/plack/Plack/pull/564/files
    [ 'ZZZ="spaced out"; XXX=Foo', { ZZZ => 'spaced out', XXX => 'Foo' }],
    [ 'ZZTOP=%22with%20quotes%22;', { ZZTOP => '"with quotes"' }],
    [ 'BOTH="%22internal quotes%22";', { BOTH => '"internal quotes"'}],
    [ 'EMPTYQUOTE="";', { EMPTYQUOTE => '' }],
    [ 'EMPTY=;', { EMPTY => '' }],
    [ 'BADSTART="data;', { BADSTART => '"data' }],
    [ 'BADEND=data";', { BADEND => 'data"' }],

    [ '', {} ],
    [ undef, {} ],
);

for my $test (@tests) {
    is_deeply( crush_cookie($test->[0]), $test->[1] );
    is_deeply( Cookie::Baker::pp_crush_cookie($test->[0]), $test->[1] );
}

done_testing;

