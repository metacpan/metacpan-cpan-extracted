use strict;
use warnings;

use Test::More;
use APR::Emulate::PSGI;
use IO::File;

plan('tests' => 21);

# Set up filehandles needed in the PSGI environment.
my $error_string;
my $request_body = 'hello=world';
my $response_body = 'howdy';
open my $fh_in, '<', \do { $request_body };
open my $fh_errors, '>', \$error_string;

# Set up PSGI environment.
my $psgi_env = {
    'REMOTE_ADDR'    => '192.168.1.1',
    'REQUEST_METHOD' => 'POST',
    'CONTENT_TYPE'   => 'application/x-www-form-urlencoded',
    'CONTENT_LENGTH' => length($request_body),
    'HTTP_HOK'       => 'gahaha',
    'psgi.errors'    => $fh_errors,
    'psgi.input'     => $fh_in,
};

# Create instance.
my $r = APR::Emulate::PSGI->new($psgi_env);

isa_ok(
    $r,
    'APR::Emulate::PSGI',
    'Object is instantiated.',
);

# Verify that data is going in as expected (request).

SKIP: {
    skip(
        'Not yet implemented: $r->connection()',
        1,
    ) unless $r->can('connection');
    is(
        $r->connection()->remote_ip(),
        '192.168.1.1',
        'Remote address is available.',
    );
}

is(
    $r->method(),
    'POST',
    'Request method is available.',
);

is(
    $r->headers_in()->header('CONTENT_TYPE'),
    'application/x-www-form-urlencoded',
    'Content-type is available.',
);

is(
    $r->headers_in()->header('CONTENT_LENGTH'),
    length($request_body),
    'Content length is available.',
);

is(
    $r->headers_in()->header('HTTP_HOK'),
    'gahaha',
    'Custom header is available.',
);

my $actual;
is(
    $r->read($actual, length($request_body)),
    length($request_body),
    'POST content is read.',
);

is(
    $actual,
    $request_body,
    'POST content is correct.',
);

# Set headers for the response.

is(
    $r->headers_out()->add('X-Foo' => 'Bar'),
    1,
    'Header added.',
);

is(
    $r->content_type('text/html'),
    'text/html',
    'Content-type is set.',
);

# Verify that data comes out as expected (response).

is(
    $r->psgi_status(),
    '200',
    'Received expected status.',
);

my $headers = +{ @{$r->psgi_headers()} };
is(
    $headers->{'Content-Type'},
    'text/html',
    'Received expected content type.',
);

is(
    $headers->{'X-Foo'},
    'Bar',
    'Received expected custom header.',
);

is(
	$r->no_cache(1),
	0,
	'No cache is set.',
);

$headers = +{ @{$r->psgi_headers()} };
is(
	$headers->{'Pragma'},
	'no-cache',
	'Received Pragma header for cache.',
);

is(
	$headers->{'Cache-control'},
	'no-cache',
	'Received Cache-control header for cache.',
);

is(
	$r->no_cache(0),
	1,
	'No cache is unset.',
);

$headers = +{ @{$r->psgi_headers()} };
is(
	exists($headers->{'Pragma'}),
	'',
	'Received no Pragma header.',
);

is(
	exists($headers->{'Cache-control'}),
	'',
	'Received no Cache-control header.',
);

my $body_fh = IO::File->new_tmpfile();
{
    local *STDOUT = $body_fh;
    #my $length = $r->print($response_body);
    is(
        #$length,
        $r->print($response_body),
        length($response_body),
        'Content is printed.',
    );

}

$body_fh->seek(0, 0);  # Reset filehandle back to the beginning.
is(
    $body_fh->getline(),
    $response_body,
    'Received expected content.',
);

