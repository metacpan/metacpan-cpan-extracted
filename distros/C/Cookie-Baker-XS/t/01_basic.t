use strict;
use Test::More;
use Cookie::Baker::XS qw/crush_cookie/;

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
    [ 'ZZZ="spaced out";', { ZZZ => 'spaced out' }],
    [ 'ZZTOP=%22with%20quotes%22;', { ZZTOP => '"with quotes"' }],
    [ 'BOTH="%22internal quotes%22";', { BOTH => '"internal quotes"'}],
    [ 'EMPTYQUOTE="";', { EMPTYQUOTE => '' }],
    [ 'EMPTY=;', { EMPTY => '' }],
    [ 'BADSTART="data;', { BADSTART => '"data' }],
    [ 'BADEND=data";', { BADEND => 'data"' }],

     # disallow "," as a delimiter
    [ 'Foo=Bar; Bar=Baz,  XXX=Foo%20Bar   ; YYY=; ', { Foo => 'Bar', Bar => 'Baz,  XXX=Foo Bar',YYY=>"" }],

    [ '%=";', {'%' => '"' }],
    [ ';%=";', {'%' => '"' }],
    [ ';;;;;      A="B"";;C=D', { A => 'B"', C => 'D' }],

    # raw key test
    [ '%5F%5FFoo=Bar; ', { "__Foo" => 'Bar' }],

    [ '', {} ],
    [ undef, {} ],
);

for my $test (@tests) {
    is_deeply( crush_cookie($test->[0]), $test->[1] );
}


my @raw_key_tests = (
    [ 'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
    [ 'Foo=Bar; Bar=Baz; XXX=Foo%20Bar; YYY=0; YYY=3;', { Foo => 'Bar', Bar => 'Baz', XXX => 'Foo Bar', YYY => 0 }],
    [ '%5F%5FFoo=Bar; ', { "%5F%5FFoo" => 'Bar' }],
);

for my $test (@raw_key_tests) {
    is_deeply( crush_cookie($test->[0], 1), $test->[1] );
}

done_testing;

