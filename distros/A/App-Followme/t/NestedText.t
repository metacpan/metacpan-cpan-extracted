#!/usr/bin/env perl
use strict;

use Test::More tests => 38;

use Cwd;
use IO::File;
use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

eval "use App::Followme::FIO";
eval "use App::Followme::NestedText";

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

chdir $test_dir or die $!;
$test_dir = cwd();

#----------------------------------------------------------------------
# Test trim_string

do {
	my $str;
	$str = App::Followme::NestedText::trim_string($str);
	is($str, '', "trim undefined string"); # test 1
	
	$str = " A very fine string with whitespace  ";
	$str = App::Followme::NestedText::trim_string($str);
	is($str, "A very fine string with whitespace", 
	    "trim string with blanks"); # test 2	
};

#----------------------------------------------------------------------
# Test parsing and formatting simple hash in almost yaml 

do {
	my $text = <<EOQ;
name1: value1
name2: value2
name3: value3
EOQ

	my %value = (name1 => 'value1', name2 => 'value2', name3 => 'value3');
	my %config = nt_parse_almost_yaml_string($text);
	is_deeply(\%config, \%value, "parse simple config as yaml"); # test 3

	my ($type, $formatted_text) = App::Followme::NestedText::format_almost_yaml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format simple config as yaml"); # test 4
};

#----------------------------------------------------------------------
# Test parsing and formatting qualified names in almost yaml 

do {
	my $text = <<EOQ;
App::Followme::NestedText::name1: value1
Followme::NestedText::name2: value2
NestedText::name3: value3
EOQ

	my %value = ('App::Followme::NestedText::name1' => 'value1', 
				 'Followme::NestedText::name2' => 'value2', 
				 'NestedText::name3' => 'value3');

	my %config = nt_parse_almost_yaml_string($text);
	is_deeply(\%config, \%value, "parse simple config as yaml"); # test 5

	my ($type, $formatted_text) = App::Followme::NestedText::format_almost_yaml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format simple config as yaml"); # test 6
};

#----------------------------------------------------------------------
# Test parsing and formatting simple array in almost yaml

do {
	my $text = <<EOQ;
name1: value1
name2:
    - subvalue1
    - subvalue2
    - subvalue3
EOQ

	my %value = (name1 => 'value1',
				 name2 => ["subvalue1", "subvalue2", "subvalue3"],
				);
	my %config = nt_parse_almost_yaml_string($text);
	is_deeply(\%config, \%value, "parse simple array as yaml"); # test 7

	my ($type, $formatted_text) = App::Followme::NestedText::format_almost_yaml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format simple array as yaml"); # test 8
};

#----------------------------------------------------------------------
# Test parsing and formatting simple hash in almost yaml

do {
	my $text = <<EOQ;
name1: value1
name2:
    subname1: subvalue1
    subname2: subvalue2
    subname3: subvalue3
EOQ

	my %value = (name1 => 'value1',
				 name2 => {subname1 => "subvalue1", 
						   subname2 => "subvalue2", 
						   subname3 => "subvalue3"},
				);
	my %config = nt_parse_almost_yaml_string($text);
	is_deeply(\%config, \%value, "parse simple hash as yaml"); # test 9

	my ($type, $formatted_text) = App::Followme::NestedText::format_almost_yaml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format simple hash as yaml"); # test 10
};

#----------------------------------------------------------------------
# Test parsing and formatting long string in almost yaml

do {
	my $text = <<EOQ;
name1: value1
name2:
    > A longer value
    > split across lines
    > however many you may need
    > for the purpose you have
name3: value3
EOQ

	my %value = (name1 => 'value1', 
				 name2 => 'A longer value split across lines however many you may need for the purpose you have', 
				 name3 => 'value3');
	my %config = nt_parse_almost_yaml_string($text);
	is_deeply(\%config, \%value, "parse long string as yaml"); # test 11

	my ($type, $formatted_text) = App::Followme::NestedText::format_almost_yaml_value(\%value);
    $formatted_text .= "\n";

	%config = nt_parse_almost_yaml_string($formatted_text);
	is($config{name2}, $value{name2}, "Format long string as yaml"); # test 12
};

#----------------------------------------------------------------------
# Test parsing comments and blank lines in almost yaml

do {
	my $text = <<EOQ;
# This is a test of parsing comments
name1: value1
    
name2: value2

name3: value3

  # That's all folks! 
EOQ

	my %value = (name1 => 'value1', name2 => 'value2', name3 => 'value3');
	my %config = nt_parse_almost_yaml_string($text);
	is_deeply(\%config, \%value, "parse blank lines and comments in yaml"); # test 13
};

#----------------------------------------------------------------------
# Test parsing and formatting a multi-level hash in almost yaml

