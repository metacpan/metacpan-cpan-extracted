#!perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use MyTestApp;
use Test::More tests => 1;

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = 'rm=mode2';

use CGI;
my $q = new CGI;
{
	my $testname = "Standard call";
	
	my $app = new MyTestApp(QUERY=>$q);
	my $t = $app->run;
	ok ($t =~ /called mode2/, $testname);
}

