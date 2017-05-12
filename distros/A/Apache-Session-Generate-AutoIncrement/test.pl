# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::Session::Generate::AutoIncrement;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

eval {
  my $o = new Apache::Session::Generate::AutoIncrement( {} );
  print "not ok 2\n"; # line above should produce an error
};
print "ok 2\n" if $@;

my $pack = "";
my $testfile = "/tmp/Apache_Session_Generate_AutoIncrement_$$";
my $session = { args=>{CounterFile=>$testfile} };
my $value;
eval {
  $value = Apache::Session::Generate::AutoIncrement::generate($session);
  print "ok 3\n";
};
print "not ok 3 : $@\n" if $@;

$value = Apache::Session::Generate::AutoIncrement::generate($session);
$session->{data}->{_session_id} = $value;
if ( $value == 2
	  && $value eq "0000000002"
	  && Apache::Session::Generate::AutoIncrement::validate($session) ) {
  print "ok 4\n";
} else {
  print "not ok 4: $value\n";
}

$value = Apache::Session::Generate::AutoIncrement::generate($session);
$session->{data}->{_session_id} = $value;
if ( $value == 3
	  && $value eq "0000000003"
	  && Apache::Session::Generate::AutoIncrement::validate($session) ) {
  print "ok 5\n";
} else {
  print "not ok 5: $value\n";
}

$session->{args}->{IDLength} = 5;
eval {
  $value = Apache::Session::Generate::AutoIncrement::generate($session);
  print "ok 6\n";
};
print "not ok 6\n" if $@;

$value = Apache::Session::Generate::AutoIncrement::generate($session);
$session->{data}->{_session_id} = $value;
if ( $value == 5
	  && $value eq "00005"
	  && Apache::Session::Generate::AutoIncrement::validate($session) ) {
  print "ok 7\n";
} else {
  print "not ok 7\n";
}


# Cleanup
unlink $testfile;

