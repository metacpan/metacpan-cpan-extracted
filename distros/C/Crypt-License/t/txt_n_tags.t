# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..29\n"; }
END {print "not ok 1\n" unless $loaded;}
use License;
use Digest::MD5;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $tf = 'delete.me.tmp';
my $test = 2;

my $test_text = "

        This is the test	text.
It has trailing blanks here      
and it started with a leading blank line.
 Leading spaces are left in place  as are multiple spaces.


Multiple internal blank lines, but		tabs are converted to
single spaces. Some fields follow. Colon's are not allowed in the text
field so DON'T PUT THEM IN!!!

This line has a tab and a space	 separating the previous words.

TAG1:	:value 1   
TAG2::no space here and trailing spaces here and TAG1   
TAG3:	:tab here and	in this value
a_num: :4
KEY:	:this is the last value
";
my @expected_text = split(/\n/, "        This is the test text.
It has trailing blanks here
and it started with a leading blank line.
 Leading spaces are left in place  as are multiple spaces.


Multiple internal blank lines, but tabs are converted to
single spaces. Some fields follow. Colon's are not allowed in the text
field so DON'T PUT THEM IN!!!

This line has a tab and a space  separating the previous words.

TAG1: :value 1
TAG2::no space here and trailing spaces here and TAG1
TAG3: :tab here and in this value
a_num: :4
KEY: :this is the last value
");

my %expected_tags = (
	'TAG1'		=> 'value 1',
	'TAG2'		=> 'no space here and trailing spaces here and TAG1',
	'TAG3',		=> 'tab here and in this value',
	'a_num'	=> 4,
	'KEY',		=> 'this is the last value',
);

################# TESTS START HERE

if ( open(T,">$tf") ) {
  print T $test_text;
  close T;
} else {
  print "could not open test file $tf for write\nnot ";
}
print "ok $test\n";
++$test;

my @file_text = Crypt::License::get_file($tf);

print "could not delete $tf\nnot "
	unless unlink $tf;
print "ok $test\n";
++$test;

print 'file text array not the right size, want ', @expected_text, ' got ', @file_text, "\nnot "
  unless $#file_text == $#expected_text;
print "ok $test\n";
++$test;

foreach(0..$#expected_text) {
  print 'line #', sprintf("%2d: ", $_ +1) , "|$file_text[$_]|\n",
	 "should be |$expected_text[$_]|\nnot "
	unless $expected_text[$_] eq $file_text[$_];
  print "ok $test\n";
  ++$test;
}

my %parms;
my $tag_line = Crypt::License::extract(\@file_text,\%parms);

print "tag line is $tag_line, should be 12\nnot "
	unless $tag_line == 12;
print "ok $test\n";
++$test;

my ($i,$o);
print 'tag hash wrong size = ', ($o=(%parms)+1), ' want ',
	($i=(%expected_tags)+1), "\nnot "
	unless ($o=(%parms)) eq ($i=(%expected_tags));
print "ok $test\n";
++$test;

foreach(sort keys %parms) {
  unless ( exists $expected_tags{$_} ) {
    print "tag $_	= $parms{$_} not found in expected tags\nnot ";
  } else {
    print "$_:	= |$parms{$_}|\n",
	"want	= |$expected_tags{$_}|\nnot "
	unless $parms{$_} eq $expected_tags{$_};
  }
  print "ok $test\n";
  ++$test;
}

my $md5 = Digest::MD5->new;
$md5->add(@expected_text);
$i = $md5->b64digest;

$md5 = Digest::MD5->new;
$md5->add(@file_text);
$o = $md5->b64digest;

print "md5 sums do not match\nnot "
  unless $o eq $i;
print "ok $test\n";
++$test;

