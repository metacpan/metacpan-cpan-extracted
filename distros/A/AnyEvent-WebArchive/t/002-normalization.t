#!/usr/bin/env perl

use Test::More tests => 3;
use AnyEvent::WebArchive;

my $worker = {domain => 'cpan.org'};

bless $worker, AnyEvent::WebArchive;

is(
	$worker->_normalize_url('web.archive.org/some/url/cpan.org/test/'),
	'/test/index.html'
);

is(
	$worker->_normalize_url('web.archive.org/some/url/cpan.org/test/?page=2'),
	'/test/_page=2.html'
);
is(
	$worker->_normalize('<a href="http://web.archive.org/some/url/cpan.org/test/?page=8&C=1">test link</a>'),
	'<a href="/test/_page=8&C=1.html">test link</a>'
);