#!perl 

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use MyTestApp;
use Test::More tests => 2;

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'rm=mode1';

use CGI;
my $q = new CGI;
{
	my $testname = "Test RequireSSL in CGI::App class";
	
	my $app = new MyTestApp(QUERY=>$q);
	my $t;
    eval {$t = $app->run};
	ok ($@ =~ /https request required/, $testname);
}

{
	my $testname = "Test RewriteSSL in CGI::App class";
	
	my $app = new MyTestApp(QUERY=>$q, PARAMS => {rewrite_to_ssl => 1});
	my $t = $app->run;
	ok ($t =~ /Status:\s+302\s/, $testname);
}
