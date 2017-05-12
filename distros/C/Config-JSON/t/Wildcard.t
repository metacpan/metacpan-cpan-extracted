use strict;
use warnings;
use Test::More tests => 12;

use lib '../lib';
use Test::Deep;
use Config::JSON;
use File::Temp qw/ tempfile /;
use JSON;

my ($mainHandle, $mainConfigFile) = tempfile();
my ($firstIncludeHandle, $firstIncludeFile) = tempfile('XXXXX', SUFFIX => '.include.conf', UNLINK => 1);
my ($secondIncludeHandle, $secondIncludeFile) = tempfile('XXXXX', SUFFIX => '.include.conf', UNLINK => 1);
close($mainHandle);
close($firstIncludeHandle);
close($secondIncludeHandle);
my $mainConfig = Config::JSON->create($mainConfigFile);
my $firstConfig = Config::JSON->create($firstIncludeFile);
my $secondConfig = Config::JSON->create($secondIncludeFile);

# set up main config file with include section
if (open(my $file, ">", $mainConfigFile)) {
    my $testData = <<END;

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

    "includes" : [ "*.include.conf"]
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

