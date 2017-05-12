use strict;
use warnings;
use Test::More tests => 55;

use lib '../lib';
use Test::Deep;
use Config::JSON;
use File::Temp qw/ tempfile /;
use JSON;

my ($mainHandle, $mainConfigFile) = tempfile();
my ($firstIncludeHandle, $firstIncludeFile) = tempfile();
my ($secondIncludeHandle, $secondIncludeFile) = tempfile();
close($mainHandle);
close($firstIncludeHandle);
close($secondIncludeHandle);
my $mainConfig = Config::JSON->create($mainConfigFile);
my $firstConfig = Config::JSON->create($firstIncludeFile);
my $secondConfig = Config::JSON->create($secondIncludeFile);

# set up main config file with include section
if (open(my $file, ">", $mainConfigFile)) {
    my $testData = <<END;
# config-file-type: JSON 1
{
    "dsn" : "DBI:mysql:test",
    "user" : "tester",
    "password" : "xxxxxx", 

    "colors" : [ "red", "green", "blue" ],

    "stats" : {
        "health" : 32,
        "vitality" : 11
    },

    "this" : {
        "that" : {
            "scalar" : "foo",
            "array" : ["foo", "bar"],
            "hash" : { 
                "foo" : 1,
                "bar" : 2
            }
        }
    },

    "includes" : [ "$firstIncludeFile", "$secondIncludeFile"]
} 

END
    print $file $testData;
    close($file);
    ok(1, "set up test data");
} 
else {
    ok(0, "set up test data");
}

# set up the first include file
if( open my $file, '>', $firstIncludeFile ) {
    my $testData = <<END;
# config-file-type: JSON 1
{
    "firstFileName" : "$firstIncludeFile",
    "metasyntacticVariables" : ["foo", "bar", "baz"],
    "myFavoriteColors" : {
        "mostFavorite" : "black",
        "leastFavorite" : "white"
    },
    "cars" : {
        "ford" : [
            "maverick",
            "mustang",
            "pinto"
        ]
    }
} 
END
    print $file $testData;
    close $file;
    ok(1, "set up first include test data");
}
else {
    ok(0, "set up first include file");
}

if( open my $file, '>', $secondIncludeFile ) {
    my $testData = <<END;
# config-file-type: JSON 1
{
    "secondFileName" : "$secondIncludeFile",
    "programmingLanguages" : ["perl", "python", "intercal"],
    "OSVendors" : {
        "OS X" : "Apple",
        "Windows" : "Microsoft"
    }
} 
END
    print $file $testData;
    close $file;
    ok(1, "set up second include test data");
}
else {
    ok(0, "set up second include file");
}
$mainConfig = Config::JSON->new($mainConfigFile);
isa_ok($mainConfig, "Config::JSON" );

# getFilePath and getFilename
is( $mainConfig->getFilePath, $mainConfigFile, "getFilePath()" );
my $justTheName = $mainConfigFile;
$justTheName =~ s{.*/(\w+)$}{$1}xmsg;
is( $mainConfig->getFilename, $justTheName, "getFileName()" );

# getFilePaths and getFilenames
#cmp_deeply( $mainConfig->getFilePaths, ($mainConfigFile, $firstIncludeFile, $secondIncludeFile), "getFilePaths()" );
#my @justTheNames = map { s{.*/(\w+)$}{$1}xmsg, $_ } ($mainConfigFile, $firstIncludeFile, $secondIncludeFile);
#cmp_deeply( $mainConfig->getFileNames, @justTheNames, "getFileNames()" );

# get
# first, make sure stuff in the main file works
is( $mainConfig->get('dsn'), 'DBI:mysql:test', 'get() scalar' );
cmp_deeply( $mainConfig->get('colors'), ['red', 'green', 'blue'], 'get() arrayref' );
cmp_deeply( $mainConfig->get('stats'), {health => 32, vitality => 11}, 'get() hashref' );

# now make sure stuff in the included files work
is( $mainConfig->get('firstFileName'), $firstIncludeFile, 'get() first include scalar' );
is( $mainConfig->get('secondFileName'), $secondIncludeFile, 'get() second include scalar' );
cmp_deeply( $mainConfig->get('metasyntacticVariables'), ['foo', 'bar', 'baz'], 'get() first include arrayref' );
cmp_deeply( $mainConfig->get('programmingLanguages'), ['perl', 'python', 'intercal'], 'get() second include arrayref' );
cmp_deeply( $mainConfig->get('myFavoriteColors'), {mostFavorite => 'black', leastFavorite => 'white'}, 'get() first include hashref' );
cmp_deeply( $mainConfig->get('OSVendors'), {'OS X' => 'Apple', 'Windows' => 'Microsoft'}, 'get() first include hashref' );

# set
# testing set is different for includes because we have to make sure that the
# key goes to the right file. thus we need to check the files after writing to
# ensure that the correct key was written to the correct file.
$mainConfig->set('dsn', 'DBI:mysql:test2');
is( getKey($mainConfigFile, 'dsn'), 'DBI:mysql:test2', 'set() works for existing scalar in main file');
is( getKey($firstIncludeFile, 'dsn'), undef, 'set() does not write to the wrong file for an existing scalar');
is( getKey($secondIncludeFile, 'dsn'), undef, 'set() does not write to the wrong file for an existing scalar');

$mainConfig->set('foobar', 'the foobar value');
is( getKey($mainConfigFile, 'foobar'), 'the foobar value', 'set() works for new value in main file');
is( getKey($firstIncludeFile, 'foobar'), undef, 'set() does not write to the wrong file for a new scalar');
is( getKey($secondIncludeFile, 'foobar'), undef, 'set() does not write to the wrong file for a new scalar');

