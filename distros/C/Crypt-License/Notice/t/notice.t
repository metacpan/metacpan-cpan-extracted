# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..22\n"; }
END {print "not ok 1\n" unless $loaded;}
#use lib qw (../../blib/lib blib/lib);
use lib qw (blib/lib);
require Crypt::License::Notice;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test = 2;
my $tmp = './';
my $lf = 'License.tmp';
my $user = `/usr/bin/id -un`;
chomp $user;
my $tgt = "$user.bln";
my $notice = "./notice.tmp";

unlink $lf if (-e $lf);
unlink $notice if (-e $notice);
unlink "$tmp/$tgt" if (-e "$tmp/$tgt");

my $License_data = q|
 just some stuff to put in a file

 ID:	: 54321
 JUNK:	: a little junk
|;

my $expected_txt = q|From: root
To: monkey_see@monkey.do
Subject: LICENSE EXPIRATION

 ID:| . (split('ID:', $License_data))[1] . "\n";;

my $ptr = {
	'path'	=> do {$_ = `/bin/pwd`; chomp;$_} . "/$lf",
	'expires'	=> 12345,	# will write tmp file if detected
	'TMPDIR'	=> $tmp,
	'ACTION'	=> "/bin/cat > $notice",
	'TO'		=> 'monkey_see@monkey.do',
	'INTERVALS'	=> '2w,4d,8h,16m,32s,64',
};

@expectedI = (1209600,345600,28800,960,64,32);

#### FAIL tests first

# there is no license file
print "did not detect missing License file\nnot " if Crypt::License::Notice->check($ptr);
&OK_test;

# write a temporary license file
unless (open(LF,">$ptr->{path}")) {
  print "could not open $lf for write\nnot ";
} else {
  print LF $License_data;
  close LF;
}
&OK_test;

$tmp = $ptr->{path};
delete $ptr->{path};
print "did not detect missing 'path' hash key\nnot " if Crypt::License::Notice->check($ptr);
&OK_test;

$ptr->{path} = $tmp;

delete $ptr->{expires};

# there is no expiration
print "did not detect missing 'expires' hash key\nnot " if Crypt::License::Notice->check($ptr);
&OK_test;

# expiration is zero
$ptr->{expires} = 0;
print "did not detect zero 'expires' hash value\nnot " if Crypt::License::Notice->check($ptr);
&OK_test;

# expiration is greater than any check value
$ptr->{expires} = $expectedI[0] +1;
print "did not check expiration $ptr->{expires}\nnot " unless (@_ = Crypt::License::Notice->check($ptr));
&OK_test;

# unexpected notice tracking file found
print "unexpected tracking file $ptr->{TMPDIR}/$user.bln for $ptr->{expires}\nnot " if (-e "$ptr->{TMPDIR}/$user.bln");
&OK_test;

# unexpected notice found
print "created unexpected notice for $ptr->{expires}\nnot " if (-e $notice);
&OK_test;

# wrong number of check arguments
$tmp = 0;
++$tmp unless @_ == @expectedI;		# same number of arguments
print "wrong number of check arguments @_\nnot " if $tmp;
&OK_test;

$tmp = 0;
foreach(0..$#_) {
  ++$tmp unless $_[$_] == $expectedI[$_];
}
print "check times @_ do not agree with expected values\nnot " if $tmp;
&OK_test;

# detect illegal character
$tmp = $ptr->{INTERVALS};
$ptr->{INTERVALS} = '12x34';
eval{Crypt::License::Notice->check($ptr)};
print "did not detect illegal character string '$ptr->{INTERVALS}'\nnot " unless $@;

&OK_test;
$ptr->{INTERVALS} = $tmp;

#### PASS tests

# create tracking file and notice, test each epoch

$ptr->{INTERVALS} = '5,2';

my ($ctime, $prev);
foreach my $chk (5,2) {
# check that abutting timeout is NOT found
  &no_find($chk) unless $chk == 5;	# skip first back check
# check that overflow value is found
  $ptr->{expires} = $chk;
  $prev = &next_sec(time);
  Crypt::License::Notice->check($ptr);
  $_ = `/bin/cat $notice`;
  print "$chk, notice text does not match expected\nnot " unless $_ eq $expected_txt;
  &OK_test;
  $ctime = (stat("$ptr->{TMPDIR}/$user.bln"))[10];
  print "ctime $ctime is not now $prev\nnot " unless $ctime == $prev;
  &OK_test;
  unlink $notice;
}
# check 0 -- expired is not found ever
&no_find(0);
&no_find(0);

unlink "$ptr->{TMPDIR}/$user.bln" if ( -e "$ptr->{TMPDIR}/$user.bln");	# clean up

sub next_sec {
  my ($then) = @_;
  do { select(undef,undef,undef,0.1); $now = time } while ( $then == $now );	# wait for epoch
  $now;
}

sub OK_test {
  print "ok $test\n";
  ++$test;
}

sub no_find {
  my $chk = $_[0];
  $ptr->{expires} = $chk + 1;
  do { $tmp = &next_sec(time) } while ( $tmp < $prev + $ptr->{expires});
# wait for next epoch
  Crypt::License::Notice->check($ptr);
  print "$chk , unexpected notice found for check $ptr->{expires}\nnot " if (-e $notice);
  &OK_test;
  $ctime = (stat("$ptr->{TMPDIR}/$user.bln"))[10];
  print "ctime $ctime should be $prev\nnot " unless $ctime == $prev;
  &OK_test;
}
