#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SecureState-Forgetful.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "Load failed ... not ok 1\n" unless $loaded;}
use CGI qw(-no_debug);
use CGI::SecureState;
$loaded = 1;
$test=1;
print "ok $test\n";

@ISA=qw (CGI);
######################### End of black magic.

unless ( eval { require 5.005_03 } )
{
    warn "\nWow, you really insist on using an old version of PERL, don't you?\n";
    warn "If this is not a warning that you expected to see, read the README file\n";
    warn "Press return to continue.\n";
    <STDIN>;
}

$ENV{'REMOTE_ADDR'}='127.0.0.1';
$ENV{'REQUEST_METHOD'}='GET';

#test CGI->new
$test++;
my $cgi=new CGI::SecureState(-stateDir => ".", -mindSet => 1, -temp => [qw(param1 param2)]);
print "ok $test\n";

#test CGI->user_param
$test++;
$cgi->param('.tmpparam1' => "Test of param 1");
$cgi->param('.tmpparam2' => "Test".chr(2)." of param 2");
$cgi->recover_memory;
($param1, $param2) = $cgi->user_params('param1', 'param2');
if ($param1 ne "Test of param 1" or $param2 ne "Test".chr(2)." of param 2") {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

$test++;
if ($cgi->param('param1') or $cgi->param('param2')) {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

$test++;
my $url = $cgi->memory_as('url');
if ($url =~ /\.tmpparam1=Test/ and $url =~ /\.tmpparam2=Test\%02/) {
    print "ok $test\n";
} else {
    print "not ok $test\n";
}

#test CGI->add
$test++;
$cgi->add( param1 => ['alpha','beta'], param2 => ['gamma'] );
$cgi->add('random_stuff'.chr(2) => 'Some\[]/cv;l,".'.chr(244).chr(2).'bxpo wierdness');
$cgi->SUPER::delete('random_stuff'.chr(2));
$cgi->SUPER::delete('param1');
$cgi->SUPER::delete('param2');
$cgi->recover_memory;

@param1=$cgi->param('param1');
($param2,$random_stuff)=$cgi->params('param2','random_stuff'.chr(2));
if ($param1[0] ne 'alpha' or $param1[1] ne 'beta' or $param2 ne 'gamma' or
    $random_stuff ne 'Some\[]/cv;l,".'.chr(244).chr(2).'bxpo wierdness') {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}


#test CGI->delete
$test++;
$cgi->delete(qw(param1 param2),'random_stuff'.chr(2));
$cgi->recover_memory;
@param1=$cgi->param('param1');
($param2,$random_stuff)=$cgi->params('param2','random_stuff'.chr(2));

unless (!@param1 && ! defined $param2 && ! defined $random_stuff) {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

#test CGI->remember
$test++;
$cgi->param('param1', 'alpha', 'beta');
$cgi->param('param2', 'gamma');
$cgi->remember(qw(param1 param2));
$cgi->SUPER::delete('param1');
$cgi->SUPER::delete('param2');
$cgi->recover_memory;

@param1=$cgi->param('param1');
$param2=$cgi->param('param2');
if ($param1[0] ne 'alpha' or $param1[1] ne 'beta' or $param2 ne 'gamma') {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

#test CGI->delete_all
$test++;
$cgi->delete_all;
$cgi->recover_memory;
if ($cgi->param != 1) {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

#test CGI->age
$test++;
if ($cgi->age != 0) {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

#test CGI->delete_session
$test++;
$cgi->delete_session;
print "ok $test\n";
