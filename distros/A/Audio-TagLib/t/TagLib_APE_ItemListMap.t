use Test::More tests => 19;

BEGIN { use_ok('Audio::TagLib::APE::ItemListMap') };

my @methods = qw(new DESTROY begin end insert clear size isEmpty find
                 contains erase getItem copy);
can_ok("Audio::TagLib::APE::ItemListMap", @methods) 					or 
	diag("can_ok failed");

my $i = Audio::TagLib::APE::ItemListMap->new();
isa_ok($i, "Audio::TagLib::APE::ItemListMap") 							or 
	diag("method new() failed");
isa_ok(Audio::TagLib::APE::ItemListMap->new($i), 
	"Audio::TagLib::APE::ItemListMap") 								    or 
	diag("method new(map) failed");
isa_ok($i->begin(), "Audio::TagLib::APE::ItemListMap::Iterator") 		or 
	diag("method begin() failed");
isa_ok($i->end(), "Audio::TagLib::APE::ItemListMap::Iterator") 		    or 
	diag("method end() failed");
my $key = Audio::TagLib::String->new("key");
my $value = Audio::TagLib::String->new("value");
my $item = Audio::TagLib::APE::Item->new($key, $value);
isa_ok($i->find($key), "Audio::TagLib::APE::ItemListMap::Iterator") 	or 
	diag("method find(key) failed");
$i->insert($key, $item);
cmp_ok($i->size(), "==", 1) 									        or 
	diag("method insert(key, item) and size() failed");
$i->clear();
cmp_ok($i->size(), "==", 0) 									        or 
	diag("method clear() failed");
ok($i->isEmpty()) 												        or 
	diag("method isEmpty() failed");
$i->insert($key, $item);
ok($i->contains($key)) 											        or 
	diag("method contains(key) failed");
$i->erase($key);
ok(not $i->contains($key)) 										        or 
	diag("method erase(key) failed");
$i->insert($key, $item);
is($i->getItem($key)->toString()->toCString(), "value") 		        or 
	diag("method getItem(key) failed");
################################################################
# NOW START TO TEST TIE MAGIC
################################################################
tie my %j, "Audio::TagLib::APE::ItemListMap", $i;
isa_ok(tied %j, "Audio::TagLib::APE::ItemListMap") 					    or 
	diag("method TIEHASH failed");
$j{$key} = $item;
is($j{$key}->toString()->toCString(), "value") 					        or 
	diag("method FETCH and STORE failed");
%j = ();
cmp_ok(scalar(%j), "==", 0) 									        or 
	diag("method CLEAR and SCALAR failed");
$j{$key} = $item;
ok(exists $j{$key}) 											        or 
	diag("method EXISTS failed");
my @keys = keys %j;
cmp_ok($#keys+1, "==", scalar(%j)) 								        or 
	diag("method FIRSTKEY and NEXTKEY failed");
{ no warnings q(untie); untie %j; }
ok(not %j) 														        or 
	diag("method UNTIE failed");
