# -*- Perl -*-

use Test::More tests => 3503;
BEGIN { use_ok('Crypt::IDA', ':all') };

my $class="Crypt::IDA";

# Test fill_from_string
my $f=fill_from_string("Testing 1 2 3 4 5 6 7 8 9 10",1);
ok (defined ($f),   "fill_from_string returned something?");

ok ($f->{"SUB"}->(4)  eq "Test",   "got 4 bytes from string?");
ok ($f->{"SUB"}->(4)  eq "ing ",   "next 4 bytes from string?");
ok ($f->{"SUB"}->(18) eq "1 2 3 4 5 6 7 8 9 ",
    "next 18 bytes from string?");
ok ($f->{"SUB"}->(4)  eq "10",     "read to eof and beyond?");
my $eof_str=$f->{"SUB"}->(4);
ok (defined($eof_str),             "read at eof returns something?");
ok ($eof_str  eq "",               "empty string at eof?");

# fill_from_string with padding at end of string?
$f=fill_from_string("abcde", 4);
ok (defined ($f),   "fill_from_string(\$s,4) returned something?");
ok ($f->{"SUB"}->(3) eq "abc",
    "First 3 bytes from 4-aligned string?");
ok ($f->{"SUB"}->(3) eq "de\0",
    "1 byte of padding from 4-aligned string?");
ok ($f->{"SUB"}->(3) eq "\0\0",
    "last 2 bytes of padding from 4-aligned string?");
ok ($f->{"SUB"}->(2) eq "",
    "eof after padding on 4-aligned string?");

# Test calling fill_from_string with fully-qualified name
$f=Crypt::IDA::fill_from_string("FooBarBaz");
ok ($f->{"SUB"}->(9) eq "FooBarBaz",
    "fill_from_string called with classname::?");
$f=Crypt::IDA->fill_from_string("FooBarBaz");
ok ($f->{"SUB"}->(9) eq "FooBarBaz",
    "fill_from_string called with classname->?");
$f=fill_from_string($class,"FooBarBaz");
ok ($f->{"SUB"}->(9) eq "FooBarBaz",
    "fill_from_string called with (\$classname,\$string)?");

# more exhaustive tests on fill_from_string?
# ...
# Shouldn't need any more tests on aligned strings since padding is
# done once before any calls to the SUB callback.

# test empty_to_string
my ($e,$s,$rc);
$s=""; $e=empty_to_string(\$s);
ok(defined($e),          "empty_to_string(\\\$s) returned something?");
$rc=$e->{"SUB"}->("FooBarBaz");
ok($s eq "FooBarBaz",    "empty_to_string emptied first bit?");
ok ($rc == 9,            "empty_to_string emptied 9 bytes?");
$rc=$e->{"SUB"}->("Quux");
ok($s eq "FooBarBazQuux","empty_to_string appended second bit?");
ok ($rc == 4,            "empty_to_string emptied 4 bytes?");

# test fill_from_file

# mostly just a rehash of the fill_from_string tests, but the
# fill_from_file callback returns fewer bytes at end of file
my $filestr="Testing 1 2 3 4 5 6 7 8 9 10";
open FH, ">./test.$$" or die "Couldn't create test file";
print FH $filestr;
close FH;

$f=fill_from_file("./test.$$",0,0);
ok (defined ($f),                 "fill_from_file returned something?");

ok ($f->{"SUB"}->(4)  eq "Test",  "got first 4 bytes from file?");
ok ($f->{"SUB"}->(4)  eq "ing ",  "got next 4 bytes from file?");
ok ($f->{"SUB"}->(18) eq "1 2 3 4 5 6 7 8 9 ",
    "Next 18 bytes from file?");
ok ($f->{"SUB"}->(4)  eq "10",    "read to file eof and beyond?");
$eof_str=$f->{"SUB"}->(4);
ok (defined($eof_str),            "read at file eof returns something?");
ok ($eof_str  eq "",              "empty file at eof?");

# fill_from_file with padding at end of file?
$filestr="abcde";
open FH, ">./test.$$" or die "Couldn't create test file";
print FH $filestr;
close FH;
$f=fill_from_file("./test.$$", 4,0);
ok (defined ($f),        "fill_from_file(\$s,4,0) returned something?");
ok ($f->{"SUB"}->(3) eq "abc",    "first 3 bytes from 4-aligned file?");
ok ($f->{"SUB"}->(3) eq "de",
    "last two non-padding bytes from  4-aligned file?");
ok ($f->{"SUB"}->(1) eq "\0",
    "first byte of padding from 4-aligned file?");
ok ($f->{"SUB"}->(17) eq "\0\0",
    "last 2 bytes of padding from 4-aligned file?");
ok ($f->{"SUB"}->(2) eq "",
    "eof after padding on 4-aligned file?");
$f=undef; unlink "./test.$$";

# test ida_split

# first test uses an identity matrix as the transform, which should
# effect a striping of input
my $id=Math::FastGF2::Matrix->
  new_identity(size => 3, org => 'rowwise', width => 1);
ok (defined ($id),   "problem creating 3x3 identity matrix!");
$f=fill_from_string("abcdefghi",3);
my ($u,$v,$w);
my ($key,$mat);
my @e=(empty_to_string(\$u),
       empty_to_string(\$v),
       empty_to_string(\$w));
($key,$mat,$rc)=
  ida_split(
	    quorum  => 3,  shares   => 3, width => 1,
	    matrix  => $id,
	    # source, sinks
	    filler  => $f, emptiers => \@e,
	    # byte order flags
	    inorder => 0,  outorder => 0,
	   );
