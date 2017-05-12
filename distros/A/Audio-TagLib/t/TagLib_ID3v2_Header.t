use Test::More tests => 24;
use version;

BEGIN { use_ok('Audio::TagLib::ID3v2::Header') };

sub convert_bytevector {
    my $bv = shift;
    my $iter = $bv->begin();
    my $l = 0;
    my @unpacked_bv;
    # This would be done better with an Iterator, but that requires == defined
    # as in c++: for(ByteVector::Iterator it = data.begin(); it != data.end(); it++) {
    # which is not accessible at this point
    while ( $l < $bv->size() ) {
        push @unpacked_bv, unpack 'C', $$iter;
        $iter->next();
        $l++;
    }
    return \@unpacked_bv;
}

my @methods = qw(new DESTROY majorVersion revisionNumber
unsynchronisation extendedHeader experimentalIndicator footerPresent
tagSize completeTagSize setTagSize setData render size fileIdentifier);
can_ok("Audio::TagLib::ID3v2::Header", @methods) 							or 
	diag("can_ok failed");

cmp_ok(Audio::TagLib::ID3v2::Header->size(), '==', 10)                                                or
    diag("static method size() failed");
cmp_ok(Audio::TagLib::ID3v2::Header->fileIdentifier(), 'eq', Audio::TagLib::ByteVector->new('ID3'))                                                or
    diag("static method fileIdentifier() failed");

my $i = Audio::TagLib::ID3v2::Header->new();
isa_ok($i, "Audio::TagLib::ID3v2::Header") 								    or 
	diag("method new() failed");
cmp_ok($i->majorVersion(), '==', 4)                                         or
	diag("method majorVersion() failed");
cmp_ok($i->revisionNumber(), '==', 0)                                       or
	diag("method revisionNumber() failed");
cmp_ok($i->unsynchronisation(), '==', 0)                                    or
	diag("method unsynchronisation() failed");
cmp_ok($i->experimentalIndicator(), '==', 0)                                or
	diag("method experimentalIndicator() failed");
cmp_ok($i->extendedHeader(), '==', 0)                                       or
	diag("method extendedHeader() failed");
cmp_ok($i->footerPresent(), '==', 0)                                        or
	diag("method footerPresent() failed");
cmp_ok($i->tagSize(), '==', 0)                                              or
    diag("method tagSize() failed");
cmp_ok($i->completeTagSize(), '==', 10)                                     or
    diag("method completeTagSize() failed");
$i->setTagSize(20);
cmp_ok($i->tagSize(), '==', 20)                                             or
    diag("method setTagSize() failed");
# Now we test the ability to specify a non-standard header tag
# We need 10 bytes (null-filled) version, revision, flags
my $head = "ID3\x{02}\x{03}\x{f0}\x{0}\x{0}\x{0}\x{0}";
my $data = Audio::TagLib::ByteVector->new($head, 10);
$i = Audio::TagLib::ID3v2::Header->new($data);
isa_ok($i, "Audio::TagLib::ID3v2::Header") 								    or 
	diag("method new(bytevector) failed");
cmp_ok($i->size(), '==', 10)                                                or
	diag("method new(bytevector) failed");
cmp_ok($i->majorVersion(), '==', 2)                                         or
	diag("method majorVersion() failed");
cmp_ok($i->revisionNumber(), '==', 3)                                       or
	diag("method revisionNumber() failed");
cmp_ok($i->unsynchronisation(), '==', 1)                                    or
	diag("method unsynchronisation() failed");
cmp_ok($i->experimentalIndicator(), '==', 1)                                or
	diag("method experimentalIndicator() failed");
cmp_ok($i->extendedHeader(), '==', 1)                                       or
	diag("method extendedHeader() failed");
cmp_ok($i->footerPresent(), '==', 1)                                        or
	diag("method footerPresent() failed");

chomp(my $ver = qx{taglib-config --version});
$is18 = $ver >= version->declare('1.8');

# Render changes things a bit
# The point to this test is to demonstrate that the
# render() method discards non-current values in the header.
# So, for example, the major version is changed from 2 to 4
# The experimentalIndicator flag is not cleared (bug??), so
# we replicate it in our baseline.

# Patch Festus-03 rt.cpan.org #79942
#$new_head = "ID3\x{04}\x{0}\x{20}\x{0}\x{0}\x{0}\x{0}";
# 9/25/2012
# According to taglib-1.8/taglib/mpeg/id3v2/id3v2header.cpp:render()
# The version is always set to 2.4.0 (4.0), however as of taglib-1.8
#   The majorVersion is carried through as is.
#   The revisionNumber is set to 0 (Zero).
#   The experimentalIndicator flag is carried through as is.
#   The rest are unsupported by taglib therfore set to false:
#     unsynchronisation
#     extendedHeader
#     footerPresent
#

# Mod for 1.63 - Make the data version-dependent

$new_head = $is18 ? "ID3\x{02}\x{0}\x{20}\x{0}\x{0}\x{0}\x{0}" :
                    "ID3\x{04}\x{0}\x{20}\x{0}\x{0}\x{0}\x{0}";
$new_data = Audio::TagLib::ByteVector->new($new_head, 10);
$new = convert_bytevector($new_data);
$render = convert_bytevector($i->render());

SKIP: {
    eval { require Test::Deep };
    skip "Test::Deep is not installed", 1 if $@;

    Test::Deep::cmp_deeply($new, $render, "Using taglib $ver")                                                   or
        diag("method render() failed");
}

# Demonstrate that illegal header data is accepted 
$data = Audio::TagLib::ByteVector->new("'twas brillig and ...");
$i = Audio::TagLib::ID3v2::Header->new($data);
cmp_ok($i->majorVersion(), '==', 97)                                         or
	diag("method majorVersion() failed");
