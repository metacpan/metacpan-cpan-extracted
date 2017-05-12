#!/usr/bin/perl

use Class::Easy;

use Data::Dumper;

use Test::More qw(no_plan);

use_ok 'Data::Dump::XML';
use_ok 'Data::Dump::XML::Parser';

$Class::Easy::DEBUG = 'immediately';

my $dumper = Data::Dump::XML->new;

my $data = {a => 1, b => [3, 4, 5], c => {e => 15}};

my $t = timer ("dumping structure");

my $xml = $dumper->dump_xml ($data);

$t->end;

#diag Dumper $data;

#diag $xml->toString (1);

ok $xml->toString =~ m|<a>1</a><b><item>3</item><item>4</item><item>5</item>|;
ok $xml->toString =~ m|<c><e>15</e></c>|;

my $parser = Data::Dump::XML::Parser->new;

my $parsed = $parser->parse_string ($xml->toString);

# TODO: checks

# diag Dumper $parsed;

$data = {a => 1, b => [{'@ttt' => 25, '#text' => ''}, 3, 4, 5], c => {'@d' => 30,  e => 15}};

$t = timer ("dumping structure");

$xml = $dumper->dump_xml ($data);

# diag $xml->toString (1);

$t->end;

ok $xml->toString =~ m|<a>1</a><b><item ttt="25"/><item>3</item><item>4</item><item>5</item>|;
ok $xml->toString =~ m|<c d="30"><e>15</e></c>|;

$parsed = $parser->parse_string ($xml->toString);

ok $parsed->{c}->{'@d'} eq 30;

$data = bless {a => 1, b => [bless ({'@ttt' => 25, '#text' => ''}, 'Foo'), 3, 4, 5]}, 'Bar';

$t = timer ("dumping structure");

$xml = $dumper->dump_xml ($data);

diag $xml->toString (1);

$t->end;

ok $xml->toString =~ m|<data _class="Bar"|;

ok $xml->toString =~ m|<a>1</a><b><item _class="Foo" ttt="25"/><item>3</item><item>4</item><item>5</item>|;

$parsed = $parser->parse_string ($xml->toString);

warn Dumper $parsed;

ok $parsed->{b}->[0]->{'@ttt'} eq 25;

ok ref $parsed eq 'Bar';

ok ref $parsed->{b}->[0] eq 'Foo';

$dumper = Data::Dump::XML->new (root_name => 'rss');

my $item = {
	pubDate => 'Mon, 04 May 2009 16:21:57 MSD',
	link => 'http://developers.slashdot.org/story/09/06/03/1817214/Money-For-Nothing-and-the-Codecs-For-Free',
	guid => {'@isPermaLink' => 'true', '#text' => 'http://developers.slashdot.org/story/09/06/03/1817214/Money-For-Nothing-and-the-Codecs-For-Free'},
	title => 'Money For Nothing and the Codecs For Free',
	description => 'Davis Freeberg writes "In an in depth discussion on the codec industry…"',
};

my $rss = {
	'@version' => '2.0',
	channel => {
		description => 'slashdot',
		link => 'http://slashdot.com/',
		title => 'slashdot.com',
		image => {
			url => 'http://c.fsdn.com/sd/topics/topicmediaall.gif',
		},
		pubDate => $item->{pubDate},
		'<item' => [$item],
	},
};

$xml = $dumper->dump_xml ($rss);

my $xml_string = $xml->toString;

ok $xml_string =~ /<rss version="2\.0">/s;
ok $xml_string =~ /<guid isPermaLink="true">/s;
ok $xml_string =~ /<guid isPermaLink="true">/s;

my $s = "<iPad_MN>&gt; \x{437}</iPad_MN>";

my $xml_parser = Data::Dump::XML::Parser->new;

my $str = $xml_parser->parse_string($s);

ok length($str) == 3;

ok substr ($str, -1) eq "\x{437}";



1;
