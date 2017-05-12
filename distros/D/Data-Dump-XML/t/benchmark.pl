#!/usr/bin/perl

use Class::Easy;

use Data::Dumper;

use IO::Easy;

use Test::More qw(no_plan);

use Benchmark;

use_ok 'Data::Dump::XML';
use_ok 'Data::Dump::XML::Parser';

my $file_name = shift || 't/xml.xml';
$file_name = 't/Data-Dump-XML/xml.xml' 
	unless -f $file_name;

$Class::Easy::DEBUG = 'immediately';

my $dumper = Data::Dump::XML->new;
my $parser = Data::Dump::XML::Parser->new;

my $contents = IO::Easy->new ($file_name)->as_file->contents;
my $data;
my $xml;

my $xml_string;

$data = $parser->parse_string ($contents);
$xml = $dumper->dump_xml ($data);

# my $text_bench = {'Data::Dump::XML' => sub {$dumper->dump_xml ($data)}};
my $dumper_bench = {'Data::Dump::XML' => sub {$dumper->dump_xml ($data)}};
my $parser_bench = {'Data::Dump::XML' => sub {$parser->parse_string ($contents)}};


if (try_to_use ('Data::DumpXML')) {
	$dumper_bench->{'Data::DumpXML'} = sub {eval{$xml_string = Data::DumpXML::dump_xml ($data)}};
	# $parser_bench->{'Data::DumpXML'} = sub {eval{Data::DumpXML::parser::parse_string ($xml_string)}};
	# $text_bench->{'Data::DumpXML'} = sub {eval{$xml_string = Data::DumpXML::dump_xml ($data)}; };
}

my $xml_string_dumper;

if (try_to_use ('XML::Dumper')) {
	$dumper_bench->{'XML::Dumper'} = sub {$xml_string_dumper = XML::Dumper::pl2xml ($data)};
	$parser_bench->{'XML::Dumper'} = sub {XML::Dumper::xml2pl ($xml_string_dumper)};
}

my $xml_string_simple;

if (try_to_use ('XML::Simple')) {
	$dumper_bench->{'XML::Simple'} = sub {$xml_string_simple = XML::Simple::XMLout ($data)};
	# $parser_bench->{'XML::Simple'} = sub {XML::Simple::XMLin ($xml_string_simple)};
}

my $json_string_dumper;

if (try_to_use ('JSON')) {
	$dumper_bench->{'JSON'} = sub {$json_string_dumper = JSON::to_json ($data)};
	$parser_bench->{'JSON'} = sub {JSON::from_json ($json_string_dumper)};
}

my $storable;

if (try_to_use ('Storable')) {
	$dumper_bench->{'Storable'} = sub {$storable = Storable::freeze ($data)};
	$parser_bench->{'Storable'} = sub {Storable::thaw ($storable)};
}


Benchmark::cmpthese (1000, $dumper_bench);
Benchmark::cmpthese (1000, $parser_bench);

1;
