use Test::More tests => 20;

BEGIN { use_ok('Audio::TagLib::APE::Footer') };

my @methods = qw(new DESTROY version headerPresent footerPresent isHeader setHeaderPresent
itemCount setItemCount tagSize completeTagSize renderFooter renderHeader fileIdentifier);
can_ok("Audio::TagLib::APE::Footer", @methods) 			                  or 
	diag("can_ok failed");

my $i = Audio::TagLib::APE::Footer->new();
cmp_ok($i->version(), "==", 0)	          				                  or 
	diag("new() failed");
cmp_ok(Audio::TagLib::APE::Footer->new(Audio::TagLib::ByteVector->new("blah"))->version(), 
	"==", 0)                                                              or
    diag("new(ByteVector v) failed");

ok(not $i->headerPresent())		                                          or
	diag("method headerPresent() failed");
$i->setHeaderPresent(1);
ok($i->headerPresent())			                                          or
	diag("method setHeaderPresent() failed");
ok($i->footerPresent())			                                          or 
	diag("method footerPresent() failed");
ok(not $i->isHeader())			                                          or 
	diag("method isHeader() failed");
cmp_ok($i->itemCount(), "==", 0)	                                      or 
	diag("method itemCount() failed");
$i->setHeaderPresent(0);
$i->setItemCount(3);
cmp_ok($i->itemCount(), "==", 3)	                                      or 
	diag("method setItemCount failed");
$i->setItemCount(0);
cmp_ok($i->tagSize(), "==", 0)		                                      or 
	diag("method tagSize() failed");
cmp_ok($i->completeTagSize(), "==", 0)              	                  or 
	diag("method completeTagSize() failed");
$i->setTagSize(3);
$i->setHeaderPresent(1);
cmp_ok($i->tagSize(), "==", 3)		                                      or 
	diag("method setTagSize() failed");
cmp_ok($i->completeTagSize(), "==", 35) 	                              or 
	diag("method setTagSize() failed");
$i->setTagSize(0);
$i->setHeaderPresent(0);
$i->setData(Audio::TagLib::ByteVector->new("blah"x8));
like($i->renderFooter()->data(), qr(^APETAGEX))	                          or 
	diag("method renderFooter() failed");
# cmp_ok() has a problem with comparing two undefs for ==
# cmp_ok($i->renderHeader()->data(), '==' undef)
ok(not defined $i->renderHeader()->data())                                or
	diag("method renderHeader() failed");
cmp_ok($i->size(), "==", 32)			                                  or
	diag("method size() failed");
cmp_ok(Audio::TagLib::APE::Footer->size(), "==", 32)	                  or 
	diag("method size() failed");
like($i->fileIdentifier()->data(), qr(^APETAGEX)) 		                  or
    diag("method fileIdentifier() failed");
like(Audio::TagLib::APE::Footer->fileIdentifier()->data(), qr(^APETAGEX)) or
    diag("method fileIdentifier() failed");
