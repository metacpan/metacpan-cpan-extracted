# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::CryptHash;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.
#use warnings;
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $name = 'TESTING CryptHash';
my %x = (
	'check' => 'is x1',
	'a'     => 'is a',
	'x'     => 'is x',
	'y'     => 'is y',
	'r'     => 'is r',
);

my @k = ('x','r');

my @check = ('x','r');

my %bad = %x;
$bad{x} = 'different';

my %z;

my $failed = 0;
my $testno = 2;

my $c = Apache::CryptHash->init;
$c->name($name);

my $v = $c->encode(\%x, \@k);
my $dc = $v;		# decrypted string
my $rv;		# return value

$c = Apache::CryptHash->init;
$c->name($name);
unless ($rv = $c->decode(\$dc, \%z, \@check)) {
  print "failed decrypt\nnot ";
}
print "ok $testno\n";
++$testno;

unless ( $rv eq  $name ) {
  print "decode did not return '", $name, "'\nnot ";
}
print "ok $testno\n";
++$testno;

foreach (sort keys %x) { 
  unless ( $z{$_} eq $x{$_} ) {
    print "items don't match $_\torig=$x{$_} dcrypt=$z{$_}\n";
    ++$failed;
  }
}
print 'not ' if $failed;
print "ok $testno\n";
++$testno;

$bad{MAC} = $z{MAC};	# setup bad decode array

unless ( $c->checkMAC( \%z, \@check )) {
  print "failed good MAC check\nnot ";
}
print "ok $testno\n";
++$testno;

if ( $c->checkMAC( \%bad, \@check )) {
my $zy = $c->checkMAC( \%bad, \@check );
  print "passed?? bad MAC check\nnot ";
}
print "ok $testno\n";
++$testno;

my $expected = '9df35756e960e13555a423af4bb8fbce';
my $md5val = $c->md5_hex($name);
if ( $expected ne $md5val ) {
  print "bad md5_hex=$md5val\nexpect hexv=$expected\nnot ";
} 
print "ok $testno\n";
++$testno;

$expected = 'nfNXVulg4TVVpCOvS7j7zg';
$md5val = $c->md5_b64($name);
if ( $expected ne $md5val ) {
  print "bad md5_b64=$md5val\nexpect b64v=$expected\nnot ";
} 
print "ok $testno\n";
++$testno;


$name = 'Harry';
$c = Apache::CryptHash->init('password2');;
$c->name($name);

$v = undef;
$v = $c->encode(\%x, \@k);
$dc = $v;		# decrypted string

$c = Apache::CryptHash->init;
$c->name($name);
$c->passcode('password2');
unless ($rv = $c->decode(\$dc, \%z, \@check)) {
  print 'failed decrypt', "\nnot ";
}
print "ok $testno\n";
++$testno;

unless ( $rv eq  $name ) {
  print "decode did not return '", $name, "'\nnot ";
}
print "ok $testno\n";
++$testno;

foreach (sort keys %x) { 
  unless ( $z{$_} eq $x{$_} ) {
    print "items don't match $_\torig=$x{$_} dcrypt=$z{$_}\n";
    ++$failed;
  }
}
print 'not ' if $failed;
print "ok $testno\n";
++$testno;

$expected = 'db05833c29e688b5ab54d5e8608a72ec';
$md5val = $c->md5_hex($name);
if ( $expected ne $md5val ) {
  print "bad md5_hex=$md5val\nexpect hexv=$expected\nnot ";
} 
print "ok $testno\n";
++$testno;

$expected = '2wWDPCnmiLWrVNXoYIpy7A';
$md5val = $c->md5_b64($name);
if ( $expected ne $md5val ) {
  print "bad md5_b64=$md5val\nexpect b64v=$expected\nnot ";
} 
print "ok $testno\n";
++$testno;

