use Test::More;
use CGI::PSGI;
use CGI;

my $env;
$env->{REQUEST_METHOD}  = 'GET';
$env->{HTTP_HOST}       = 'virtual.example.com:81';
$env->{SERVER_NAME}     = 'server.example.com';
$env->{SCRIPT_NAME}     = '/cgi-bin/foo.cgi';
$env->{PATH_INFO}       = '';
$env->{QUERY_STRING}    = '';
$env->{SERVER_PROTOCOL} = 'HTTP/1.0';
$env->{SERVER_PORT}     = 8080;
$env->{REQUEST_URI}     = "$env->{SCRIPT_NAME}$env->{PATH_INFO}?$env->{QUERY_STRING}";
$env->{HTTP_USER_AGENT} = 'Mozilla/5.1';
$env->{HTTP_REFERER}    = 'http://localhost/foo';

{
    my $q = CGI::PSGI->new($env);
    is $q->server_name, 'server.example.com';
    is $q->virtual_host, 'virtual.example.com';
    is $q->virtual_port, 81;

    is $q->user_agent, 'Mozilla/5.1';
    is $q->referer, 'http://localhost/foo';
}

done_testing;
