#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Unicode.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
    unless (eval { require 5.008 } ) {
	print "1..0 \#Skipped: Perl 5.8.0 or higher required for Unicode test.\n";
	exit;
    }
    $| = 1; print "1..6\n";
}
END {print "Load failed ... not ok 1\n" unless $loaded;}

use CGI qw(-no_debug);
use CGI::SecureState;
$loaded = 1;
$test=1;
print "ok $test\n";

@ISA=qw (CGI);
######################### End of black magic.

$ENV{'REMOTE_ADDR'}='127.0.0.1';
$ENV{'REQUEST_METHOD'}='GET';

#test CGI->new
$test++;
my $cgi=new CGI::SecureState(-stateDir => ".", -mindSet => 1, -temp => ["\x{4141}"]);
print "ok $test\n";

#test CGI->user_param
$test++;
$cgi->param(".tmp\x{4141}" => "Test of param 1\x{1310}");
$cgi->recover_memory;
($param1) = $cgi->user_param("\x{4141}");
if ($param1 ne "Test of param 1\x{1310}") {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

$test++;
if ($cgi->param("\x{4141}")) {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

#test CGI->add
$test++;
$cgi->add( "Some \x{123412} wierd \x{1313} Unicode" => ["a\x{1210}pha","beta"], "Stup\x{236A}" => ["\x{2341}"] );
$cgi->add('random_stuff'.chr(2) => 'Some\[]/cv;l,".'.chr(244).chr(2).'bxpo wierdness');
$cgi->SUPER::delete('random_stuff'.chr(2));
$cgi->SUPER::delete('param1');
$cgi->SUPER::delete('param2');
$cgi->recover_memory;

@param1=$cgi->param("Some \x{123412} wierd \x{1313} Unicode");
($param2,$random_stuff)=$cgi->params("Stup\x{236A}",'random_stuff'.chr(2));
if ($param1[0] ne "a\x{1210}pha" or $param1[1] ne 'beta' or $param2 ne "\x{2341}" or
    $random_stuff ne 'Some\[]/cv;l,".'.chr(244).chr(2).'bxpo wierdness') {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}


#test CGI->delete
$test++;
$cgi->delete("Some \x{123412} wierd \x{1313} Unicode","Stup\x{236A}" ,'random_stuff'.chr(2));
$cgi->recover_memory;
@param1=$cgi->param("Some \x{123412} wierd \x{1313} Unicode");
($param2,$random_stuff)=$cgi->params("Stup\x{236A}",'random_stuff'.chr(2));

unless (!@param1 && ! defined $param2 && ! defined $random_stuff) {
    print "not ok $test\n";
} else {
    print "ok $test\n";
}

$cgi->delete_session;
