# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# util
sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

require 5.004_05;
use Config; $perl = $Config{'perlpath'};

# Set up a CGI environment
%ENV = ();
$ENV{REQUEST_METHOD}='GET';
$ENV{QUERY_STRING}  ='game=chess&game=checkers&weather=dull';
$ENV{PATH_INFO}     ='/somewhere/else';
$ENV{PATH_TRANSLATED} ='/usr/local/somewhere/else';
$ENV{SCRIPT_NAME}   ='/cgi-bin/foo.cgi';
$ENV{SERVER_PROTOCOL} = 'HTTP/1.0';
$ENV{SERVER_PORT} = 8080;
$ENV{SERVER_NAME} = 'the.good.ship.lollypop.com';


$error = <<EOT;
Content-type: text/html

<html><head><title>CGI Error</title></head><body>
<h1>CGI Error</h1>
<p>An error occured while generating this page.
The webmaster has now been notified.
</body></html>
EOT
    ;

# Compile error
test(2, `$perl t/file/compile.cgi` eq $error);

# Runtime error
test(3, `$perl t/file/die.cgi` eq "Content-type: text/html\n\na1\n");

# Header error
test(4, `$perl t/file/header.cgi` eq $error);

# Runtime warning
test(5, `$perl t/file/warn.cgi` eq "Content-type: text/html\n\na1\n");

# Custom error response
test(6, `$perl t/file/custom.cgi` eq "Status: 302 Moved\nLocation: failed.html\n\n");
