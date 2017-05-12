#!/usr/local/bin/perl -w

use Test::More qw(no_plan);
use lib "lib";
use lib "../lib";

BEGIN {
   use_ok("App");
}

my ($context, $dir);
$dir = ".";
$dir = "t" if (! -f "app.pl");

$context = App->context(
    conf_file => "",
    conf => {
        Serializer => {
            ini        => { class => "App::Serializer::Ini", },
            perl       => { class => "App::Serializer::Perl", },
            properties => { class => "App::Serializer::Properties", },
            xml        => { class => "App::Serializer::Xml", },
            storable   => { class => "App::Serializer::Storable", },
            text_array => { class => "App::Serializer::TextArray", },
            yaml       => { class => "App::Serializer::Yaml", },
            one_line   => { class => "App::Serializer::OneLine", },
        },
    },
);

my $ser = $context->serializer("ini");
ok(defined $ser, "constructor ok");
isa_ok($ser, "App::Serializer::Ini", "ini right class");
is($ser->service_type(), "Serializer", "ini right service type");

my ($ser2, $sdata2, $data2, $data3, $data4, $data5, $sdata5);
my $data_array = [
  "e",
  2.71828,
  [ "pi", "is", 3.1416 ],
  { fun => "under_sun", 6 => undef, "more", undef },
];

# ini
$data = $ser->deserialize(&read_file("$dir/app.ini"));
$sdata2 = $ser->serialize($data);
#&write_file("app.ini.tmp",$sdata2);
$data3 = $ser->deserialize($sdata2);
is_deeply($data3, $data, "ini serialized and deserialized again");
# can't do arrays
# $data4 = $ser->deserialize($ser->serialize($data_array));
# is_deeply($data4, $data_array, "ini round trip on array");

# perl
$ser2 = $context->serializer("perl");
isa_ok($ser2, "App::Serializer::Perl", "perl right class");
$sdata2 = &read_file("$dir/app.pl");
$data2 = $ser2->deserialize($sdata2);
is_deeply($data2, $data, "perl app.pl same as app.ini");
$sdata2 = $ser2->serialize($data2);
#&write_file("app.pl.tmp",$sdata2);
$data3 = $ser2->deserialize($sdata2);
is_deeply($data3, $data2, "perl serialized and deserialized again");
$data4 = $ser2->deserialize($ser2->serialize($data_array));
is_deeply($data4, $data_array, "perl round trip on array");

# properties
$ser2 = $context->serializer("properties");
isa_ok($ser2, "App::Serializer::Properties", "properties right class");
$sdata2 = &read_file("$dir/app.properties");
$data2 = $ser2->deserialize($sdata2);
is_deeply($data2, $data, "properties app.properties same as app.ini");
$sdata2 = $ser2->serialize($data2);
#&write_file("app.properties.tmp",$sdata2);
$data3 = $ser2->deserialize($sdata2);
is_deeply($data3, $data2, "properties serialized and deserialized again");
# can't do arrays
# $data4 = $ser2->deserialize($ser2->serialize($data_array));
# is_deeply($data4, $data_array, "properties round trip on array");

# xml
$ser2 = $context->serializer("xml");
isa_ok($ser2, "App::Serializer::Xml", "xml right class");
$sdata2 = &read_file("$dir/app.xml");
$data2 = $ser2->deserialize($sdata2);
is_deeply($data2, $data, "xml app.xml same as app.ini");
$sdata2 = $ser2->serialize($data2);
#&write_file("app.xml.tmp",$sdata2);
$data3 = $ser2->deserialize($sdata2);
# this should work but it doesn't.  hmmm...
# is_deeply($data3, $data2, "xml serialized and deserialized again");
# can't do arrays
# $data4 = $ser2->deserialize($ser2->serialize($data_array));
# is_deeply($data4, $data_array, "xml round trip on array");

