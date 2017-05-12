# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use CGI::Enurl;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
sub test_enurl;

$num = 2;
# test_enurl $correct_result, @parameters;
test_enurl "a=b", {a => 'b'};

test_enurl 'hello+world', 'hello world';

test_enurl 'hello+world&others', 'hello world', 'others';

test_enurl 'hello+world&others', ['hello world', 'others'];

test_enurl 'hello+world&others', {1 => 'hello world', 2 => 'others'};

test_enurl 'greeting=hello+world&name=Jenda', {greeting => 'hello world', name => 'Jenda'};

test_enurl 'hello+world&name=Jenda', {1 => 'hello world', name => 'Jenda'};

exit;

#=========

sub test_enurl {
	my $good = shift();
	my $result = enurl(@_);
	if ($good eq $result) {
		print "ok $num\n";
	} else {
		print "not ok $num\n\t'$result' ne '$good'\n";
	}
	$num++;
}
