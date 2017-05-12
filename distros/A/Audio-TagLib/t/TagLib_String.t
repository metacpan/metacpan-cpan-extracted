use Test::More tests => 43;
use Encode qw(encode decode);

BEGIN { use_ok('Audio::TagLib::String') };

my @methods = qw(new DESTROY to8Bit toCString begin end find substr
                 append upper size isEmpty isNull data toInt stripWhiteSpace getChar
                 _equal _append copy _lessThan number null);
can_ok("Audio::TagLib::String", @methods)                                       or 
    diag("can_ok failed");

my $i = Audio::TagLib::String->new();
my $s_latin1 = Audio::TagLib::String->new(Audio::TagLib::String->new("string test 1"));
is($s_latin1->to8Bit(), "string test 1")						                    or
	diag("method new(ascii) failed");
is(Audio::TagLib::String->new(Audio::TagLib::ByteVector->new("STRING TEST 2"))->to8Bit(), "STRING TEST 2") or 
	diag("method new(ByteVector) failed");

# These are needed for fixing UTF16. Cf. also http://en.wikipedia.org/wiki/Byte_order_mark 
my $BOM_LE = 0xfffe;
my $BOM_BE = 0xfeff;

# An arbitrary seletion of non-ASCII Latin-1 characters
my $gb2312 			= chr(0316). # Î  LATIN CAPITAL LETTER I WITH CIRCUMFLEX
                      chr(0322). # Ò  LATIN CAPITAL LETTER O WITH GRAVE
                      chr(0265). # µ  MICRO SIGN
                      chr(0304); # Å  LATIN CAPITAL LETTER A WITH RING ABOVE
# The same thing in a different representation
my $utf8_hardcode 	= "\x{6211}\x{7684}";
# This conversion should be a no-op
my $utf8 			= decode("GB2312", $gb2312);
# Various representations
# These encodings affect byte order only. There is NO BOM prepended
my $utf16be 		= encode("UTF16BE", $utf8);
my $utf16le 		= encode("UTF16LE", $utf8);
my $utf16 			= encode("UTF16", $utf8);
# $utf16 has been encoded as big-endian (aka network order) with a  BE BOM prepended.
# even though we may be executing on a little-endian # system.
# This is the defined behavior for Encode::Unicode. 
my $s_utf8 = Audio::TagLib::String->new($utf8);

is($s_utf8->to8Bit("true"), $utf8_hardcode)					                    or 
	diag("method new(utf8) failed");

is(Audio::TagLib::String->new($utf8_hardcode)->to8Bit("true"),$utf8_hardcode)   or
    diag("method new(utf8) failed");

is(Audio::TagLib::String->new($utf8, "UTF8")->to8Bit("true"), $utf8_hardcode)   or
    diag(qq{method new(utf8, "UTF8") failed}); 

my $s_utf16be = Audio::TagLib::String->new($utf16be, "UTF16BE");
is($s_utf16be->to8Bit("true"), $utf8_hardcode) 				                    or 
	diag(qq{method new(utf16be, "UTF16BE") failed});

my $s_utf16le = Audio::TagLib::String->new($utf16le, "UTF16LE");
is($s_utf16le->to8Bit("true"), $utf8_hardcode) 				                    or 
	diag(qq{method new(utf16le, "UTF16LE") failed});

my $s_utf16 = Audio::TagLib::String->new($utf16, "UTF16");
is($s_utf16->to8Bit("true"), $utf8_hardcode) 				                    or 
	diag(qq{method new(utf16, "UTF16") failed});

is($s_utf16->toCString("true"), $utf8_hardcode) 			                    or 
	diag("method toCString(O failed");

# Index into "string test 1"
cmp_ok($s_latin1->find(Audio::TagLib::String->new("ri")), "==", 2) 	            or 
	diag("method find(string) failed");

# Index into "string test 1" 13
cmp_ok($s_latin1->find(Audio::TagLib::String->new("te"), 4), "==", 7) 	        or 
	diag("method find(string, offset) failed");

# Index into "string test 1" 14
is($s_latin1->substr(0, 4)->to8Bit(), "stri")					                or
	diag("method substr(position, n) failed");

# 15
is($s_utf16be->substr(0, 2)->to8Bit("true"), $utf8_hardcode) 	                or
	diag("method substr(position, n) failed");

# 16
is($s_latin1->append(Audio::TagLib::String->new(" appended"))->to8Bit(), "string test 1 appended") or
    diag("method append(string) failed");

