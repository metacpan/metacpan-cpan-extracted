use strict;
use warnings;
use Test::More;
plan(tests => 5);
use lib qw(../lib lib);
use CGI::Mungo;
use CGI::Mungo::Response::Raw;

#setup our cgi environment
$ENV{'SCRIPT_NAME'} = "test.cgi";
$ENV{'SERVER_NAME'} = "www.test.com";
$ENV{'HTTP_HOST'} = "www.test.com";
$ENV{'HTTP_REFERER'} = "http://" . $ENV{'HTTP_HOST'};
$ENV{'REQUEST_METHOD'} = 'GET';

my $options = {
	'responsePlugin' => 'CGI::Mungo::Response::Raw'
};

my $m = CGI::Mungo->new($options);

my $raw = $m->getResponse();

#1
ok($raw->setContent('Hello'), 'SetContent()');

{
	my $out = $raw->_getContent();
	#2
	is($out, 'Hello', '_getContent()');
}

#3
ok($raw->setContent(' world'), 'SetContent()');

{
	my $out = $raw->_getContent();
	#4
	is($out, 'Hello world', '_getContent()');
}

{
	$raw->setError("some error");
	my $out = $raw->_getContent();
	#5
	is($out, 'Error: some error', '_getContent() with error');	
}