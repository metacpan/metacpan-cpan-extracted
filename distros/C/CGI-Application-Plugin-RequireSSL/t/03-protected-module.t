#!perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use MyTestApp;
use MyTestApp2;
use Test::More tests => 3;

$ENV{CGI_APP_RETURN_ONLY} = 1;
$ENV{REQUEST_METHOD}      = 'GET';
$ENV{QUERY_STRING}        = 'rm=mode2';

use CGI;
my $q = new CGI;
{
    my $testname = "Module requires SSL";

    my $app = new MyTestApp(QUERY => $q, PARAMS => {require_ssl => 1});
    my $t;
    eval { $t = $app->run };
    ok($@ =~ /https request required/, $testname);
}

{
    my $testname = "Module requires SSL, Request rewritten";

    my $app = new MyTestApp(
        QUERY  => $q,
        PARAMS => {require_ssl => 1, rewrite_to_ssl => 1}
    );
    my $t = $app->run;
    ok($t =~ /Status:\s+302\s/, $testname);
}

{
    my $testname = "Module requires SSL, Explicitly ignore check";

    my $app = new MyTestApp2(
        QUERY  => $q,
        PARAMS => {require_ssl => 1, rewrite_to_ssl => 1}
    );
    my $t = $app->run;
    ok($t =~ /called mode2/, $testname);
}

