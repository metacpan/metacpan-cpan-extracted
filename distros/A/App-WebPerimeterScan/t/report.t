use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use JSON::PP qw(decode_json);
use Test::More;

use App::WebPerimeterScan;
use App::WebPerimeterScan::Findings;
use App::WebPerimeterScan::Report;

# White-box: _record_response is private, and this test calls it directly.
$Sub::Private::BYPASS = 1;

my $findings = App::WebPerimeterScan::Findings->new;

$findings->add(
	id => 'low-thing', severity => 'low',
	host => 'example.com', url => 'https://example.com/a',
	title => 'A low thing',
);
$findings->add(
	id => 'critical-thing', severity => 'critical',
	host => 'example.com', url => 'https://example.com/b',
	title => 'A <script>alert(1)</script> thing',
	detail => 'Detail & more',
	evidence => '<img src=x>',
	fix => 'Fix it',
);
$findings->add(
	id => 'medium-thing', severity => 'medium',
	host => 'example.com', url => 'https://example.com/c',
	title => 'A medium thing',
);

is($findings->count, 3, 'three findings recorded');

is($findings->add(id => 'medium-thing', severity => 'medium',
	host => 'example.com', url => 'https://example.com/c',
	title => 'A medium thing'), 0, 'duplicate suppressed');
is($findings->count, 3, 'duplicate did not increase the count');

my $sorted = $findings->sorted;
is($sorted->[0]{severity}, 'critical', 'worst finding sorts first');
is($sorted->[-1]{severity}, 'low', 'least severe sorts last');

my $counts = $findings->counts;
is($counts->{critical}, 1, 'critical counted');
is($counts->{info}, 0, 'unused severity counted as zero');

is(scalar @{ $findings->at_or_above('high') }, 1, 'one finding at or above high');
is(scalar @{ $findings->at_or_above('info') }, 3, 'all findings at or above info');
is_deeply($findings->at_or_above('bogus'), [], 'an unknown threshold matches nothing');

my %meta = (
	version      => '0.01',
	generated    => '2026-11-05T00:00:00Z',
	scope_source => 'scope.txt',
	requests     => 12,
	hosts        => [ { host => 'example.com', urls => ['https://example.com/'],
		open_ports => [ { port => 443 } ],
		response   => {
			url     => 'https://example.com/',
			method  => 'GET',
			status  => 200,
			headers => { 'content-security-policy' => [ "default-src 'self'" ] },
			raw     => 'HTTP/1.1 200 OK',
		},
		responses  => [ { url => 'http://example.com/', method => 'GET', status => 200,
			headers => { location => ['https://example.com/'] },
			raw     => 'HTTP/1.1 200 OK' } ] } ],
);

my $text = App::WebPerimeterScan::Report::as_text($findings, %meta);
like($text, qr/example\.com/, 'text report names the host');
like($text, qr/Summary: 1 critical/, 'text report has a summary');
like($text, qr/\[critical-thing\]/, 'text report lists rule ids');

my $json = App::WebPerimeterScan::Report::as_json($findings, %meta);
my $data = eval { decode_json($json) };
ok($data, 'JSON report decodes') or diag($@);
is(scalar @{ $data->{findings} }, 3, 'JSON has all findings');
is($data->{summary}{critical}, 1, 'JSON summary is populated');
is($data->{findings}[0]{id}, 'critical-thing', 'JSON is sorted worst first');
is($data->{hosts}[0]{response}{headers}{'content-security-policy'}[0],
	"default-src 'self'", 'JSON keeps the parsed header block');
like($data->{hosts}[0]{response}{raw}, qr{HTTP/1\.1 200 OK},
	'JSON keeps the raw header block');
is($data->{hosts}[0]{responses}[0]{headers}{location}[0],
	'https://example.com/', 'JSON keeps the probe responses');

my $html = App::WebPerimeterScan::Report::as_html($findings, %meta);
like($html, qr/<!DOCTYPE html>/, 'HTML report is a document');
unlike($html, qr/<script>alert\(1\)<\/script>/, 'HTML report escapes finding text');
like($html, qr/&lt;script&gt;alert\(1\)&lt;\/script&gt;/, 'escaped text is present');
like($html, qr/example\.com/, 'HTML report names the host');

my $no_hosts = App::WebPerimeterScan::Report::as_text(
	App::WebPerimeterScan::Findings->new, %meta, hosts => [],
);
like($no_hosts, qr/No findings/, 'clean report says so');