$mainConfig->set('colors', ['blue', 'green', 'red']);
cmp_deeply( getKey($mainConfigFile, 'colors'), ['blue', 'green', 'red'], 'set() works for existing array in main file' );
is( getKey($firstIncludeFile, 'colors'), undef, 'set() does not write to the wrong file for an existing array');
is( getKey($secondIncludeFile, 'colors'), undef, 'set() does not write to the wrong file for an existing array');

$mainConfig->set('numbers', ['one', 'two', 'three']);
cmp_deeply( getKey($mainConfigFile, 'numbers'), ['one', 'two', 'three'], 'set() works for existing array in main file' );
is( getKey($firstIncludeFile, 'numbers'), undef, 'set() does not write to the wrong file for a new array');
is( getKey($secondIncludeFile, 'numbers'), undef, 'set() does not write to the wrong file for a new array');

$mainConfig->set('stats', { height => 65, weight => 'none of your business' });
cmp_deeply( getKey($mainConfigFile, 'stats'), { height => 65, weight => 'none of your business'}, 'set() works for existing hash in main file' );
is( getKey($firstIncludeFile, 'stats'), undef, 'set() does not write to the wrong file for an existing hash');
is( getKey($secondIncludeFile, 'stats'), undef, 'set() does not write to the wrong file for an existing hash');

$mainConfig->set('developerNames', { 'JT' => 'Smith', 'Chris' => 'Nehren' } );
cmp_deeply( getKey($mainConfigFile, 'developerNames'), { 'JT' => 'Smith', 'Chris' => 'Nehren' }, 'set() works for a new hash in main file' );
is( getKey($firstIncludeFile, 'developerNames'), undef, 'set() does not write to the wrong file for a new hash');
is( getKey($secondIncludeFile, 'developerNames'), undef, 'set() does not write to the wrong file for a new hash');

$mainConfig->set('firstFileName', "$firstIncludeFile first");
is( getKey($firstIncludeFile, 'firstFileName'), "$firstIncludeFile first", 'set() writes a scalar to the correct include file');
is( getKey($mainConfigFile, 'firstFileName'), undef, 'set() does not write to the wrong file for a scalar in an include file');
is( getKey($secondIncludeFile, 'firstFileName'), undef, 'set() does not write to the wrong file for a scalar in an include file');

$mainConfig->set('metasyntacticVariables', ['baz', 'bar', 'foo']);
cmp_deeply( getKey($firstIncludeFile, 'metasyntacticVariables'), ['baz', 'bar', 'foo'], 'set() works for an existing array in an include file' );
is( getKey($mainConfigFile, 'metasyntacticVariables'), undef, 'set() does not write to the wrong file for an existing array in an include file');
is( getKey($secondIncludeFile, 'metasyntacticVariables'), undef, 'set() does not write to the wrong file for an existing array in an include file');

$mainConfig->set('myFavoriteColors', { 'black' => 'mostFavorite', 'white' => 'leastFavorite' } );
cmp_deeply( getKey($firstIncludeFile, 'myFavoriteColors'), { 'black' => 'mostFavorite', 'white' => 'leastFavorite' }, 'set() works for an existing hash in an include file' );
is( getKey($mainConfigFile, 'myFavoriteColors'), undef, 'set() does not write to the wrong file for an existing hash in an include file');
is( getKey($secondIncludeFile, 'myFavoriteColors'), undef, 'set() does not write to the wrong file for an existing hash in an include file');

# delete 
$mainConfig->delete("dsn");
ok(!(defined getKey($mainConfigFile, "dsn")), "delete() writes changes for scalar in main file");
ok(!(defined $mainConfig->get("dsn")), "delete() works for scalar in main file");
$mainConfig->delete("stats/vitality");
ok(!(defined getKey($mainConfigFile, "stats/vitality")), "delete() multilevel works for main file");
ok(!(defined $mainConfig->get("stats/vitality")), "delete() multilevel works for main file");
ok(defined getKey($mainConfigFile, "stats"), "delete() multilevel - doesn't delete parent in main file");
ok(defined $mainConfig->get("stats"), "delete() multilevel - doesn't delete parent in main file");
$mainConfig->delete('firstFileName');
ok(!(defined getKey($firstIncludeFile, "firstFileName")), "delete() works for scalar in first include file");
ok(!(defined $mainConfig->get("dsn")), "delete() works for scalar in main file");
$mainConfig->delete('metasyntacticVariables');
ok(!(defined getKey($firstIncludeFile, "metasyntacticVariables")), "delete() works for multilevel in first include file");
ok(!(defined $mainConfig->get("metasyntacticVariables")), "delete() works for multilevel in main file");
$mainConfig->delete('cars/ford');
ok(!(defined getKey($firstIncludeFile, "cars/ford")), "delete() works for multilevel in first include file");
ok(!(defined $mainConfig->get("cars/ford")), "delete() works for multilevel in main file");
ok(defined getKey($firstIncludeFile, 'cars'), "delete() on multilevel doesn't delete parent in include file");


#----------------------------------------------------
# get a value from a config file that has includes. Can't use Config::JSON
# because the main file includes the other files, which means the value we're
# looking for will be found regardless. that's what we're testing, so we have
# to use raw JSON.
sub getKey {
    my $configFile = shift;
    my $key = shift;
    open my $fh, '<', $configFile or die "open($configFile): $!";
    my $raw = do {
        local $/;
        <$fh>;
    };
    close $fh;
    my $data = JSON->new->relaxed(1)->decode($raw);
    return $data->{$key};
}
