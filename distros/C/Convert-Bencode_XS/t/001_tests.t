# -*- perl -*-

# t/001_tests.t - check to make sure its all working

use Test::More tests => 76;

BEGIN { use_ok( 'Convert::Bencode_XS', qw(:all) ); }


#tests taken from Convert::Bencode
my $test_string = "d7:Integeri42e4:Listl6:item 1i2ei3ee6:String9:The Valuee";
my $hashref = bdecode($test_string);

ok( defined $hashref, 'bdecode() returned something' );
is( ref($hashref), "HASH", 'bdecode() returned a valid hash ref' );
ok( defined ${$hashref}{'Integer'}, 'Integer key present' );
is( ${$hashref}{'Integer'}, 42, '  and its the correct value' );
ok( defined ${$hashref}{'String'}, 'String key present' );
is( ${$hashref}{'String'}, 'The Value', '  and its the correct value' );
ok( defined ${$hashref}{'List'}, 'List key present' );
is( @{${$hashref}{'List'}}, 3, '  list has 3 elements' );
is( ${${$hashref}{'List'}}[0], 'item 1', '    first element correct' );
is( ${${$hashref}{'List'}}[1], 2, '    second element correct' );
is( ${${$hashref}{'List'}}[2], 3, '    third element correct' );

my $encoded_string = bencode($hashref);

ok( defined $encoded_string, 'bencode() returned something' );
is( $encoded_string, $test_string, '  and it appears to be the correct value' );

#tests taken from bencode.py

eval { bdecode('0:0:') };
ok($@, "We should croak here: invalid format");

eval { bdecode('ie') };
ok($@, "We should croak here: invalid format");

eval { bdecode('i341foo382e') };
ok($@, "We should croak here: invalid format");

is( bdecode('i4e'), 4 );
is( bdecode('i0e'), 0 );
is( bdecode('i123456789e'), 123456789 );
is( bdecode('i-10e'), -10 );
is( bdecode('i-0e'), "-0" );  #we are more relaxed over this cause anyway 
is( bdecode('i-0e') + 0, 0 ); #it works well as a number
cleanse(my $minus_zero = bdecode('i-0e'));
is( $minus_zero, 0 );

eval { bdecode('i123') };
ok($@, "We should croak here: invalid format");

eval { bdecode('') };
ok($@, "We should croak here: invalid format");

eval { bdecode('i6easd') };
ok($@, "We should croak here: invalid format");


eval { bdecode('35208734823ljdahflajhdf') };
ok($@, "We should croak here: invalid format");

eval { bdecode('2:abfdjslhfld') };
ok($@, "We should croak here: invalid format");

eval { bdecode('9999:x') };
ok($@, "We should croak here: invalid format");

is( bdecode('0:'), '' );
is( bdecode('3:abc'), 'abc' );
is( bdecode('10:1234567890'), '1234567890' );
is( bdecode('02:xy'), 'xy' );   #more relaxed, bencode.py will not accept this
is( bdecode('i03e') + 0, 3 );   #and this
{
    #and for pedantic ones
    local $Convert::Bencode_XS::COERCE = 0;
    is( bdecode('i03e'), 3 ); 
}
eval { bdecode('l') };
ok($@, "We should croak here: invalid format");

eval { bdecode('leanfdldjfh') };
ok($@, "We should croak here: invalid format");

eval { bdecode('relwjhrlewjh') };
ok($@, "We should croak here: invalid format");

eval { bdecode('d') };
ok($@, "We should croak here: invalid format");

eval { bdecode('defoobar') };
ok($@, "We should croak here: invalid format");

eval { bdecode('d3:fooe') };
ok($@, "we should croak here: invalid format");

eval { bdecode('d0:') };
ok($@, "we should croak here: invalid format");

eval { bdecode('d0:0:') };
ok($@, "we should croak here: invalid format");

eval { bdecode('l0:') };
ok($@, "we should croak here: invalid format");


SKIP: {
    #we use Storable so we do not rely on bencode
    eval q{use Storable qw(freeze)}; 
    skip "Storable not available", 12 if $@;
    local $Convert::Bencode_XS::COERCE = 0;
    is( freeze(bdecode('le')), freeze([]) );
    is( freeze(bdecode('l0:0:0:e')), freeze(['', '', '']) );
    is( freeze(bdecode('li1ei2ei3ee')), freeze([1, 2, 3]) );
    is( freeze(bdecode('l3:asd2:xye')), freeze(['asd', 'xy']) );
    is( freeze(bdecode('ll5:Alice3:Bobeli2ei3eee')),
            freeze([['Alice', 'Bob'], [2, 3]]) );
    is( freeze(bdecode('de')), freeze({}) );
    is( freeze(bdecode('d3:agei25e4:eyes4:bluee')), 
            freeze({age => 25, eyes => 'blue'}) );
    is( freeze(bdecode('d8:spam.mp3d6:author5:Alice6:lengthi100000eee')), 
            freeze({"spam.mp3" => {author => 'Alice', length => 100000}}) );
    #from here on we accept what bencode.py won't
    #(it's Perl after all, why being that strict in what we accept?)
    is( freeze(bdecode('di1e0:e')), freeze({1 => ''}) );
    is( freeze(bdecode('d1:b0:1:a0:e')), freeze({b => '', a => ''}) );
    is( freeze(bdecode('d1:a0:1:a0:e')), freeze({a => ''}) );
    is( freeze(bdecode('l01:ae')), freeze(['a']) );
}

is( bencode(4), 'i4e' );
is( bencode(0), 'i0e' );
is( bencode(-10), 'i-10e');
#we cheat in next test, taking advantage of $Convert::Bencode_XS::COERCE == 1
is( bencode("12345678901234567890"), 'i12345678901234567890e' );
is( bencode(''), '0:' );
is( bencode('abc'), '3:abc' );
{ #serializing something that looks like an int as a string is tricky
    local $Convert::Bencode_XS::COERCE = 0;
    is( bencode('1234567890'), '10:1234567890' );
}
is( bencode([]), 'le' );
is( bencode([1, 2, 3]), 'li1ei2ei3ee' );
is( bencode([['Alice', 'Bob'], [2, 3]]), 'll5:Alice3:Bobeli2ei3eee' );
is( bencode({}), 'de' );
is( bencode({age => 25, eyes => 'blue'}), 'd3:agei25e4:eyes4:bluee' );
is( bencode({'spam.mp3' => {author => 'Alice', length => 100000}}), 
    'd8:spam.mp3d6:author5:Alice6:lengthi100000eee' );
#we succeed in next one as all hash keys are naturally strings
is( bencode({1 => 'foo'}), 'd1:13:fooe');

#my tests
eval { bdecode('2:x') };
ok($@, "We should croak here: invalid format");

eval { bdecode('dli1ee4:ROOTe') };
ok($@, "We should croak here: invalid format");

is( bencode('0:0:'), '4:0:0:' );

eval { bencode({sub => sub{print "Heila!\n"}}) };
ok($@, "We should croak here: invalid format");

is ( length bencode({ join("", map chr($_), 0..255) => join("", map chr($_), 0..255) }), 1 + 4 + 256 + 4 + 256 + 1 );