# The record itself: duplicates preserved, failed requests not recorded.
my $scanner = App::WebPerimeterScan->new;
my $record = $scanner->_record_response(
	'https://example.org/', 'GET',
	{
		status       => 200,
		http_version => 'HTTP/1.1',
		reason       => 'OK',
		headers      => {
			'set-cookie'   => [ 'a=1', 'b=2' ],
			'content-type' => ['text/html'],
		},
		raw_headers => 'HTTP/1.1 200 OK',
	},
);
is($record->{status}, 200, 'response record keeps the status');
is_deeply($record->{headers}{'set-cookie'}, [ 'a=1', 'b=2' ],
	'repeated headers preserved, not collapsed');
is($record->{raw}, 'HTTP/1.1 200 OK', 'raw header block is kept verbatim');
is($scanner->_record_response('https://example.org/', 'GET', { error => 'connect failed' }),
	undef, 'a failed request is not recorded');

# Every value in the HTML is escaped, the metadata included.
my $hostile = App::WebPerimeterScan::Report::as_html($findings, %meta,
	generated => '<script>x</script>', version => '"><b>');
unlike($hostile, qr/<script>x<\/script>/, 'the generated time is escaped in the title and header');
unlike($hostile, qr/"><b>/, 'the version is escaped');

my $plain = App::WebPerimeterScan::Report::as_text($findings, %meta, color => 0);
unlike($plain, qr/\e\[/, 'color => 0 gives plain text');
my $colored = App::WebPerimeterScan::Report::as_text($findings, %meta, color => 1);
like($colored, qr/\e\[/, 'color => 1 gives ANSI colour');

like(App::WebPerimeterScan::Report::as_text($findings, %meta, hosts => [ {
	host => 'tls.example', urls => [], open_ports => [],
	tls => { ok => 1, protocol => 'TLSv1_3', cipher => 'X', not_after => 'Dec 25 2026', days_left => 1 },
} ]), qr/expires Dec 25 2026 \(1 day\)/, 'TLS expiry is singular for one day');

ok(!eval { App::WebPerimeterScan::Report::as_json($findings, bogus => 1); 1 }, 'an unknown metadata key is refused');

# Findings: the API added in the refactor.
{
	my $f = App::WebPerimeterScan::Findings->new;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	$f->add(id => 'typo', severity => 'crtical');
	is($f->all->[0]{severity}, 'info', 'an unknown severity is recorded as info');
	like($warnings[0] // '', qr/Unknown severity 'crtical'/, '... with a warning');

	is($f->report('csp-missing', severity => 'medium', host => 'h', vars => { url => 'https://h/' }), 1,
		'report() records a catalogued rule');
	my ($csp) = grep { $_->{id} eq 'csp-missing' } @{ $f->all };
	is($csp->{title}, 'Content-Security-Policy is missing', 'the title comes from the catalogue');
	is($csp->{evidence}, 'No Content-Security-Policy header on https://h/', 'the evidence template is filled in');

	$f->report('x', message => 'csp-missing', rule => { severity => 'low', reference => 'R' });
	my ($x) = grep { $_->{id} eq 'x' } @{ $f->all };
	is($x->{severity}, 'low', 'the rule supplies the severity');
	is($x->{reference}, 'R', 'the rule supplies the reference');

	is($f->annotate($csp, file => '/srv/x'), $f, 'annotate() returns the collection');
	is($csp->{file}, '/srv/x', 'annotate() sets the file');
	ok(!eval { $f->annotate({ %{$csp} }, file => 'y'); 1 }, 'a copy of a finding is refused');
	ok(!eval { $f->annotate($csp, title => 'y'); 1 }, 'only file and source can be annotated');

	is(App::WebPerimeterScan::Findings::rank('critical'), 5, 'rank of critical');
	is(App::WebPerimeterScan::Findings::rank('nope'), 0, 'rank of an unknown severity');
	is(App::WebPerimeterScan::Findings::rank(undef), 0, 'rank of undef');

	push @{ $f->all }, 'junk';
	ok(!(grep { !ref } @{ $f->all }), 'all() returns a copy of the list');
	ok(!eval { App::WebPerimeterScan::Findings->new(bogus => 1); 1 }, 'new() takes no arguments');
}

done_testing();
