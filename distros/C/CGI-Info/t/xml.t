#!perl -wT

use strict;
use warnings;
use Test::Most tests => 10;
use Test::NoWarnings;

eval { use autodie qw(:all) };	# Test for open/close failures

BEGIN {
	use_ok('CGI::Info');
}

XML: {
	my $xml = '<foo>bar</foo>';

	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'POST';
	$ENV{'CONTENT_TYPE'} = 'text/xml; charset=utf-8';
	$ENV{'CONTENT_LENGTH'} = length($xml);

	open (my $fin, '<', \$xml);
	local *STDIN = $fin;

	my $i = new_ok('CGI::Info');
	my %p = %{$i->params({ expect => ['XML'] })};
	ok(exists($p{XML}));
	is($p{XML}, $xml);	# Fails on Perl 5.6.2
	is($i->as_string(), "XML=$xml");

	$i = $i->new();	# A second instantiation should get the same data
	isa_ok($i, 'CGI::Info');
	my $p = $i->params();
	ok(exists($p->{XML}));
	is($p{XML}, $xml);	# Fails on Perl 5.6.2
	is($i->as_string(), "XML=$xml");
}