do {
	my $text = <<EOQ;
name1: value1
name2:
    subname1: subvalue1
    subname2:
        - 10
        - 20
        - 30
    subname3: subvalue3
name3: value3
EOQ

	my %value = (name1 => 'value1',
				 name2 => {subname1 => "subvalue1", 
						   subname2 => [10, 20, 30], 
						   subname3 => "subvalue3"},
				 name3 => 'value3',
				);
				
	my %config = nt_parse_almost_yaml_string($text);
	is_deeply(\%config, \%value, "parse multi-level hash as yaml"); # test 14

	my ($type, $formatted_text) = App::Followme::NestedText::format_almost_yaml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format multi-level hash as yaml"); # test 15
};

#----------------------------------------------------------------------
# Test merging two configurations

do {
	my $text1 = <<EOQ;
name1: value1
name2:
    subname1: subvalue1
    subname2:
        - 10
        - 20
        - 30
    subname3: subvalue3
name3: value3
EOQ

	my %config1 = nt_parse_almost_yaml_string($text1);

 	my $text2 = <<EOQ;
name1: value1
name2:
    subname1: subvalue1
    subname2:
        - 10
        - 30
        - 50
    subname4: subvalue4
name4: value4
EOQ

	my %config2 = nt_parse_almost_yaml_string($text2);
   
	my %value = (name1 => 'value1',
				 name2 => {subname1 => "subvalue1", 
						   subname2 => [10, 20, 30, 50], 
						   subname3 => "subvalue3",
                           subname4 => "subvalue4"},
				 name3 => 'value3',
				 name4 => 'value4',
				);
				
    my $config3 = nt_merge_items(\%config1, \%config2);
    is_deeply($config3, \%value, "Merge items"); # test 16
};

#----------------------------------------------------------------------
# Test parsing and writing file contents in almost yaml

do {
	my $output = <<EOQ;
name1: value1
name2:
    subname1: subvalue1
    subname2:
        - 10
        - 20
        - 30
    subname3: subvalue3
name3: value3
EOQ

	my %value = (name1 => 'value1',
				 name2 => {subname1 => "subvalue1", 
						   subname2 => [10, 20, 30], 
						   subname3 => "subvalue3"},
				 name3 => 'value3',
				);
				
	my $filename = catfile($test_dir, 'test.cfg');
    fio_write_page($filename, $output);
    
	my %config = nt_parse_almost_yaml_file($filename);
	is_deeply(\%config, \%value, "parse file contents as yaml"); # test 17

	nt_write_almost_yaml_file($filename, %config);
	%config = nt_parse_almost_yaml_file($filename);
	is_deeply(\%config, \%value, "write and re-read file contents as yaml"); # test 18
};

#----------------------------------------------------------------------
# Test error cases in almost yaml

do {
	my %config;
	
	my $text = <<EOQ;
    - 1
    - 2
    - 3
EOQ

	eval{%config = nt_parse_almost_yaml_string($text)};
	is($@, "Configuration must be a hash\n", 
	   "config is a yaml array"); # test 19

	$text = <<EOQ;
    name1: value1
    name2:
        subname1: subvalue1
        subname2: subvalue2
  name3: value3
EOQ

	eval{%config = nt_parse_almost_yaml_string($text)};
	my ($err, $msg) = split(/ at /, $@);
	is($err, "Bad indent", "badly indented data in yaml"); # test 20

	$text = <<EOQ;
    name1: value1
    - value2
    > value3
EOQ

	eval{%config = nt_parse_almost_yaml_string($text)};
	($err, $msg) = split(/ at /, $@);
	is($err, "Missing indent", "mixed types in block in yaml"); # test 21

	$text = <<EOQ;
    name1: value1
    name2: value2
	    name3: value3
EOQ

	eval{%config = nt_parse_almost_yaml_string($text)};
	($err, $msg) = split(/ at /, $@);
	is($err, "Duplicate value", 
	   "inconsistent indentation in block in yaml"); # test 22

	$text = <<EOQ;
    name1: value1
    name2: 
	    > value2
	        > value3
EOQ

	eval{%config = nt_parse_almost_yaml_string($text)};
	($err, $msg) = split(/ at /, $@);
	is($err, "Indent under string", 
	   "inconsistent indentation in string in yaml"); # test 23

	$text = <<EOQ;
    name1: value1
    name2  value2

EOQ

	eval{%config = nt_parse_almost_yaml_string($text)};
	($err, $msg) = split(/ at /, $@);
	is($err, "Bad tag", "missing tag in yaml"); # test 24
};

#----------------------------------------------------------------------
# Test parsing and formatting simple hash in almost xml 

do {
	my $text = <<EOQ;
<name1>value1</name1>
<name2>value2</name2>
<name3>value3</name3>
EOQ

	my %value = (name1 => 'value1', name2 => 'value2', name3 => 'value3');
	my %rss = nt_parse_almost_xml_string($text);
	is_deeply(\%rss, \%value, "parse simple hash as xml"); # test 25

	my $formatted_text = App::Followme::NestedText::format_almost_xml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format simple rss"); # test 26
};

