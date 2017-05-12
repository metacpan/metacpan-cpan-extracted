#!/usr/bin/perl

use Class::Easy;

use Data::Dumper;

use Test::More qw(no_plan);

use_ok 'Data::Dump::XML';
use_ok 'Data::Dump::XML::Parser';

$Class::Easy::DEBUG = 'immediately';

my $dumper = Data::Dump::XML->new;

my $data = bless {__structure => {a => 1, b => [3, 4, 5], c => {e => 15}}}, 'AAA';

$::TO_XML_CALLED = 0;

my $t = timer ("dumping structure");

my $xml = $dumper->dump_xml ($data);

$t->end;

ok $::TO_XML_CALLED == 1;

ok $xml->toString =~ m|<a>1</a><b><item>3</item><item>4</item><item>5</item>|;
ok $xml->toString =~ m|<c[^>]*><e>15</e></c>|;

my $data = bless {__structure => {a => 1, b => [3, 4, 5], c => bless ({__structure => {e => 15}}, 'AAA')}}, 'AAA';

ok $xml->toString =~ m|<a>1</a><b><item>3</item><item>4</item><item>5</item>|;
ok $xml->toString =~ m|<c[^>]*><e>15</e></c>|;


1;

package AAA;

sub TO_XML {
	$::TO_XML_CALLED = 1;
	return shift->{__structure};
}

1;
