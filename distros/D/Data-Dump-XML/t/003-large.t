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

$data = $parser->parse_string ($contents);
$xml = $dumper->dump_xml ($data);

for (0 .. 10) {
	my $t = timer ("parsing file");
	$data = $parser->parse_string ($contents);
	$t->lap ('dumping data');
	$xml = $dumper->dump_xml ($data);
	$t->end;
}

if ($ENV{DEBUG}) {
	my $file_name2 = $file_name;
	$file_name2 =~ s/xml\.xml/xml2\.xml/;

	IO::Easy->new ($file_name2)->as_file->store ($xml->toString(1));
}

1;
