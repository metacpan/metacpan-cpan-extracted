# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..5\n"; }
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


# Compile error
test(2, `$perl t/fatals/compile.cgi` eq <<EOT);
Content-type: text/html

<html><head><title>CGI::Debug response</title></head><body>
<h2>/cgi-bin/foo.cgi</h2>
<plaintext>
Bareword "eRrOr" not allowed while "strict subs" in use at t/fatals/compile.cgi line 6.
Execution of t/fatals/compile.cgi aborted due to compilation errors.

Your program doesn\'t produce ANY output!


<EOF>
EOT
    ;

# Early runtime error
test(3, `$perl t/fatals/early.cgi` eq <<EOT);
Content-type: text/html

<html><head><title>CGI::Debug response</title></head><body>
<h2>/cgi-bin/foo.cgi</h2>
<plaintext>
Died at t/fatals/early.cgi line 6.

Your program doesn\'t produce ANY output!


<EOF>
EOT
    ;

# Late runtime error, html
test(4, `$perl t/fatals/late_html.cgi` eq <<EOT);
Content-type: text/html

a1
<hr><h2>/cgi-bin/foo.cgi</h2>
<plaintext>
Died at t/fatals/late_html.cgi line 8.

<EOF>
EOT
    ;

# Late runtime error, text
test(5, `$perl t/fatals/late_text.cgi` eq <<EOT);
Content-type: something/strange

a1


------------------------------------------------------------

	/cgi-bin/foo.cgi


Died at t/fatals/late_text.cgi line 8.

<EOF>
EOT
    ;
