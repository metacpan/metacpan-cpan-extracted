# copied and rearranged from CGI::PSGI's psgi_headers.t

# Test that header generation is spec compliant.
# References:
#   http://www.w3.org/Protocols/rfc2616/rfc2616.html
#   http://www.w3.org/Protocols/rfc822/3_Lexical.html

use strict;
use warnings;

use Test::More 'no_plan';
use CGI::PSGI;
use CGI::Header::PSGI;

# Set up a CGI environment
my $env;
$env->{REQUEST_METHOD}  = 'GET';
$env->{QUERY_STRING}    = 'game=chess&game=checkers&weather=dull';
$env->{PATH_INFO}       = '/somewhere/else';
$env->{PATH_TRANSLATED} = '/usr/local/somewhere/else';
$env->{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$env->{SERVER_PROTOCOL} = 'HTTP/1.0';
$env->{SERVER_PORT}     = 8080;
$env->{SERVER_NAME}     = 'the.good.ship.lollypop.com';
$env->{REQUEST_URI}     = "$env->{SCRIPT_NAME}$env->{PATH_INFO}?$env->{QUERY_STRING}";
$env->{HTTP_LOVE}       = 'true';

my $header = CGI::Header::PSGI->new( query => CGI::PSGI->new($env) );

my ($status, $headers) = $header->type('text/html')->finalize;
is $status, 200;
is_deeply $headers, [ 'Content-Type' => 'text/html; charset=ISO-8859-1' ],
    'known header, basic case: type => "text/html"';

$header->clear;
eval { $header->type("text/html".$CGI::CRLF."evil: stuff")->finalize };
like($@,qr/contains a newline/,'invalid header blows up');

$header->clear;
($status, $headers) = $header->type("text/html".$CGI::CRLF." evil: stuff ")->finalize;
like $headers->[1],
    qr#text/html evil: stuff#, 'known header, with leading and trailing whitespace on the continuation line';

$header->clear->set( foobar => "text/html".$CGI::CRLF."evil: stuff" );
eval {  $header->finalize };
like($@,qr/contains a newline/,'unknown header with CRLF embedded blows up');

$header->clear->set( foobar => "\nContent-type: evil/header" );
eval { $header->finalize };
like($@,qr/contains a newline/,'header with leading newline blows up');
