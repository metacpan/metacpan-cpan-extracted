# -*- Perl -*-

use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

BEGIN {
    use_ok('Crypt::IDA::Algorithm');
    use_ok('Crypt::IDA', ":all");	# needed for support functions
}

# Porting old Crypt::IDA tests to use new ::Algorithm interface


# test ida_split

# first test uses an identity matrix as the transform, which should
# effect a striping of input
my $id = Math::FastGF2::Matrix->
    new_identity(size => 3, org => 'rowwise', width => 1);
ok (defined ($id),   "problem creating 3x3 identity matrix!");

##
## Basic tests with default buffer size (much bigger than our message)
##

my ($s,$c); 			# spliter/combiner objects
my ($key,$mat);

# $f=fill_from_string("abcdefghi",3);
my $in_msg = "abcdefghi";


my ($u,$v,$w);
#my @e=(empty_to_string(\$u),
#       empty_to_string(\$v),
#       empty_to_string(\$w));

#ida_split(
#	    quorum  => 3,  shares   => 3, width => 1,
#	    matrix  => $id,
#	    # source, sinks
#	    filler  => $f, emptiers => \@e,
#	    # byte order flags
#	    inorder => 0,  outorder => 0,
#	   );

$s = Crypt::IDA::Algorithm->splitter(
    k => 3, rows => 3, w => 1,
    xform => $id,
    inorder => 0,  outorder => 0,);

# new
ok(ref($s), "splitter created successfully");

# n/a:
# ok (!defined($key), "ida_split didn't returned key (as expected)?"); 

#ok ($mat eq $id,    "ida_split returned unchanged matrix?");
is ($s->xform,$id,   "ida_split returned unchanged matrix?");

#ok ($rc == 9,       "ida_split processed 9 bytes? (got $rc)");
# Better do the split:
$s->fill_stream($in_msg);
$s->split_stream;
ok($u = $s->empty_substream(0), "empty_substream 0 returned true");
ok($v = $s->empty_substream(1), "empty_substream 1 returned true");
ok($w = $s->empty_substream(2), "empty_substream 2 returned true");

ok ($u eq "adg",    "ida_split gives correct first slice? (got '$u')");
ok ($u eq "adg",    "ida_split gives correct first slice? (got '$u')");

ok ($v eq "beh",    "ida_split gives correct second slice? (got '$v')");
ok ($v eq "beh",    "ida_split gives correct second slice? (got '$v')");

ok ($w eq "cfi",    "ida_split gives correct third slice? (got '$w')");
ok ($w eq "cfi",    "ida_split gives correct third slice? (got '$w')");

##
## Tests with buffer size
##

# needed to stop warnings about undefined vars
my @e;
my $rc;
my $f;

# test split using minimal buffer size...
# refill input, clear output
#my $f=fill_from_string("abcdefghi",3);
$in_msg = "abcdefghi";

$u=""; $v=""; $w="";

#@e=(empty_to_string(\$u),
#    empty_to_string(\$v),
#    empty_to_string(\$w));
#
#($key,$mat,$rc)=
#  ida_split(
#	    quorum => 3, shares => 3, width => 1,
#	    matrix => $id,
#	    # source, sinks
#	    filler => $f, emptiers => \@e,
#	    # byte order flags
#	    inorder => 0, outorder => 0,
#	    # new arg: bufsize
#	    bufsize => 1, bytes => 9,

$s = Crypt::IDA::Algorithm->splitter(
    k => 3, w => 1,
    xform => $id,
    inorder => 0, outorder => 0,
    bufsize => 1
);
ok(ref ($s),  "splitter with bufsize=1 created");

# n/a:
# ok (!defined($key), "ida_split returned key! (didn't expect one)");

# skip:
# ok ($mat eq $id,    "ida_split returned unchanged matrix?");

# simulate:
# ok ($rc == 9,       "ida_split processed 9 bytes? (got $rc)");
my $cols_written = 0;
while ($in_msg ne '') {
    my $str = substr $in_msg, 0, 3,''; # splice out full column
    $s->fill_stream($str);
    $s->split_stream;
    $u .= $s->empty_substream(0);
    $v .= $s->empty_substream(1);
    $w .= $s->empty_substream(2);
}

ok ($u eq "adg",    "ida_split gives correct first slice? (got '$u')");
ok ($v eq "beh",    "ida_split gives correct second slice? (got '$v')");
ok ($w eq "cfi",    "ida_split gives correct third slice? (got '$w')");

##
## Big looping test
##

my ($str,$k,$n,$l,$order,$b);

