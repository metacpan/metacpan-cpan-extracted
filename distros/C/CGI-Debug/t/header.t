# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..9\n"; }
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


# Just CR
test(2, `$perl t/header/cr.cgi` eq "Content-type: text/htmla1\n");

# CRLF
test(3, `$perl t/header/crlf.cgi` eq "Content-type: text/html\r\n\r\na1\n");

# Empty header
test(4, `$perl t/header/empty.cgi` eq "\n\na1\n");

# Multiline headers
test(5, `$perl t/header/extended.cgi` eq <<EOT);
Content-type: text/html
	and more
Something: else

a1
EOT
    ;

# Header format error
test(6, `$perl t/header/format.cgi` eq <<EOT);
Content-type: text/html

<html><head><title>CGI::Debug response</title></head><body>
<h2>/cgi-bin/foo.cgi</h2>
<plaintext>

Malformed header!

--- Program output below  -----------------------
Content-type text/html

a1

-------------------------------------------------


<EOF>
EOT
    ;

# Header mixed crlf error
test(7, `$perl t/header/format.cgi` eq <<EOT);
Content-type: text/html

<html><head><title>CGI::Debug response</title></head><body>
<h2>/cgi-bin/foo.cgi</h2>
<plaintext>

Malformed header!

--- Program output below  -----------------------
Content-type text/html

a1

-------------------------------------------------


<EOF>
EOT
    ;


# Ignored header
test(8, `$perl t/header/ignore.cgi` eq "bollibompa!\n");

# Minimal header
test(9, `$perl t/header/minimal.cgi` eq "Content-Type: text/html\n\na1\n");