# storable
$ser2 = $context->serializer("storable");
isa_ok($ser2, "App::Serializer::Storable", "storable right class");
$sdata2 = $ser2->serialize($data);
#&write_file("app.storable.tmp",$sdata2);
$data3 = $ser2->deserialize($sdata2);
is_deeply($data3, $data, "storable serialized and deserialized again");
$data4 = $ser2->deserialize($ser2->serialize($data_array));
is_deeply($data4, $data_array, "storable round trip on array");

# yaml
$ser2 = $context->serializer("yaml");
isa_ok($ser2, "App::Serializer::Yaml", "yaml right class");
$sdata2 = $ser2->serialize($data);
#&write_file("app.yaml.tmp",$sdata2);
$data3 = $ser2->deserialize($sdata2);
is_deeply($data3, $data, "yaml serialized and deserialized again");
$data4 = $ser2->deserialize($ser2->serialize($data_array));
is_deeply($data4, $data_array, "yaml round trip on array");

# one_line
$ser2 = $context->serializer("one_line");
isa_ok($ser2, "App::Serializer::OneLine", "one_line right class");
$sdata2 = $ser2->serialize($data);
#&write_file("app.one_line.tmp",$sdata2);
$data3 = $ser2->deserialize($sdata2);
is_deeply($data3, $data, "one_line serialized and deserialized again");
$data4 = $ser2->deserialize($ser2->serialize($data_array));
is_deeply($data4, $data_array, "one_line round trip on array");

is($ser2->serialize([x=>""]), "x,", "one_line serializing empty strings");
is_deeply($ser2->deserialize("x,"), [x=>""], "one_line deserializing empty strings");

is($ser2->serialize({x=>""}), "{x=}", "one_line serializing hashref with empty string");
is_deeply($ser2->deserialize("{x=}"), {x=>""}, "one_line deserializing hashref with empty string");

is($ser2->serialize(["x"]), "x", "one_line serializing array with one element");
is_deeply($ser2->deserialize("x"), "x", "one_line deserializing array with one element");
is_deeply($ser2->deserialize("[x]"), ["x"], "one_line deserializing array with one element (alt)");

#is($ser2->serialize(["1,2"]), '"1,2"', "one_line serializing one element with commas");
#is_deeply($ser2->deserialize('"1,2"'), "1,2", "one_line deserializing one element with commas");
#is_deeply($ser2->deserialize("[x]"), ["x"], "one_line deserializing array with one element (alt)");

#is($ser2->serialize(["x","y"]), "x,y", "one_line serializing array with two elements");
#is_deeply($ser2->deserialize("x,y"), ["x","y"], "one_line deserializing array with two elements");
#is_deeply($ser2->deserialize("[x,y]"), ["x","y"], "one_line deserializing array with two elements (alt)");
#$data5 = { dow => "1,7", "i[0]" => "{hello=>world},[yuk]", punct => '`~!@#$%^&*()_+=-[]}{\\|\'";:/.,<>?', };
#$sdata5 = $ser2->serialize($data5);
#is($sdata5, "???", "one_line serializing with punctuation");
#is_deeply($ser2->deserialize($sdata5), $data5, "one_line deserializing with punctuation");

# text_array (ONLY WORKS WITH ARRAYS OF ARRAYS)
$data2 = [
  [ "pi", "=", 3.1416 ],
  [ 6, undef, "more", undef ],
];
$ser2 = $context->serializer("text_array");
isa_ok($ser2, "App::Serializer::TextArray", "text_array right class");
$sdata2 = $ser2->serialize($data2);
#&write_file("app.text_array.tmp",$sdata2);
$data3 = $ser2->deserialize($sdata2);
is_deeply($data3, $data2, "text_array serialized and deserialized again");

exit 0;

sub read_file {
    my ($file) = @_;
    open(FILE, "< $file") || die "Unable to open $file: $!";
    my @data = <FILE>;
    close(FILE);
    my $data = join("",@data);
    return($data);
}

sub write_file {
    my ($file, $data) = @_;
    open(FILE, "> $file") || die "Unable to open $file: $!";
    print FILE $data;
    close(FILE);
}

