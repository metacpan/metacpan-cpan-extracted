# Methods that read the CGI environment use the PSGI env, not %ENV

use strict;
use warnings;

use Test::More;
use CGI::PSGI;

local $ENV{QUERY_STRING} = 'from=process';
local $ENV{HTTP_REFERER} = 'http://process.example/';

my $env = {
    REQUEST_METHOD  => 'GET',
    QUERY_STRING    => 'from=request',
    HTTP_REFERER    => 'http://request.example/',
    SCRIPT_NAME     => '/app',
    SERVER_PROTOCOL => 'HTTP/1.0',
    SERVER_PORT     => 80,
    SERVER_NAME     => 'example.com',
    'psgi.input'    => \*STDIN,
};

my $q = CGI::PSGI->new($env);

is $q->referer, 'http://request.example/', 'referer from the PSGI env';

SKIP: {
    skip "CGI.pm $CGI::VERSION has no env_query_string", 1
        unless CGI->can('env_query_string');
    is $q->env_query_string, 'from=request', 'env_query_string from the PSGI env';
}

# The process' own @ARGV never becomes the request params
{
    local @ARGV = ('from=argv');
    my $q = CGI::PSGI->new({ %$env, REQUEST_METHOD => 'OPTIONS', QUERY_STRING => '' });
    ok !defined $q->param('from'), 'OPTIONS request does not read @ARGV';

    my %noreq = %$env;
    delete @noreq{qw(REQUEST_METHOD QUERY_STRING)};
    $q = CGI::PSGI->new(\%noreq);
    ok !defined $q->param('from'), 'env without REQUEST_METHOD does not read @ARGV';
    is_deeply \@ARGV, ['from=argv'], '@ARGV left alone';
}

done_testing;
