#!perl -T
use 5.008;
use strict;
use warnings;

use utf8;

our $VERSION='0.30';

use Test::More;
use Test2::Plugin::UTF8;

my $num_tests = 0;

use Data::Roundtrip qw/dump2json/;

# we are printing to stdout utf8
binmode STDOUT, ':encoding(UTF-8)';

my $jsonstr = '{"Songname": "Απόκληρος της κοινωνίας", "Artist": "Καζαντζίδης Στέλιος/Βίρβος Κώστας"}';
my $yamlstr = Data::Roundtrip::json2yaml($jsonstr);
print $yamlstr."\n";
#---
#Artist: Καζαντζίδης Στέλιος/Βίρβος Κώστας
#Songname: Απόκληρος της κοινωνίας

$yamlstr = Data::Roundtrip::json2yaml($jsonstr, {'escape-unicode'=>1});
print $yamlstr."\n";
#---
#Artist: \u039a\u03b1\u03b6\u03b1\u03bd\u03c4\u03b6\u03af\u03b4\u03b7\u03c2 \u03a3\u03c4\u03ad\u03bb\u03b9\u03bf\u03c2/\u0392\u03af\u03c1\u03b2\u03bf\u03c2 \u039a\u03ce\u03c3\u03c4\u03b1\u03c2
#Songname: \u0391\u03c0\u03cc\u03ba\u03bb\u03b7\u03c1\u03bf\u03c2 \u03c4\u03b7\u03c2 \u03ba\u03bf\u03b9\u03bd\u03c9\u03bd\u03af\u03b1\u03c2


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
print "escaped dump:\n".$dump."\n";
$dump = Data::Roundtrip::json2dump($jsonstr,
	{'dont-bloody-escape-unicode'=>1, 'terse'=>1, 'indent'=>1}
);
print "unescaped, terse dump:\n".$dump."\n";

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
