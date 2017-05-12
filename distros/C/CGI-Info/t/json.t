#!perl -wT

use strict;
use warnings;
use Test::Most tests => 5;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('CGI::Info');
}

JSON: {
	my $json = '{ "first": "Nigel", "last": "Horne" }';

	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'POST';
	$ENV{'CONTENT_TYPE'} = 'application/json; charset=utf-8';
	$ENV{'CONTENT_LENGTH'} = length($json);

	my $allowed = { 'first' => undef, 'last' => undef };

	open (my $fin, '<', \$json);
	local *STDIN = $fin;

	my $i = new_ok('CGI::Info' => [ logger => MyLogger->new() ]);
	ok(defined($i->params(allow => $allowed)));
	ok($i->first() eq 'Nigel');
}

package MyLogger;

sub new {
	my ($proto, %args) = @_;

	my $class = ref($proto) || $proto;

	return bless { }, $class;
}

sub warn {
	my $self = shift;
	my $message = shift;

	::diag($message);
}

sub trace {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}

sub debug {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}
