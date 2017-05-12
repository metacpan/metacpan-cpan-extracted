use strict;
use warnings;
use Test::More;
plan(tests => 7);
use lib qw(../lib lib);
use CGI::Mungo;

#setup our cgi environment
$ENV{'SCRIPT_NAME'} = "test.cgi";
$ENV{'SERVER_NAME'} = "www.test.com";
$ENV{'HTTP_HOST'} = "www.test.com";
$ENV{'HTTP_REFERER'} = "http://" . $ENV{'HTTP_HOST'};
$ENV{'SERVER_PORT'} = 8080;
$ENV{'REQUEST_URI'} = "/test.cgi";
$ENV{'REQUEST_METHOD'} = 'GET';

my $options = {
	'responsePlugin' => 'CGI::Mungo::Response::Raw',
	'debug' => 1
};

my $m = CGI::Mungo->new($options);
#1
isa_ok($m, "CGI::Mungo");

#2
my $response = $m->getResponse();
isa_ok($response, "CGI::Mungo::Response::Raw");

#3
my $session = $m->getSession();
isa_ok($session, "CGI::Mungo::Session");

#4
my $request = $m->getRequest();
isa_ok($request, "CGI::Mungo::Request");

#5 need to test getthisurl()
is($m->getThisUrl(), "http://www.test.com:8080/test.cgi", "CGI::Mungo::Utils::getThisUrl()");

#6
is($m->getFullUrl(), "http://www.test.com:8080/test.cgi", "CGI::Mungo::getFullUrl()");

#7
is($m->getOption('debug'), 1, "CGI::Mungo::getOption()");
