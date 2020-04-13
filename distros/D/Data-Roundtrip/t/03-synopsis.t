#!/usr/bin/env perl

##!perl -T
use 5.006;
use strict;
use warnings;

use utf8;
binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN,  ':encoding(UTF-8)';
# to avoid wide character in TAP output
# do this before loading Test* modules
use open ':std', ':encoding(utf8)';

use Test::More;

my $num_tests = 0;

use Data::Roundtrip;

use Data::Roundtrip;

my $jsonstr = '{"Songname: Απόκληρος της κοινωνίας" : "Artist: Καζαντζίδης Στέλιος/Βίρβος Κώστας"}';
my $yamlstr = Data::Roundtrip::json2yaml($jsonstr);
print $yamlstr."\n";
#--- 
#abc-αβγ: χψζ-xyz 
$yamlstr = Data::Roundtrip::json2yaml($jsonstr, {'escape-unicode'=>1});
print $yamlstr."\n";
#---
#abc-\u03b1\u03b2\u03b3: \u03c7\u03c8\u03b6-xyz

# back to json but unescaped unicode chars
my $backtojson = Data::Roundtrip::yaml2json($yamlstr, {'escape-unicode'=>0});
print $backtojson."\n";

# back to json, escape unicode chars
$backtojson = Data::Roundtrip::yaml2json($yamlstr, {'escape-unicode'=>1});
print $backtojson."\n";

$yamlstr = Data::Roundtrip::json2yaml($backtojson, {'escape-unicode'=>0});
print "unescaped yaml:\n".$yamlstr."\n";
$yamlstr = Data::Roundtrip::json2yaml($backtojson, {'escape-unicode'=>1});
print "escaped yaml:\n".$yamlstr."\n";
my $newjson = Data::Roundtrip::yaml2json($yamlstr, {'escape-unicode'=>0});
print "unescaped json:\n".$newjson."\n";
$newjson = Data::Roundtrip::yaml2json($yamlstr, {'escape-unicode'=>1});
print "escaped json:\n".$newjson."\n";
for(1..3){
	$newjson = Data::Roundtrip::yaml2json($yamlstr, {'escape-unicode'=>1});
	$yamlstr = Data::Roundtrip::json2yaml($newjson, {'escape-unicode'=>1});
}
print "escaped json:\n".$newjson."\n";
print "escaped yaml:\n".$yamlstr."\n";  

for(1..3){
	$newjson = Data::Roundtrip::yaml2json($yamlstr, {'escape-unicode'=>0});
	$yamlstr = Data::Roundtrip::json2yaml($newjson, {'escape-unicode'=>0});
}
print "unescaped json:\n".$newjson."\n";
print "unescaped yaml:\n".$yamlstr."\n";  

my $dump = Data::Roundtrip::json2dump($jsonstr,
	{'dont-bloody-escape-unicode'=>1}
);
print "unescaped dump:\n".$dump."\n";
$dump = Data::Roundtrip::json2dump($jsonstr,
	{'dont-bloody-escape-unicode'=>0}
);
print "unescaped dump:\n".$dump."\n";


$dump = Data::Roundtrip::json2dump($jsonstr,
	{'dont-bloody-escape-unicode'=>0, 'terse'=>1, 'indent'=>0}
);
print "escaped, terse and with no indentations, dump:\n".$dump."\n";

$backtojson = Data::Roundtrip::dump2json($dump, {'escape-unicode'=>0});
print "unescaped json:\n".$backtojson."\n";
$backtojson = Data::Roundtrip::dump2json($dump, {'escape-unicode'=>1});
print "escaped json:\n".$backtojson."\n";

ok(1==1, "done"); $num_tests++;
done_testing($num_tests);
