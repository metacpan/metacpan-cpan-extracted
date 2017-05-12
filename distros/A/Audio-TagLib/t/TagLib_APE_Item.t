use Test::More tests => 14;
use version;

BEGIN { use_ok('Audio::TagLib::APE::Item') };

my @methods = qw(new DESTROY copy key value size toString
                 toStringList render parse setReadOnly isReadOnly setType type
                 isEmpty);
can_ok("Audio::TagLib::APE::Item", @methods) 					     or 
	diag("can_ok failed");

ok(Audio::TagLib::APE::Item->new()->isEmpty()) 				         or 
	diag("method new() failed");
my $key    = Audio::TagLib::String->new("test");
my $value  = Audio::TagLib::String->new("This is a test");
my $values = Audio::TagLib::StringList->new($value);
my $i      = Audio::TagLib::APE::Item->new($key, $value);
my $j      = Audio::TagLib::APE::Item->new($key, $values);
my $k      = Audio::TagLib::APE::Item->new($i);
my $l      = Audio::TagLib::APE::Item->new();

is($i->key()->toCString(), $key->toCString()) 			             or 
	diag("method key() failed");
is($i->value()->data(),  undef) 				                     or 
	diag("method value() failed");

# Patch Festus-03 rt.cpan.org #79942
#cmp_ok($i->size(), "==", 13) 							             or 
#
# from taglib-1.8/taglib/ape/apeitem.cpp:170
# int result = 8 + d->key.size() /* d->key.data(String::UTF8).size() */ + 1;
# So, $key       = 13 ((test) + 9)
#     $value     = 14 (This is a test)
#     $i->size() = 27
#

# Mod for 1.63 - Make the size version-dependent
# Algorithm changed in v1.8.0.

chomp(my $ver = qx{taglib-config --version});
$is18 = $ver >= version->declare('1.8');
$size = $is18  ? 27 : 13;

cmp_ok($i->size(), "==", $size, "Using taglib $ver")                                        or 
    diag("method size() failed");
is($i->toString()->toCString(), $value->toCString()) 	             or 
	diag("method toString() failed");
is($i->toStringList()->toString()->toCString(), $value->toCString()) or
    diag("method toStringList() failed");
cmp_ok($i->render()->size(), "==", 27) 					             or 
	diag("method render() failed");
$l->parse($i->render());
is($l->key()->toCString(), $key->toCString()) 			             or 
	diag("method parse() failed");
$i->setReadOnly(1);
ok($i->isReadOnly()) 									             or 
	diag("method setReadOnly() failed");
$i->setReadOnly(0);
ok(not $i->isReadOnly()) 								             or 
	diag("method isReadOnly() failed");
$i->setType("Binary");
is($i->type(), "Binary") 								             or 
	diag("method type() failed");
$i->setType("Text");
ok(not $i->isEmpty()) 									             or 
	diag("method isEmpty() failed");