for $str ("A", "BC", "DEF", "GHIJ", "KLMNO", "PQRSTU") {  # 6 x
  for $k (1,2,5,7) {                                      # 4 x
    for $n ($k, $k + 1, $k + 3, $k + 5) {                 # 4 x
#      for $l (0,length($str)) {                           # 2 x
      for $l (length($str)) {                             # 2 x
	for $w (1,2,4) {	                          # 3 x
	  for $order (1,2) {                              # 2 x
	    for $b (1,3,7) {                              # 3 = 

	      my $test_parms = "secret '$str', quorum $k, shares $n," 
		  . " bytes $l, bufsize $b width $w order $order";
	      
	      # Keep this code for now, until fully ported.
	      my $len=length $str;	# length before null padding
	      while ($l % ($k * $w)) {
		  ++$l;		# length after null padding
	      }

	      # The Crypt::IDA code lets you choose between running up
	      # to the value passed in bytes => ... or running until
	      # EOF (bytes => 0). The new code doesn't handle either.
	      # But we do have to do something similar---padding.
	      $in_msg  = $str;	  # we can't modify string constants
	      $in_msg =~ s/^(.{$l}).*/$1/; ; # truncate to l bytes
	      $in_msg .= "\0" while length($in_msg) % ($k * $w);
	      
	      # Can keep original code and compare outputs
	      $f=fill_from_string($str, $k * $w );
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

	      my ($split,@shares);
	      # The same, using Algorithm::splitter, passing a matrix
	      $split = Crypt::IDA::Algorithm->splitter(
		  xform    => $mat, k  => $k, w => $w,
		  bufsize  => $b, inorder  => 0, outorder => $order,
	      );
	      my $save_in_msg = $in_msg;
	      # some of the tests are on strings that longer than window
	      @shares = (("") x $n);
	      do {
		  my $chunk = substr $in_msg, 0, $b * $k * $w, '';
		  $split->fill_stream($chunk);
		  $split->split_stream;
		  $shares[$_].=$split->empty_substream($_) foreach (0..$n-1);
	      } while ($in_msg);
	      # warn "matrix has ", $mat->ROWS, " rows and ", $mat->COLS,
	      # " columns";
	      is_deeply(\@shares, \@sinks, 
			"Split with matrix returns same for $test_parms "
			."(in_msg is '$save_in_msg')");

	      # The same, using Algorithm::splitter, passing a key
	      $in_msg = $save_in_msg;
	      @shares = (("") x $n);
	      # warn "key is [", join(", ", @$key), "]\n";
	      $split = Crypt::IDA::Algorithm->splitter(
		  k  => $k, w => $w, key => $key, sharelist => [ 0..$n-1 ],
		  bufsize  => $b, inorder  => 0, outorder => $order,
	      );
	      do {
		  my $chunk = substr $in_msg, 0, $b * $k * $w, '';
		  $split->fill_stream($chunk);
		  $split->split_stream;
		  $shares[$_].=$split->empty_substream($_) foreach (0..$n-1);
	      } while ($in_msg);

	      is_deeply(\@sinks, \@shares, 
			"Split with key returns same for $test_parms "
			."(in_msg is '$in_msg')");

	      
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
	      @shares = ();
	      # This code keeps the association between transform rows and
	      # share data intact
	      foreach my $row (@sharenums) {
		my @v = $mat->getvals($row,0,$k);
		$inv->setvals($dest_row,0, \@v);
		# push @f,fill_from_string($sinks[$row]);
		push @shares, $sinks[$row]; # for new code
		++$dest_row;
	      }
	      $inv=$inv->invert();	# replace original matrix
	      #warn "Failed to invert matrix\n" unless defined($inv);

	      # combine ... using old Crypt::IDA method
	      if (0) {
		  my $output="";
		  my $e=empty_to_string(\$output);
		  my $outlen = ida_combine(
		      quorum   => $k,  width    => $w,
		      matrix   => $inv,
		      fillers  => \@f, emptier  => $e,
		      bufsize  => $b,  bytes    => $l,
		      inorder  => $order,
		      outorder => 0
		  );
	      }
	      # New code: only check passing a transform matrix (not key)
	      my $comb = Crypt::IDA::Algorithm->combiner(
		  k => $k, w => $w, xform => $inv,
		  inorder => $order, outorder => 0
	      );
	      # as with splitting, some strings/shares are bigger than
	      # the buffer size
	      my $share_len = length($shares[0]);
	      my $row_len   = $b * $w;
	      my $out_msg   = '';
	      #warn "Share length is $share_len";
	      while ($share_len > 0) {
		  for my $row (0..$k-1) {
		      my $chunk = substr $shares[$row], 0, $row_len, '';
		      #warn "Chunk ($chunk) length is ", length $chunk;
		      $comb->fill_substream($row,$chunk);
		  }
		  $comb->combine_streams;
		  my $got_back = $comb->empty_stream;
		  #warn "got back $got_back from empty_stream";
		  $out_msg .= $got_back;
		  $share_len -= $row_len;
	      }

	      # disabled old combine code, so nothing to compare with
	      # is ($out_msg, $output, "Combine results agree; $test_parms");

	      $out_msg=~s/\0+$//;	# truncate output
	      # If the input were a binary file, deleting all \0's
	      # from the end would not be a good idea.  There is an
	      # alternative truncate method, provided we saved the
	      # original length of the secret:
	      #   substr $output,0,$len,'';

	      # test ...
	      ok ($out_msg eq $str,
		  "$test_parms (got '$out_msg', length ". length($out_msg). ")");
	    }
	  }
	}
      }
    }
  }
}

done_testing;
