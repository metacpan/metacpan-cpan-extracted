# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bloom.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More tests => 10;
$ENV{TEST_VERBOSE} = 1;

BEGIN { 
	use_ok('Bloom::Faster'); 
};


my $fail = 0;
foreach my $constname (qw(
	HASHCNT )) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Bloom macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $cnt = 100000; 
my $afth = 4;
my $bloom = new Bloom::Faster({n=>($cnt * $afth),e=>0.00001});
ok($bloom,"create object");
my $dups = 0;

my $tempfile = "bloomtest.$$";


open(FILE,">$tempfile");
my $i;
my $firststr = "peter alvaro";
print FILE "$firststr\n";
my $str;
for ($i=0;$i < $cnt; $i++) {
	$str = "$i ".int(rand(100000))." ".rand().time();
	print FILE "$str\n";
}
close FILE;

open (FILE,$tempfile);
my $tests;
while (<FILE>) {
	chomp;
	if ($bloom->add($_)) {
		$dups++;
	}
	$tests++;
}
close(FILE);
# those should have been unique.  test this assumption.
ok(($dups == 0),"nodups");

# tests should equal cnt
#ok(($tests == $cnt),"alltests");

# a repeat of the first string seen
ok(($bloom->add($firststr) == 1),"ok, dup");

# a repeat of the last string seen
ok(($bloom->add($str)),"ok, dup2");

## can we serialize to the file? 
ok(($bloom->to_file($tempfile) == 1), "ok, tofile");

#$bloom->DESTROY;

## try to read from the file
my $newbloom;
ok(($newbloom = new Bloom::Faster($tempfile)), "ok, reading");

## verify that the last string and first strings are still there
ok( ($newbloom->add($str) && $newbloom->add($firststr)), "ok, first and last still there");

## verify capacity is the same
ok (( $newbloom->capacity() == $bloom->capacity()), "ok, capacity regained");
unlink($tempfile);



