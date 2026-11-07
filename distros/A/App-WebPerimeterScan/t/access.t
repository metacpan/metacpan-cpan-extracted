use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

use App::WebPerimeterScan;
use App::WebPerimeterScan::Report;
use App::WebPerimeterScan::Scope;

# Every other test runs with the access checks bypassed, because prove sets
# HARNESS_ACTIVE.  Turn the bypass off here to prove the checks are real.
local $Sub::Private::BYPASS = 0;
local $Sub::Protected::BYPASS = 0;
local $Sub::Private::config{harness_bypass} = 0;
local $Sub::Protected::config{harness_bypass} = 0;

subtest 'private routines cannot be called from outside' => sub {
	my %private = (
		'App::WebPerimeterScan::TLS::_name'               => [ 'x' ],
		'App::WebPerimeterScan::HTTP::_parse_head'        => [ "HTTP/1.1 200 OK" ],
		'App::WebPerimeterScan::Checks::_version_lt'      => [ '1', '2' ],
		'App::WebPerimeterScan::Source::_pattern_re'      => [ '/x' ],
		'App::WebPerimeterScan::Report::_escape'          => [ '<' ],
		'App::WebPerimeterScan::I18N::_render'            => [ 'x', {} ],
		'App::WebPerimeterScan::Ports::_open_port'        => [ 1 ],
		'App::WebPerimeterScan::_random_token'            => [],
	);
	for my $name (sort keys %private) {
		no strict 'refs';
		ok(!eval { &{$name}(@{ $private{$name} }); 1 }, "$name refuses an outside caller");
		like($@, qr/is a private subroutine/, '... with the access message');
	}

	my $scanner = App::WebPerimeterScan->new;
	ok(!eval { $scanner->_record_response('u', 'GET', { status => 200 }); 1 }, 'a private method too');
};

subtest 'protected helpers are for the distribution and its subclasses' => sub {
	ok(!eval { App::WebPerimeterScan::Scope->_throw('scope.empty', { file => 'f' }); 1 },
		'_throw refuses a caller outside the class tree');
	like($@, qr/is a protected method/, '... with the access message');

	{
		package My::Scope;
		our @ISA = ('App::WebPerimeterScan::Scope');
		sub explode { return shift->_throw('scope.empty', { file => 'x.txt' }) }
	}
	ok(!eval { My::Scope->explode; 1 }, 'a subclass may call _throw');
	like($@, qr/\AScope file 'x\.txt' contains no usable hosts/, '... and gets the catalogued message');
};

subtest 'public behaviour is unaffected by enforcement' => sub {
	# These all call private helpers internally.
	my $findings = App::WebPerimeterScan::Findings->new;
	ok($findings->report('csp-missing', severity => 'medium', vars => { url => 'u' }), 'Findings::report');
	ok(App::WebPerimeterScan::Checks::check_page($findings, url => 'https://x/', res => { headers => {}, body => '<title>t</title>' }),
		'Checks::check_page');
	like(App::WebPerimeterScan::Report::as_html($findings), qr/<!DOCTYPE html>/, 'Report::as_html');
	is(App::WebPerimeterScan::HTTP->new->fetch('ftp://x/')->{error}, "unsupported scheme 'ftp'", 'HTTP::fetch');
	ok(App::WebPerimeterScan::Scope->new->covers('x') == 0, 'Scope::covers');
};

done_testing();
