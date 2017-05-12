use strict;
use warnings;
use Test::More;

eval "use 5.008";
plan skip_all => "$@" if $@;
plan tests => 6;
#plan 'no_plan';

use CGI::PSGI ();

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

my $q = CGI::PSGI->new($env);

# These first tree tests are ported from CGI.pm's 'function.t'
{
    my $test = 'psgi_redirect($url)';
    my ($status,$headers) = $q->psgi_redirect('http://somewhere.else');
    is($status, 302, "$test - default status");
    is_deeply $headers, [ 'Location' => 'http://somewhere.else' ], "$test - headers array";  
}
{
    my $test = 'psgi_redirect() with content type';
    my ($status,$headers) = $q->psgi_redirect( -Location=>'http://somewhere.else',-Type=>'text/html');
    is($status, 302, "$test - status");
    is_deeply $headers, [ 
        'Location' => 'http://somewhere.else',
        'Content-Type' => 'text/html; charset=ISO-8859-1',
        ], "$test - headers array";  
}
{
    my $test = "psgi_redirect() with path and query string"; 
    my ($status,$headers) = $q->psgi_redirect( -Location=>'http://somewhere.else/bin/foo&bar',-Type=>'text/html');
    is($status, 302, "$test - status");
    is_deeply $headers, [ 
        'Location' => 'http://somewhere.else/bin/foo&bar',
        'Content-Type' => 'text/html; charset=ISO-8859-1',
        ], "$test - headers array";  
}


