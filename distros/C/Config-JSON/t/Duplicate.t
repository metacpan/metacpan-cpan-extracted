use strict;
use warnings;
use Test::More tests => 22;

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

# delete 
my $mainConfig = Config::JSON->new($mainConfigFile);
$mainConfig->delete("dsn");
ok(!(defined getKey($mainConfigFile, "dsn")), "delete() writes changes for scalar in main file");
ok(!(defined getKey($firstIncludeFile, "dsn")), "delete() writes changes for scalar in first include file");
ok(!(defined getKey($secondIncludeFile, "dsn")), "delete() writes changes for scalar in second include file");
ok(!(defined $mainConfig->get("dsn")), "delete() works for scalar in main file");
$mainConfig->delete("stats/vitality");
ok(!(defined getKey($mainConfigFile, "stats/vitality")), "delete() multilevel works for main file");
ok(!(defined getKey($firstIncludeFile, "stats/vitality")), "delete() multilevel works for first include file");
ok(!(defined getKey($secondIncludeFile, "stats/vitality")), "delete() multilevel works for second include file");
ok(!(defined $mainConfig->get("stats/vitality")), "delete() multilevel works for main file");
ok(defined getKey($mainConfigFile, "stats"), "delete() multilevel - doesn't delete parent in main file");
ok(defined getKey($firstIncludeFile, "stats"), "delete() multilevel - doesn't delete parent in first include file");
ok(defined getKey($secondIncludeFile, "stats"), "delete() multilevel - doesn't delete parent in second include file");
ok(defined $mainConfig->get("stats"), "delete() multilevel - doesn't delete parent in main file");
$mainConfig->delete('this/that/hash');
ok(!(defined getKey($firstIncludeFile, "this/that/hash")), "delete() works for multilevel in first include file");
ok(!(defined getKey($secondIncludeFile, "this/that/hash")), "delete() works for multilevel in second include file");
ok(!(defined getKey($mainConfigFile, "this/that/hash")), "delete() works for multilevel in main file");
ok(!(defined $mainConfig->get("this/that/hash")), "delete() works for multilevel in main file");
ok(defined getKey($firstIncludeFile, 'this/that'), "delete() on multilevel doesn't delete parent in first include file");
ok(defined getKey($secondIncludeFile, 'this/that'), "delete() on multilevel doesn't delete parent in second include file");
ok(defined getKey($mainConfigFile, 'this/that'), "delete() on multilevel doesn't delete parent in main file");


#----------------------------------------------------
# get a value from a config file that has includes. Can't use Config::JSON
# because the main file includes the other files, which means the value we're
# looking for will be found regardless. that's what we're testing, so we have
# to use raw JSON.
sub getKey {
    my $configFile = shift;
    my $key = shift;
    my @parts = split '/', $key;
    my $lastPart = pop @parts;
    open my $fh, '<', $configFile or die "open($configFile): $!";
    my $raw = do {
        local $/;
        <$fh>;
    };
    close $fh;
    my $data = JSON->new->relaxed(1)->decode($raw);
    my $directive = $data;
    for my $part (@parts) {
        $directive = $directive->{$part};
    }
    return $directive->{$lastPart};
}

