use Test::More tests => 36;

use lib '../lib';
use Test::Deep;
use Config::JSON;
use File::Temp qw/ tempfile /;

my ($fh, $filename) = tempfile();
close($fh);
my $config = Config::JSON->create($filename);
ok (defined $config, "create new config");

# set up test data
if (open(my $file, ">", $filename)) {
my $testData = <<END;
# config-file-type: JSON 1

 {
        "dsn" : "DBI:mysql:test",
        "user" : "tester",
        "password" : "xxxxxx", 

        # some colors to choose from
        "colors" : [ "red", "green", "blue" ],

        # some statistics
        "stats" : {
                "health" : 32,
                "vitality" : 11
        },

        # multilevel
        "this" : {
            "that" : {
                "scalar" : "foo",
                "array" : ["foo", "bar"],
                "hash" : { 
                    "foo" : 1,
                    "bar" : 2
                }
            }
        }
 } 

END
	print {$file} $testData;
	close($file);
	ok(1, "set up test data");
} 
else {
	ok(0, "set up test data");
}

$config = Config::JSON->new($filename);
isa_ok($config, "Config::JSON" );

# getFilePath and getFilename
is( $config->getFilePath, $filename, "getFilePath()" );
my $justTheName = $filename;
$justTheName =~ s{.*/(\w+)$}{$1}xmsg;
is( $config->getFilename, $justTheName, "getFilename()" );

# get
ok( $config->get("dsn") ne "", "get()" );
is( ref $config->get("stats"), "HASH", "get() hash" );
is( ref $config->get("colors"), "ARRAY", "get() array" );
is( $config->get("this/that/scalar"), "foo", "get() multilevel");
is( ref $config->get("this/that/hash"), "HASH", "get() hash multilevel" );
is( ref $config->get("this/that/array"), "ARRAY", "get() array multilevel" );
eval{$config->get("this/that/array/non-existant-element")};
ok($@, "Throw an error when trying to access an element of an array.");

# set
$config->set('privateArray', ['a', 'b', 'c']);
cmp_bag($config->get('privateArray'), ['a', 'b', 'c'], 'set()');
$config->set('cars/ford', "mustang");
is($config->get('cars/ford'), "mustang", 'set() multilevel non-exisistant');
$config->set('cars/ford', [qw( mustang pinto maverick )]);
cmp_bag($config->get('cars/ford'),[qw( mustang pinto maverick )], 'set() multilevel');
$config->addToHash('hash','cdn\\/','CDNRoot');
my $hash = $config->get('hash');
is $hash->{'cdn/'}, 'CDNRoot', 'allow for escaped slashes in keys';
my $reconfig = Config::JSON->new($filename);
cmp_bag($config->get('cars/ford'),$reconfig->get('cars/ford'), 'set() multilevel after re-reading config file');
$config->set('Data::GUID', '9EDE9D96-D416-11DF-A7FC-B391564030AF');
is($config->get('Data::GUID'), '9EDE9D96-D416-11DF-A7FC-B391564030AF', 'report that Data::GUID does not work with CJ');

# delete 
$config->delete("dsn");
ok(!(defined $config->get("dsn")), "delete()");
$config->delete("stats/vitality");
ok(!(defined $config->get("stats/vitality")), "delete() multilevel");
ok(defined $config->get("stats"), "delete() multilevel - doesn't delete parent");
$config->delete('this/that/hash');
ok(defined $config->get('this/that/scalar'), "delete() multilevel - doesn't delete siblings");

# addToArray
$config->addToArray("colors","TEST");
ok((grep /TEST/, @{$config->get("colors")}), "addToArray()");
$config->addToArray("cars/ford", "fairlane");
ok((grep /fairlane/, @{$config->get("cars/ford")}), "addToArray() multilevel");

# deleteFromArray
$config->deleteFromArray("colors","TEST");
ok(!(grep /TEST/, @{$config->get("colors")}), "deleteFromArray()");
$config->deleteFromArray("cars/ford", "fairlane");
ok(!(grep /fairlane/, @{$config->get("cars/ford")}), "deleteFromArray() multilevel");

# addToArrayBefore
$config->addToArrayBefore("colors","green",'orange');
is_deeply($config->get('colors'), [qw(red orange green blue)], "addToArrayBefore works");
$config->addToArrayBefore("colors","green",'orange');
is_deeply($config->get('colors'), [qw(red orange green blue)], "addToArrayBefore doesn't insert duplicate entries");
$config->addToArrayBefore('colors', 'purple', 'black');
is_deeply($config->get('colors'), [qw(black red orange green blue)], "addToArrayBefore with item that doesn't exist adds to beginning of array");
$config->set('colors', [qw(red green blue)]);

# addToArrayAfter
$config->addToArrayAfter('colors', 'green', 'orange');
is_deeply($config->get('colors'), [qw(red green orange blue)], "addToArrayAfter works");
$config->addToArrayAfter('colors', 'green', 'orange');
is_deeply($config->get('colors'), [qw(red green orange blue)], "addToArrayAfter doesn't insert duplicate entries");
$config->addToArrayAfter('colors', 'purple', 'black');
is_deeply($config->get('colors'), [qw(red green orange blue black)], "addToArrayAfter with item that doesn't exist adds to end of array");
$config->set('colors', [qw(red green blue)]);

# addToHash
$config->addToHash("stats","TEST","VALUE");
is($config->get("stats/TEST"), "VALUE", "addToHash()");
$config->addToHash("this/that/hash", "three", 3);
is($config->get("this/that/hash/three"), 3, "addToHash() multilevel");

# deleteFromHash
$config->deleteFromHash("stats","TEST");
$hash = $config->get("stats");
ok(!(exists $hash->{TEST}), "deleteFromHash()");
$config->deleteFromHash("this/that/hash", "three");
$hash = $config->get("this/that/hash");
ok(!(exists $hash->{three}), "deleteFromHash() multilevel");