# 17
is($s_utf8->append($s_utf16be)->to8Bit("true"), $utf8_hardcode x 2)             or
    diag("method append(string) failed");

# 18
# s_latin1 becomes "string te" 
$s_latin1 = $s_latin1->substr(0, 9);
is($s_latin1->upper()->to8Bit(), "STRING TE") 					                or
	diag("method upper() failed");

# 19
cmp_ok($s_latin1->size(), "==", length($s_latin1->to8Bit())) 	                or
	diag("method size() failed");

# 20
$s_utf8 = $s_utf8->substr(0, 2);
cmp_ok($s_utf8->size(), "==", length($s_utf8->to8Bit("true"))) 	                or
	diag("method size() failed");

# 21
ok(Audio::TagLib::String->new()->isEmpty()) 							        or
	diag("method isEmtpy() failed");

# 22
ok(not $s_latin1->isEmpty()) 									                or
	diag("method isEmtpy() failed");

# 23
ok(Audio::TagLib::String->null()->isNull()) 							        or 
	diag("method null() failed");

# 24
ok(not $s_latin1->isNull()) 									                or 
	diag("method isNull() failed");

# 25
is($s_latin1->data("Latin1")->data(), "string te") 				                or
	diag("method data(latin1) failed");

# 26
is($s_utf8->data("UTF8")->data(), $utf8_hardcode) 				                or
	diag("method data(utf8) failed");

# 27
# Test the assertion that the data is BE-encoded
is($s_utf8->data("UTF16BE")->data(), $utf16be) 					                or
	diag("method data(utf16be) failed");

# 28
# Test the assertion that the data is LE-encoded
is($s_utf8->data("UTF16LE")->data(), $utf16le) 					                or
	diag("method data(utf16le) failed");

# 29
# What this test is checking is whether TagLib encodes $utf8 in the same way as 
# Encode, which it does not. Note that neither encoding choice depends on system endian-ness
# $utf16 is $utf8 data BE-encoded (see above comment re Encode)
# Comment in TagLib ByteVector String::data(Type t) for t == UtF16
# // Assume that if we're doing UTF16 and not UTF16BE that we want little
# // endian encoding.  (Byte Order Mark)
# We test the above assertion by constructing a LE-encoded utf16 with a LE BOM
my $utf16le_with_BOM = "  $utf16le";
vec($utf16le_with_BOM, 0, 16) =  $BOM_LE;
is($s_utf8->data("UTF16")->data(), $utf16le_with_BOM) 						    or 
	diag("method data(utf16) did not execute as expected");

cmp_ok(Audio::TagLib::String->new("a")->toInt(), "==", oct("a")) 		        or
	diag("method toInt() failed");

is(Audio::TagLib::String->new("   blanks   ")->stripWhiteSpace()->to8Bit(), "blanks") or
    diag("method stripWhiteSpace() failed");

is($s_latin1->getChar(1), "t") 									                or 
	diag("method getChar(i) failed");

is($s_utf8->getChar(1), "\x{7684}") 							                or 
	diag("method getChar(i) failed");

ok($s_latin1 == Audio::TagLib::String->new("string te")) 				        or 
	diag("method _equal(s, '') failed");

ok($s_utf8 == Audio::TagLib::String->new($utf8_hardcode)) 				        or 
	diag("method _equal(s, '') failed");

$s_latin1 += " appended";
is($s_latin1->toCString(), "string te appended") 					            or 
	diag("method _append(string) failed");

$s_latin1 += Audio::TagLib::String->new(" again");
is($s_latin1->toCString(), "string te appended again") 				            or 
	diag("method _append(String) failed");

$s_utf8 += "test";
is($s_utf8->toCString("true"), $utf8_hardcode . "test") 		                or 
	diag("method _append(string) failed");

ok(Audio::TagLib::String->new("a") < Audio::TagLib::String->new("b")) 		    or 
	diag("method _lessThan(string) failed");

ok(Audio::TagLib::String->new("b") > Audio::TagLib::String->new("a")) 		    or 
	diag("method _lessThan(string) failed");

is(Audio::TagLib::String->number(10)->toCString(), "10") 				        or 
	diag("method number(string) failed");

my $s1 = Audio::TagLib::String->new("abcd");
my $s2 = Audio::TagLib::String->new($s1);
cmp_ok($s1->toCString(), "eq", $s2->toCString())                                or
    diag("deep copy failed");

my $s3 =  Audio::TagLib::String->new("xyz");
$s3 = $s1;
cmp_ok($s3->toCString(), "eq", $s1->toCString())                                or
    diag("shallow copy failed");