ok (!defined($key), "ida_split didn't returned key (as expected)?");
ok ($mat eq $id,    "ida_split returned unchanged matrix?");
ok ($rc == 9,       "ida_split processed 9 bytes? (got $rc)");
ok ($u eq "adg",    "ida_split gives correct first slice? (got '$u')");
ok ($v eq "beh",    "ida_split gives correct second slice? (got '$v')");
ok ($w eq "cfi",    "ida_split gives correct third slice? (got '$w')");

# test split using minimal buffer size...
# refill input, clear output
$f=fill_from_string("abcdefghi",3);
$u=""; $v=""; $w="";
@e=(empty_to_string(\$u),
    empty_to_string(\$v),
    empty_to_string(\$w));
($key,$mat,$rc)=
  ida_split(
	    quorum => 3, shares => 3, width => 1,
	    matrix => $id,
	    # source, sinks
	    filler => $f, emptiers => \@e,
	    # byte order flags
	    inorder => 0, outorder => 0,
	    # new arg: bufsize
	    bufsize => 1, bytes => 9,
	   );
ok (!defined($key), "ida_split returned key! (didn't expect one)");
ok ($mat eq $id,    "ida_split returned unchanged matrix?");
ok ($rc == 9,       "ida_split processed 9 bytes? (got $rc)");
ok ($u eq "adg",    "ida_split gives correct first slice? (got '$u')");
ok ($v eq "beh",    "ida_split gives correct second slice? (got '$v')");
ok ($w eq "cfi",    "ida_split gives correct third slice? (got '$w')");

# Loop through various combinations of input size, shares, quorum,
# etc.  We could probably skip these tests if any of the above failed,
# since there are so many tests here and many of them will probably
# fail if something went wrong above.
#
# Note that unlike the tests above (which used an identity matrix to
# transform the data) these tests generate a random transformation
# matrix every time they're run. While this is not ideal from the
# point of view of creating deterministic test cases, we do have a
# definite, deterministic outcome which we *can* test. It's really
# beyond the scope of these tests to test/prove that the IDA algorithm
# (with whatever random factors it uses) works (proving that is the
# job of mathematicians), just that *this implementation* does what it
# says on the tin, namely, that k shares of the n shares produced can
# be combined to recover the original secret.  In other words, these
# are purely black-box tests, and we can ignore the fact that they use
# non-deterministic functions (calls to rand or equivalent)
# internally.  The important thing is that we exercise/cover all the
# other variables in the implementation.

for my $s ("A", "BC", "DEF", "GHIJ", "KLMNO", "PQRSTU") {  # 6 x
  for my $k (1,2,5,7) {                                    # 4 x
    for my $n ($k, $k + 1, $k + 3, $k + 5) {               # 4 x
      for my $l (0,length($s)) {                           # 2 x
	for my $w (1,2,4) {	                           # 3 x
	  for my $order (1,2) {                            # 2 x
	    for my $b (1,3,7) {                            # 3 = 

	      # split ...
	      my $len=length $s;	# length before null padding
	      while ($l % ($k * $w)) {
		++$l;		# length after null padding
	      }
	      $f=fill_from_string($s, $k * $w );
	      my @sinks=(("") x $n);
	      @e=map { empty_to_string(\$sinks[$_]) } (0 .. $n-1);
	      ($key,$mat,$rc)=
		ida_split(
			  quorum   => $k, shares   => $n, width => $w,
			  filler   => $f, emptiers => \@e,
			  bufsize  => $b, bytes    => $l,
			  inorder  => 0,
			  outorder => $order,
			 );

	      # For combining, we have to make the inverse matrix by
	      # ourselves.
	      #
	      # Previously I was just using the first k shares, but
	      # for better test coverage, I'm changing this to pick a
	      # random selection of k shares. Note that as with
	      # picking random keys, this introduces another source of
	      # non-determinism to the test cases which isn't
	      # generally a good thing. But bear in mind that if
	      # there's something wrong with the code which this
	      # shuffling picks up, then the chances are exceedingly
	      # good that random testing like this will most likely
	      # point to a particular systemic problem (eg, writing $k
	      # instead of $n in the code somewhere) rather than a
	      # rare Heisenbug.  That is, that huge numbers of these
	      # tests should fail, rather than only a few tests
	      # failing rarely.

	      my @sharenums=(0.. $n-1);
	      ida_fisher_yates_shuffle(\@sharenums,$k);

	      my @f = ();
	      my $inv=
		Math::FastGF2::Matrix->new(rows => $k,       cols  => $k,
					   org  =>'rowwise', width => $w );
	      my $dest_row=0;

	      # This code keeps the association between transform rows and
	      # share data intact
	      foreach my $row (@sharenums) {
		my @v=$mat->getvals($row,0,$k);
		$inv->setvals($dest_row,0, \@v);
		push @f,fill_from_string($sinks[$row]);
		++$dest_row;
	      }
	      $inv=$inv->invert();	# replace original matrix
	      warn "Failed to invert matrix\n" unless defined($inv);

	      # combine ...
	      my $output="";
	      my $e=empty_to_string(\$output);
	      my $outlen=
		ida_combine(
			    quorum   => $k,  width    => $w,
			    matrix   => $inv,
			    fillers  => \@f, emptier  => $e,
			    bufsize  => $b,  bytes    => $l,
			    inorder  => $order,
			    outorder => 0,
			   );
	      $output=~s/\0+$//;	# remember to truncate output
	      # If the input were a binary file, deleting all \0's
	      # from the end would not be a good idea.  There is an
	      # alternative truncate method, provided we saved the
	      # original length of the secret: $output=substr
	      # $output,0,$len;

	      # test ...
	      ok ($output eq $s,
		  "secret '$s', quorum $k, shares $n, bytes $l, ".
		  "bufsize $b width $w order $order (got '$output', ".
		  "length ". length($output). ")");
	    }
	  }
	}
      }
    }
  }
}
