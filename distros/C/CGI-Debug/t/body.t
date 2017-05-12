# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..4\n"; }
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

# empty body, html
$res = `$perl t/body/empty_html.cgi`;
$exp = <<EOT;
Content-type: text/html

<html><head><title>CGI::Debug response</title></head><body>
<h2>/cgi-bin/foo.cgi</h2>
<plaintext>

Empty body!

--- Here is the header --------------------------
Content-type: text/html


-------------------------------------------------


<EOF>
EOT
test(2, $res eq $exp );


# empty body, text
$res = `$perl t/body/empty_text.cgi`;
$exp = <<EOT;
Content-type: text/html

<html><head><title>CGI::Debug response</title></head><body>
<h2>/cgi-bin/foo.cgi</h2>
<plaintext>

Empty body!

--- Here is the header --------------------------
Content-type: something/else


-------------------------------------------------


<EOF>
EOT
test(3, $res eq $exp );


# empty body, died
$res = `$perl t/body/die.cgi`;
$exp = <<EOT;
Content-type: text/html

<html><head><title>CGI::Debug response</title></head><body>
<h2>/cgi-bin/foo.cgi</h2>
<plaintext>
Died at t/body/die.cgi line 7.

<EOF>
EOT
test(4, $res eq $exp );

