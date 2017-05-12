# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..11\n"; }
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

#Standard page
$output = "Content-type: text/html\n\na1\n";
$errheader = "<hr><h2>/cgi-bin/foo.cgi</h2>\n<plaintext>\n";
$warning_default = "Warning: something's wrong at t/control/default.cgi line 8.\n";
$warning_params = "Warning: something's wrong at t/control/params.cgi line 8.\n";
$warning_length = "Warning: something's wrong at t/control/length.cgi line 8.\n";
$time = "\nThis program finished in 0.684 seconds.\n";
$params = "
Parameters
----------
game    =   5[chess]
game    =   8[checkers]
weather =   4[dull]\n\n";
$params_l2 = "
Parameters
----------
game    =   5[ch]...
game    =   8[ch]...
weather =   4[du]...\n\n";
$params_l3 = "
Parameters
----------
game    =   5[che]...
game    =   8[che]...
weather =   4[dul]...\n\n";
$cookies = "\nCookies\n-------\n\n";
$enviroment = "
Environment
-----------
PATH_INFO       =  15[/somewhere/else]
PATH_TRANSLATED =  25[/usr/local/somewhere/else]
QUERY_STRING    =  37[game=chess&game=checkers&weather=dull]
REQUEST_METHOD  =   3[GET]
SCRIPT_NAME     =  16[/cgi-bin/foo.cgi]
SERVER_NAME     =  26[the.good.ship.lollypop.com]
SERVER_PORT     =   4[8080]
SERVER_PROTOCOL =   8[HTTP/1.0]\n\n";
$end = "\n<EOF>\n";

$start = $output.$errheader;

# Default output
$res = `$perl t/control/default.cgi`;
$res =~ s/in [\d\.]+ seconds/in 0.684 seconds/;
test(2, $res eq $start.$warning_default.$time.$params.$cookies.$enviroment.$end);

# Setting enviroment
$ENV{'CGI-Debug-report'}='errors';
test(3, `$perl t/control/default.cgi` eq $start.$warning_default.$end);

# env and params, cumulative
test(4, `$perl t/control/params.cgi` eq $start.$warning_params.$params.$end);

# env and cookie, cumulative
$ENV{'HTTP_COOKIE'} = 'CGI-Debug-report=time';
$res = `$perl t/control/default.cgi`;
$res =~ s/in [\d\.]+ seconds/in 0.684 seconds/;
test(5, $res eq $start.$warning_default.$time.$end);

# env, cookie and params, cumulative
$res = `$perl t/control/params.cgi`;
$res =~ s/in [\d\.]+ seconds/in 0.684 seconds/;
test(6, $res eq $start.$warning_params.$time.$params.$end);

# cookie and params, cumulative
delete $ENV{'CGI-Debug-report'};
$ENV{'HTTP_COOKIE'} = 'CGI-Debug-report=errors';
test(7, `$perl t/control/params.cgi` eq $start.$warning_params.$params.$end);

# env and params, override
$ENV{'CGI-Debug-set-param_length'}=2;
test(8, `$perl t/control/length.cgi` eq $start.$warning_length.$params_l2.$end);

# env, cookie and params, override
$ENV{'HTTP_COOKIE'} = 'CGI-Debug-set-param_length=3';
test(9, `$perl t/control/length.cgi` eq $start.$warning_length.$params_l3.$end);

# env and cookies, override
test(10, `$perl t/control/params.cgi` eq $start.$warning_params.$params_l3.$end);

# param and cookies, override
delete $ENV{'CGI-Debug-set-param_length'};
test(11, `$perl t/control/length.cgi` eq $start.$warning_length.$params_l3.$end);
