#!/usr/local/bin/perl -w

# Test ability to retrieve HTTP request info
######################### We start with some black magic to print on failure.
use lib '../blib/lib','../blib/arch';

BEGIN {$| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::Screen ();
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# util
sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

# Set up a CGI environment
$ENV{REQUEST_METHOD}='GET';
$ENV{QUERY_STRING}  ='game=chess&game=checkers&weather=dull';
$ENV{PATH_INFO}     ='/somewhere/else';
$ENV{PATH_TRANSLATED} ='/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}   ='/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT} = 8080;
$ENV{SERVER_NAME} = 'the.good.ship.lollypop.com';
$ENV{HTTP_LOVE} = 'true';

my $q = new CGI;
my $r = new CGI::Screen;

while (<DATA>) {
  print;
  print "not " if eval "\$q->$_ ne \$r->$_";
  print 'ok ', $.+1, "\n";
}
__DATA__
request_method
param('game')
param('weather')
param(-name=>'foo',-value=>'bar')
param(-name=>'foo')
http('love')
script_name
url
url(-absolute=>1)
url(-relative=>1)
url(-relative=>1,-path=>1)
param('foo')
param('weather')