#----------------------------------------------------------------------
# Test parsing and formatting simple array in almost xml

do {
	my $text = <<EOQ;
<name1>value1</name1>
<name2>subvalue1</name2>
<name2>subvalue2</name2>
<name2>subvalue3</name2>
EOQ

	my %value = (name1 => 'value1',
				 name2 => ["subvalue1", "subvalue2", "subvalue3"],
				);
	my %rss = nt_parse_almost_xml_string($text);
	is_deeply(\%rss, \%value, "parse simple array as xml"); # test 27

	my $formatted_text = App::Followme::NestedText::format_almost_xml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format simple array as xml"); # test 28
};

#----------------------------------------------------------------------
# Test parsing and formatting simple hash in almost xml

do {
	my $text = <<EOQ;
<name1>value1</name1>
<name2>
    <subname1>subvalue1</subname1>
    <subname2>subvalue2</subname2>
    <subname3>subvalue3</subname3>
</name2>
EOQ

	my %value = (name1 => 'value1',
				 name2 => {subname1 => "subvalue1", 
						   subname2 => "subvalue2", 
						   subname3 => "subvalue3"},
				);
	my %rss = nt_parse_almost_xml_string($text);
	is_deeply(\%rss, \%value, "parse simple hash as xml"); # test 29

	my $formatted_text = App::Followme::NestedText::format_almost_xml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format simple hash as xml"); # test 30
};

#----------------------------------------------------------------------
# Test parsing and formatting a multi-level hash in almost xml

do {
	my $text = <<EOQ;
<name1>value1</name1>
<name3>value3</name3>
<name2>
    <subname1>subvalue1</subname1>
    <subname3>subvalue3</subname3>
    <subname2>10</subname2>
    <subname2>20</subname2>
    <subname2>30</subname2>
</name2>
EOQ

	my %value = (name1 => 'value1',
				 name2 => {subname1 => "subvalue1", 
						   subname2 => [10, 20, 30], 
						   subname3 => "subvalue3"},
				 name3 => 'value3',
				);
				
	my %rss = nt_parse_almost_xml_string($text);
	is_deeply(\%rss, \%value, "parse multi-level hash as xml"); # test 31

	my $formatted_text = App::Followme::NestedText::format_almost_xml_value(\%value);
    $formatted_text .= "\n";
	is($formatted_text, $text, "format multi-level hash as xml"); # test 32
};

#----------------------------------------------------------------------
# Test parsing and writing file contents in almost xml

do {
	my $output = <<EOQ;
<?xml version="1.0"?>
<name1>value1</name1>
<name2>
    <subname1>subvalue1</subname1>
    <subname2>10</subname2>
    <subname2>20</subname2>
    <subname2>30</subname2>
    <subname3>subvalue3</subname3>
</name2>
<name3>value3</name3>
EOQ

	my %value = (name1 => 'value1',
				 name2 => {subname1 => "subvalue1", 
						   subname2 => [10, 20, 30], 
						   subname3 => "subvalue3"},
				 name3 => 'value3',
				);
				
	my $filename = catfile($test_dir, 'test.rss');
    fio_write_page($filename, $output);
    
	my %rss = nt_parse_almost_xml_file($filename);
	is_deeply(\%rss, \%value, "parse file contents as xml"); # test 33

	nt_write_almost_xml_file($filename, %rss);
	%rss = nt_parse_almost_xml_file($filename);
	is_deeply(\%rss, \%value, "write and re-read file contents as xml"); # test 34
};

#----------------------------------------------------------------------
# Test error cases in almost xml

do {
	my $text = <<EOQ;
<name1>
    <subname1>subvalue1</subname1>
    subvalue2
</name1>
EOQ

    my %rss;
	eval{%rss = nt_parse_almost_xml_string($text)};
	my ($err, $msg) = split(/ at /, $@);
	is($err, "Unexpected text", "data after brackets"); # test 35

	my $text = <<EOQ;
<name1>
    subvalue1
    <subname2>subvalue2</subname2>
</name1>
EOQ

	eval{%rss = nt_parse_almost_xml_string($text)};
	($err, $msg) = split(/ at /, $@);
	is($err, "Unexpected text", "data before brackets"); # test 36
	$text = <<EOQ;
<name1>value1</name2>
EOQ

	eval{%rss = nt_parse_almost_xml_string($text)};
	my ($err, $msg) = split(/ at /, $@);
	is($err, "Mismatched tags", "mismatched tags"); # test 37

	$text = <<EOQ;
<name1>value1</name1></name2>
EOQ

	eval{%rss = nt_parse_almost_xml_string($text)};
	my ($err, $msg) = split(/ at /, $@);
	is($err, "Unexpected closing tag", "extra closing tag"); # test 38
}
