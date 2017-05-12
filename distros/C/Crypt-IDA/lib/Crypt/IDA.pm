package Crypt::IDA;

use 5.008008;
use strict;
use warnings;

use Carp;
use Fcntl qw(:DEFAULT :seek);
use Math::FastGF2 qw(:ops);
use Math::FastGF2::Matrix;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;

our @export_default = qw(fill_from_string fill_from_fh
			 fill_from_file empty_to_string
			 empty_to_fh empty_to_file
			 ida_split ida_combine);
our @export_extras  = qw(ida_rng_init ida_fisher_yates_shuffle
			 ida_generate_key ida_check_key
			 ida_key_to_matrix ida_check_transform_opts
			 ida_check_list);

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'default' => [ @export_default ],
		     'extras'  => [ @export_extras  ],
		     'all'     => [ @export_extras, @export_default  ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.01';

# hard-coding module names is supposedly not good style, but at least
# I'm up-front about breaking that "rule":
our $classname="Crypt::IDA";

sub fill_from_string {
  # Allow calling as a regular sub call or as a method. This might not
  # be a good style to use, but it allows callers to use either the
  # exported name, as in $f=fill_from_string(...) or to avoid
  # exporting any method names and use the fully-qualified call
  # $f=Crypt::IDA::fill_from_string(...) without needing to worry
  # about the extra class name parameter.  Of course, this means that
  # if the user wants to use the class name as the first input
  # parameter, they'll have to specify it twice. A similar pattern is
  # used in other routines in this module.
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    # we won't actually use the $self->method() style of calling, but
    # with this pattern we could if we wanted to.
    $self=$classname;
    $class=$classname;
  }
  my $s     = shift;
  my $align = shift || 1;

  # There's a one-line (non-looping) way of doing the following, but
  # writing it as a loop is simpler to understand and hence less prone
  # to errors
  while ((length $s) % $align) { $s.="\0" }
  return {
	  SUB => sub {
	    my $bytes=shift;
	    # substr returns an empty string if input is empty
	    return substr $s, 0, $bytes, "";
	  }
	 };
}

sub empty_to_string {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my $strref=shift;

  return {
	  SUB => sub {
	    my $str=shift;
	    $$strref.=$str;
	    return length $str;
	  }
	 };
}

sub fill_from_fh {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my $fh=shift;
  my $align=shift || 0;
  my $offset=shift || 0;
  my $eof=0;
  my $bytes_read=0;

  if ($offset) { sysseek $fh, $offset, SEEK_SET; }

  return {
	  SUB => sub {
	    my $bytes = shift;
	    my $buf = "";
	    if ($bytes < 0) {
	      carp "Asked to read $bytes bytes\n";
	    }
	    my $rc = sysread $fh, $buf, $bytes;

	    if ($rc == 0) {
	      if ($align) {
		while ($bytes_read % $align and
		       length($buf) < $bytes) {
		  $buf.="\0";
		  ++$bytes_read;
		}
	      }
	    } elsif ($rc < 0) {
	      return undef;
	    } else {
	      $bytes_read+=$rc;
	    }
	    return $buf;
	  }
	 };
}

sub fill_from_file {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my $filename = shift;
  my $align    = shift || 0;
  my $offset   = shift || 0;
  my $fh;

  return undef  unless (sysopen $fh, $filename, O_RDONLY);
  return fill_from_fh($fh,$align,$offset);
}

sub empty_to_fh {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my $fh     = shift;
  my $offset = shift || 0;

  #warn "got fh=$fh; offset=$offset\n";
  sysseek $fh, $offset, SEEK_SET if $offset;
  return {
	  SUB => sub {
	    my $str=shift;
	    return syswrite $fh, $str;
	  }
	 };
}

sub empty_to_file {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my $filename = shift;
  my $perm     = shift || 0644;
  my $offset   = shift || 0;
  my $fh;

  return undef unless
    sysopen $fh, $filename, O_CREAT | O_WRONLY, $perm;
  return $self->empty_to_fh($fh, $offset);
}

# ida_process_streams is the heart of the module. It's called from
# both ida_split and ida_combine, so it's capable of operating with
# just one or several fillers/emptiers. Its main purpose is to manage
# the input/output buffers, and it calls the external matrix multiply
# code to actually transform blocks of data in large chunks. For
# efficiency, it has some requirements on the organisation of
# input/output buffer matrices. It also delegates the task of
# reading/writing data to relatively simple user-supplied callbacks.
# This module isn't intended to be called by users directly, though,
# so it's not even documented in the POD section. Even though
# technically this could be useful if the user wanted to specify their
# own input/output matrices, there's so little error-checking of
# parameters here that it's probably best not to mention its
# existence/availability.
sub ida_process_streams {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my ($xform, $in, $fillers, $out, $emptiers, $bytes_to_read,
     $inorder, $outorder)=@_;

  # default values are no byte-swapping, read bytes until eof
  $inorder=0         unless defined($inorder);
  $outorder=0        unless defined($outorder);
  $bytes_to_read = 0 unless defined($bytes_to_read);

  my $bytes_read=0;
  my ($IR, $OW);		# input read, output write pointers
  my ($ILEN, $OLEN);
  my ($IFmin, $OFmax);		# input and output buffer fill levels
  my ($want_in_size, $want_out_size);

  my ($eof, $rc, $str, $max_fill, $max_empty);
  my $width=$in->WIDTH;
  my $bits=$width << 3;
  my $rows=$in->ROWS;

  my $nfillers  = scalar(@$fillers);
  my $nemptiers = scalar(@$emptiers);
  my ($idown,$odown);
  my ($iright,$oright);
  my ($rr,$cc);
  my ($i, $k);
  my ($start_in_col,$start_out_col);

  #warn "-------------------------------------\n";
  #warn "Asked to process $bytes_to_read bytes\n";
  #warn "Input cols is " .$in->COLS. ", Output cols is " . $out->COLS . "\n";
  #warn "Inorder is $inorder, Outorder is $outorder\n";
  #warn "There are $nfillers fillers, $nemptiers emptiers\n";

  if ($bytes_to_read % ($width * $xform->COLS)) {
    carp "process_streams: bytes to read not a multiple of COLS * WIDTH";
    return undef;
  }
  unless ($nfillers == 1 or $nfillers==$in->ROWS) {
    carp "Fillers must be 1 or number of input rows";
    return undef;
  }
  unless ($nemptiers == 1 or $nemptiers == $out->ROWS) {
    carp "Emptiers must be 1 or number of output rows";
    return undef;
  }


  ($IFmin, $OFmax, $IR, $OW) = (0,0,0,0);
  if ($nfillers == 1) {
    if ($in->ORG ne "colwise" and $in->ROWS != 1) {
      carp "Need a 'colwise' input matrix with a single filler";
      return undef;
    }
    $ILEN=$rows * $in->COLS * $width;
    $idown=$width;
    $iright=$in->ROWS * $width;
    $want_in_size = $width * $rows;
  } else {
    if ($in->ORG ne "rowwise" and $in->ROWS != 1) {
      carp "Need a 'rowwise' input matrix with multiple fillers";
      return undef;
    }
    $ILEN=$in->COLS * $width;
    $idown=$ILEN;
    $iright=$width;
    $want_in_size = $width;
  }
  for my $i (0 .. $nfillers - 1) {
    $fillers->[$i]->{"IW" }  = $i * $idown;
    $fillers->[$i]->{"END"}  = $i * $idown + $ILEN - 1;
    $fillers->[$i]->{"BF"}   = 0;
    $fillers->[$i]->{"PART"} = ""; # partial word
  }
  if ($nemptiers == 1) {
    if ($out->ORG ne "colwise" and $out->ROWS != 1) {
      carp "Need a 'colwise' output matrix with a single emptier";
      return undef;
    }
    $OLEN=$out->ROWS * $out->COLS * $width;
    $odown=$width;
    $oright=$out->ROWS * $width;
    $want_out_size = $width * $out->ROWS;
  } else {
    if ($out->ORG ne "rowwise" and $out->ROWS != 1) {
      carp "Need a 'rowwise' output matrix with multiple emptiers";
      return undef;
    }
    $OLEN   = $out->COLS * $width;
    $odown  = $OLEN;
    $oright = $width;
    $want_out_size = $width;
  }
  for my $i (0 .. $nemptiers - 1) {
    $emptiers->[$i]->{"OR"}   = $i * $odown;
    $emptiers->[$i]->{"END"}  = $i * $odown + $OLEN - 1;
    $emptiers->[$i]->{"BF"}   = 0;
    $emptiers->[$i]->{"SKIP"} = 0;
  }

  do {
    # fill some of the input matrix
    #warn "Checking whether we need input (IFmin=$IFmin)\n";
    while (!$eof and ($IFmin < $want_in_size)) {
      #warn "Seems like we need input\n";
      for ($i = 0, $IFmin=$ILEN; $i < $nfillers ; ++$i) {
	#warn "IR is $IR, filler ${i}'s IW is " . $fillers->[$i]->{"IW"}. "\n";
	$max_fill = $ILEN - $fillers->[$i]->{"BF"};
	if ($fillers->[$i]->{"IW"} >= $IR + $i * $idown) {
	  if ($fillers->[$i]->{"IW"} + $max_fill >
	      $fillers->[$i]->{"END"}) {
	    $max_fill = $fillers->[$i]->{"END"} -
	      $fillers->[$i]->{"IW"} + 1;
	  }
	} else {
	  if ($fillers->[$i]->{"IW"} + $max_fill >=
	      $IR + $i * $idown) {
	    $max_fill = $IR  + $i * $idown - $fillers->[$i]->{"IW"};
	  }
	}

	#warn "Before adjusting maxfill: $max_fill (bytes read $bytes_read)\n";
	#warn "BF on filler $i is ". $fillers->[$i]->{"BF"} . "\n";
	if ($bytes_to_read and
	    ($bytes_read  + $max_fill > $bytes_to_read)) {
	  $max_fill = $bytes_to_read - $bytes_read;
	}

	#next unless $max_fill;

	#warn "Calling fill handler, maxfill $max_fill\n";

	# Subtract the length of any bytes from partial word read in
	# the last time around.
	$max_fill-=length $fillers->[$i]->{"PART"};
	die "max fill: $max_fill < 0\n" unless $max_fill >= 0;

	$str=$fillers->[$i]->{"SUB"}->($max_fill);

	#warn "Got input '$str' on row $i, length ". length($str). "\n";

	if (!defined($str)) {
	  carp "Read error on input stream $!";
	  return undef;
	} elsif ($str eq "") {
	  ++$eof;
	} else {
	  # setvals must be passed a string that's aligned to width
	  # (mainly so that it can do byte-order manipulation). As a
	  # result, we need to keep track of any bytes left over from
	  # the last call to the fill handler and prepend them to the
	  # string to be sent to setvals. We also need to chop off any
	  # extra bytes at the end of the string and save them until
	  # the next time around.

	  #warn "Got string '$str' from filler $i\n";
	  #warn "length of str is " . (length($str)) . "\n";

	  my $aligned=$fillers->[$i]->{"PART"} . $str;
	  $fillers->[$i]->{"PART"}=
	    substr $aligned,
	      (length($aligned) - (length($aligned) % $width)),
		(length($aligned) % $width),
		  "";
	  die "Alignment problem with filler $i\n"
	    if length($aligned) % $width;
	  die "Alignment problem with fill pointer $i\n"
	    if $fillers->[$i]->{"IW"} % $width;

	  #next unless length $aligned;

	  #warn "Adding string '$aligned' to input buffer\n";

	  $in->
	    setvals($in->
		    offset_to_rowcol($fillers->[$i]->{"IW"}),
		    $aligned,
		    $inorder);

	  # For the purpose of updating IW and BF variables, we
	  # pretend we didn't see any bytes from partial words
	  my $saw_bytes=(length $aligned) - (length($aligned) % $width) ;
	  $bytes_read += $saw_bytes;
	  $fillers->[$i]->{"BF"}  += $saw_bytes;
	  $fillers->[$i]->{"IW"}  += $saw_bytes;
	  if ($fillers->[$i]->{"IW"} > $fillers->[$i]->{"END"}) {
	    $fillers->[$i]->{"IW"}  -= $ILEN;
	  }
	}
	if ($fillers->[$i]->{"BF"} < $IFmin) {
	  $IFmin = $fillers->[$i]->{"BF"};
	}
      }
      if ($eof) {
	print "EOF detected in $eof stream(s)\n";
	if ($eof % $nfillers) {
	  carp "Not all input streams of same length";
	  return undef;
	}
      }
    }

    # flush some of the output matrix and do some processing
    do {

      #warn "Checking for output space; OFmax is $OFmax\n";

      # flush output buffer if we need some space
      while (($eof && $OFmax) || ($OFmax + $want_out_size > $OLEN)) {

        #warn "Seems like we needed to flush\n";

	for ($i=0, $OFmax=0; $i < $nemptiers; ++$i) {

	  $max_empty = $emptiers->[$i]->{"BF"};
	  if ($emptiers->[$i]->{"OR"} >= $OW + $i * $odown)  {
	    if ($emptiers->[$i]->{"BF"} + $want_out_size > $OLEN) {
	      $max_empty = $emptiers->[$i]->{"END"} -
		$emptiers->[$i]->{"OR"} + 1;
	      #warn "Stopping overflow, max_empty is now $max_empty\n";
	    }
	  } else {
	    if ($emptiers->[$i]->{"OR"} + $want_out_size >
		$OW + $i * $odown) {
	      #warn "Stopping tail overwrite, max_empty is now $max_empty\n";
	      $max_empty =
		$OW + $i * $odown - $emptiers->[$i]->{"OR"};
		# printf ("Stopping tail overwrite, max_empty is now %Ld\n", 
		#   (long long) max_fill_or_empty);  */
	    }
	  }

	  die "invalid max empty $max_empty\n" 
	    if $max_empty>0 and $max_empty<$width;
	  #next unless $max_empty;

	  # call handler to empty some data
	  #warn "Emptying row $i, col ".
	  #  ($emptiers->[$i]->{"OR"} % ( $out->COLS * $width)) .
	  #    " with $max_empty bytes\n";

	  die "Alignment problem with OR emptier $i" if
	    $emptiers->[$i]->{"OR"} % $width;
	  ($rr,$cc)=$out->
	    offset_to_rowcol($emptiers->[$i]->{"OR"});

	  #warn "got (row,col) ($rr,$cc) from OR#$i offset ".
	  #  $emptiers->[$i]->{"OR"}. "\n";

	  # When emptying, we have to check whether the emptier
	  # emptied full words. If it emptied part of a word, we have
	  # to prevent those bytes that were sent from being sent
	  # again. To do this, we keep track of a SKIP variable for
	  # each output buffer, which is the number of bytes to skip
	  # at the start of the output string.

	  $str=$out->
	    getvals($rr,$cc,
		    $max_empty / $width,
		    $outorder);
	  #substr $str, 0, $emptiers->[$i]->{"SKIP"}, "";
	  $rc=$emptiers->[$i]->{"SUB"}->($str);

	  unless (defined($rc)) {
	    carp "ERROR: write error $!\n";
	    return undef;
	  }
	  #$emptiers->[$i]->{"SKIP"} = $rc % $width;
	  #$rc -= $rc % $width;
	  $emptiers->[$i]->{"BF"}   -= $rc;
	  $emptiers->[$i]->{"OR"}   += $rc;
	  if ($emptiers->[$i]->{"OR"} > $emptiers->[$i]->{"END"}) {
	    $emptiers->[$i]->{"OR"} -= $OLEN;
	  }
	  if ($emptiers->[$i]->{"BF"} > $OFmax) {
	    $OFmax = $emptiers->[$i]->{"BF"};
	  }
	}
      }

      # do some processing
      #warn "Processing: IR=$IR, OW=$OW, IFmin=$IFmin, OFmax=$OFmax\n";
      ($rr,$cc)=$in->offset_to_rowcol($IR);
      $start_in_col = $cc;
      ($rr,$cc)=$out->offset_to_rowcol($OW);
      $start_out_col = $cc;
      $k=int ($IFmin  / $want_in_size);
      #warn "k=$k, start_in_col=$start_in_col, start_out_col=$start_out_col\n";
      if ($k + $start_in_col > $in->COLS) {
	$k = $in->COLS - $start_in_col;
      }
      if ($k + $start_out_col > $out->COLS) {
	$k = $out->COLS - $start_out_col;
      }
      #warn "k is now $k\n";
      Math::FastGF2::Matrix::multiply_submatrix_c
	  ($xform, $in, $out,
	   0, 0, $xform->ROWS,
	   $start_in_col, $start_out_col, $k);
      $IFmin -= $want_in_size * $k;
      $OFmax += $want_out_size * $k;
      $IR+=$iright * $k;
      if ($IR > $fillers->[0]->{"END"}) {
	$IR=0;
      }
      $OW+=$oright * $k;
      if ($OW > $emptiers->[0]->{"END"}) {
	$OW=0;
      }
      # printf ("Moving to next column: IFmin, OFmax are (%lld, %lld)\n",
      #	  (long long) IFmin, (long long) OFmax); */

      #warn "Finished processing chunk of $k columns\n";

      # we've been updating IFmin and OFmax, but not the real BF
      # variables in the gf2_streambuf_control structures. We do that
      # after the processing loop is finished.

      if ($k) {
	for ($i=0;  $i < $nfillers; ++$i) {
	  $fillers->[$i]->{"BF"}  -= $k * $want_in_size;
	}
	for ($i=0; $i < $nemptiers; ++$i) {
	  $emptiers->[$i]->{"BF"} += $k * $want_out_size;
	}
      }

    } while ($eof && $OFmax);
  } while (!$eof);

  return $bytes_read;
}

sub ida_rng_init {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my $bytes  = shift;
  my $source = shift || "/dev/urandom";
  my $fh;

  return undef unless ($bytes == 1 or $bytes == 2 or $bytes == 4);

  if ($source eq "rand") {
    my $max=256 ** $bytes;
    return sub { int rand $max };
  }

  return undef unless sysopen $fh, $source, O_RDONLY;

  # Return an anonymous closure to act as an iterator. Calling the
  # iterator will return an integer in the range 0 .. 2^(8*bytes)-1
  my $format;
  if ($bytes == 1) {
    $format="C";
  } elsif ($bytes == 2) {
    $format="S";
  } else {
    $format="L";
  }
  return sub {
    my $deinit=shift;		# passing any args will close the
    my $buf;			# file, allowing the calling program
    if (defined($deinit)) {	# to deallocate the iterator without
      close $fh;		# (possibly) leaving an open, but
      return undef;		# inaccessible file handle
    }
    if ($bytes != sysread $fh,$buf,$bytes) {
      die "Fatal Error: not enough bytes in random source!\n";
    }
    return unpack $format, $buf;
  };
};

sub ida_fisher_yates_shuffle {	# based on recipe 4.15 from the
				# Perl Cookbook
  my $array=shift;

  # Note that this uses plain old rand rather than our high-quality
  # RNG. If that is a problem, either replace this rand with a better
  # alternative or avoid having this function called by using more
  # than 1 byte-security. Since we're using the random variables to
  # generate a permutation, the actual numbers chosen won't be
  # revealed, so it should be a little more difficult for an attacker
  # to guess the sequence used (and hence make better guesses about
  # the random values for the other shares). I can't say either way
  # whether this will be a problem in practice, but it might be a good
  # idea to shuffle the array a second time if attacking rand is a
  # worry. Since an attacker won't have access to all the shares,
  # this should destroy or limit his ability to determine the order in
  # which the numbers were generated. Shuffling a list of high-quality
  # random numbers (such as from the rng_init function) with a
  # poor-quality rand-based shuffle should not leak any extra
  # information, while using two passes with the rand-based shuffler
  # (effectively one to select elements, the other to shuffle them)
  # seems like it should improve security.

  # Change recipe to allow picking a certain number of elements
  my $picks=shift;
  $picks=scalar(@$array) unless
    defined($picks) and $picks >=0 and $picks<scalar(@$array);

  my $i=scalar(@$array);
  while (--$i > $picks - scalar(@$array)) {
    my $j=int rand ($i + 1);	# random int from [0,$i]
    next if $i==$j;		# don't swap element with itself
    @$array[$i,$j]=@$array[$j,$i]
  }
  # If we want fewer picks than are in the full list, then truncate
  # the list by shifting off some elements from the front. This
  # destruction of the list may not be a good thing in general, but
  # it's fine for our purposes in this program. Note that this tail
  # processing effectively brings the algorithm up to O(n), where n is
  # the list length, but we still save out on the more expensive calls
  # to rand and the element-swapping for elements we'll never
  # select. Using mjd-permute might be a marginally better choice
  # where there are many unused elements, but since we're only
  # interested in using this with arrays of up to 256 elements, this
  # will be fine.
  #
  while (scalar(@$array) > $picks) {
    shift @$array;		# using splice() is quicker!
  }
  # splice @$array, 0, scalar @$array - $picks;
};

sub ida_check_key {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my ($k,$n,$w,$key)=@_;

  # Check that key generated by the algorithm (or supplied by the
  # user) has the properties required for linear independence.
  #
  # The key supplied is a list of distinct numbers in the order
  # x1,...,xn,y1,...,yk

  die "No key elements to check\n" unless defined $key;

  die "Supplied key for generating matrix is of the wrong size"
    unless scalar(@$key) == $k + $n;

  my %values;

  # For integer values xi, yj mod a prime p, the conditons that must
  # be satisfied are...
  # xi + yj != 0        |
  # i != j -> xi != xj  } for all i,j
  # i != j -> yi != yj  |
  #
  # For calculations in GF_2, since each number is its own additive
  # inverse, these conditions can be achieved by stating that all
  # numbers must be distinct.
  foreach my $v (@$key) {
    return 1 if $v >= 256 ** $w;
    return 1 if exists($values{$v}); # failure; duplicate value
    $values{$v}=1;
  }
  return 0;			# success; all values distinct
};

sub ida_generate_key {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }

  my ($k,$n,$w,$rng)=@_;
  my $key=[];

  # Generate an array of $k + $n distinct random values, each in the
  # range [0..256**$w)

  # If the width is 1 byte, then we'll use the Fisher-Yates shuffle to
  # choose distinct numbers in the range [0,255]. This takes only
  # O($k+$n) steps and requires O(256) storage. If the width is 2 or
  # more bytes, the Fisher-Yates shuffle would require too much memory
  # (O(2**16), O(2**24), etc.), so we use a different algorithm which
  # uses the rng to generate the numbers directly, checking for
  # duplicates as it goes, and re-rolling whenever dups are found.
  if ($w == 1) {
    push @$key,(0..255);
    ida_fisher_yates_shuffle($key,$k + $n);
  } else {
    my (%rolled,$r);
    my $count=$k+$n;
    while ($count) {
      $r=$rng->();
      next if exists($rolled{$r});
      $rolled{$r}=1;
      push @$key,$r;
      --$count;
    }
  }

  # do a final shuffle of the elements. This should help guard against
  # exploiting weaknesses in either random generator, but particularly
  # the 1-byte version which uses the system's rand function. The
  # extra security derives from the fact that consecutively-generated
  # numbers will likely end up being distributed to different parties,
  # so it should no longer be possible for an attacker to determine
  # the order in which the rng generated them without actually
  # collecting all the shares (which would avoid the need to attack
  # the rng in the first place).
  ida_fisher_yates_shuffle($key);
  return $key;
};

sub ida_check_list {

  # Check a given listref to make sure it has no dups and that all
  # values are within range. Returns the list less any deleted
  # elements, as well as doing an in-place delete on the passed
  # listref.

  my ($list,$item,$min,$max)=@_;

  my $new_list=[];	# list without dups, invalid values
  my @saw_val=((0) x $max);
  for my $i (@$list) {
    if ($saw_val[$i]) {
      carp "Duplicate $item number $i in ${item}list; ignoring";
    } elsif ($i < $min or $i > $max) {
      carp "$item number $i out of range in ${item}list; ignoring.";
    } else {
      ++$saw_val[$i];
      push @$new_list, $i;
    }
  }
  $list=$new_list;
}

sub ida_check_transform_opts {

  # Return 0 for success, or 1 otherwise. Fixes sharelist if it had
  # any duplicate or out-of-range vales

  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my %o= (
	  "quorum"     => undef,
	  "shares"     => undef,
	  "width"      => undef,
	  "sharelist"  => undef,
	  "key"        => undef,
	  "matrix"     => undef,
	  @_);
  my ($k,$n,$w,$sharelist,$key,$mat) =
    map {
      exists($o{$_}) ? $o{$_} : undef;
    } qw(quorum shares width sharelist key matrix);

  if (defined($key) and defined($mat)) {
    carp "both key and matrix parameters supplied; use one only";
    return 1;
  }
  if (defined($key)) {
    unless (defined ($n) and defined ($sharelist)) {
      carp "If a key is supplied, must specify shares and sharelist";
      return 1;
    }
    unless (ref($key) and scalar(@$key) == $k + $n) {
      carp "key must be a reference to a list of $k + $n elements";
      return 1;
    }
  }
  if (defined($mat)) {
    if ( ref($mat) ne "Math::FastGF2::Matrix") {
      carp "Matrix must be of type Math::FastGF2::Matrix";
      return 1;
    }
    if ($mat->ORG ne "rowwise")  {
      carp "supplied matrix must use 'rowwise' organisation";
      return undef;
    }
    if (($mat->ROWS != $n or $mat->COLS != $k)) {
      carp "supplied matrix must be $n rows x $k cols";
      return 1;
    }
  }
  if (defined($sharelist)) {
    ida_check_list($sharelist,"share",0,$n-1);
    unless (scalar(@$sharelist) > 0) {
      carp "sharelist does not contain any valid share numbers; aborting";
      return 1;
    }
  }

  return 0;
}

sub ida_key_to_matrix {
  my ($self,$class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self=shift;
    $class=ref($self);
  } else {
    $self=$classname;
  }
  my %o= (
	  "quorum"      => undef,
	  "shares"      => undef,
	  "width"       => undef,
	  "sharelist"   => undef,
	  "key"         => undef,
	  "invert?"     => 0,	# want us to invert the matrix?
	  "skipchecks?" => 0,	# skip long checks on options?
	  @_,
	 );
  my ($k,$n,$w,$sharelist,$key,$invert,$skipchecks) =
    map {
      exists($o{$_}) ? $o{$_} : undef;
    } qw(quorum shares width sharelist key invert? skipchecks?);

  # skip error checking if the caller tells us it's OK
  unless (defined($skipchecks) and $skipchecks) {
    if (ida_check_transform_opts(%o)) {
      carp "Can't create matrix due to options problem";
      return undef;
    }
  }

  my $mat=Math::FastGF2::Matrix ->
    new(rows => scalar(@$sharelist),
	cols => $k,
	width => $w,
	org => "rowwise");
  unless (defined($mat)) {
    carp "Failed to create transform matrix";
    return undef;
  }
  my $dest_row=0;
  for my $row (@$sharelist) {
    for my $col (0 .. $k-1) {
      my $x   = $key->[$row];
      my $y   = $key->[$n+$col];
      my $sum = $x ^ $y;
      $mat->setval($dest_row, $col, gf2_inv($w << 3,$sum));
    }
    ++$dest_row;
  }
  if (defined($invert) and $invert) {
    return $mat->invert;
  } else {
    return $mat;
  }
}

sub ida_split {
  my ($self, $class);
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my %o=
    (
     quorum => undef,
     shares => undef,
     width => undef,
     # supply either a list of key parameters or a matrix
     key => undef,
     matrix => undef,
     sharelist => undef,
     # source, sinks
     filler => undef,
     emptiers => undef,
     # misc options
     rand => "/dev/urandom",
     bufsize => 4096,
     bytes => 0,
     # byte order flags
     inorder => 0,
     outorder => 0,
     @_,
    );

  # move all options into local variables
  my ($k,$n,$w,$key,$mat,$sharelist,$filler,$emptiers,$rng,
      $bufsize,$inorder,$outorder,$bytes_to_read) =
	map {
	  exists($o{$_}) ? $o{$_} : undef;
	} qw(quorum shares width key matrix sharelist filler
	     emptiers rand bufsize inorder outorder bytes);

  # validity checks
  unless ($w == 1 or $w == 2 or $w == 4) {
    carp "Width must be one of 1, 2, 4";
    return undef;
  }
  unless ($k > 0 and $k < 256 ** $w) {
    carp "Quorum value out of range";
    return undef;
  }
  unless ($n > 0 and $k + $n < 256 ** $w) {
    carp "Number of shares out of range";
    return undef;
  }
  unless (defined ($filler)) {
    carp "Need a filler to provide data";
    return undef;
  }
  unless (ref($emptiers) and scalar(@$emptiers) == $n) {
    carp "emptiers must be a list of $n items (one for each share)";
    return undef;
  }
  unless (defined($bufsize) and $bufsize > 0) {
    carp "Bad bufsize ($bufsize)";
    return undef;
  }
  unless (defined($inorder) and $inorder >= 0 and $inorder <= 2) {
    carp "inorder != 0 (native), 1 (little-endian) or 2 (big-endian)";
    return undef;
  }
  unless (defined($outorder) and $outorder >= 0 and $outorder <= 2) {
    carp "outorder != 0 (native), 1 (little-endian) or 2 (big-endian)";
    return undef;
  }
  # Move some checks to ida_check_transform_opts
  if (ida_check_transform_opts(%o)) {
    carp "Can't proceed due to problem with transform options";
    return undef;
  }

  if (defined($bytes_to_read) and $bytes_to_read < 0) {
    carp "bytes parameter must be 0 (read until eof) or greater";
    return undef;
  }

  if (defined($sharelist)) {

    # moved some checks to ida_check_transform_opts

    if (defined($mat)) {
      # copy only the listed rows into a new matrix
      my $m2=Math::FastGF2::Matrix->new(rows => scalar(@$sharelist),
					cols => $k,
					width => $w,
					org => "rowwise");
      unless (defined($m2)) {
	carp "Problem creating submatrix with rows from sharelist";
	return undef;
      }
      my $dest_row=0;
      for my $row (@$sharelist) {
	for my $col (0 .. $k-1) {
	  $m2->setval($dest_row,$col, $mat->getval($row,$col));
	}
	++$dest_row;
      }
      $mat=$m2;			# replace matrix with reduced one
    }
  } else {
    $sharelist=[0..$n-1];
  }

  unless (defined($mat)) {
    if (defined ($key)) {
      if (ida_check_key($k,$n,$w,$key)) {
	carp "Problem with supplied key";
	return undef;
      }
    } else {
      # no key and no matrix, so generate random key
      $rng=ida_rng_init($w,$rng);
      unless (defined($rng)) {
	carp "Failed to initialise random number generator";
	return undef;
      }
      $key=ida_generate_key($k,$n,$w,$rng);
    }

    # now generate matrix from key
    $mat=ida_key_to_matrix( "quorum"      => $k,
			    "shares"      => $n,
			    "width"       => $w,
			    "sharelist"   => $sharelist,
			    "key"         => $key,
			    "skipchecks?" => 0);
  }

  # create the buffer matrices and start the transform
  my $in = Math::FastGF2::Matrix->new(rows=>$k,
				      cols=>$bufsize,
				      width=>$w,
				      org => "colwise");
  my $out= Math::FastGF2::Matrix->new(rows=>scalar(@$sharelist),
				      cols=>$bufsize,
				      width=>$w,
				      org => "rowwise");
  unless (defined($in) and defined($out)) {
    carp "failed to allocate input/output buffer matrices";
    return undef;
  }
  my $rc=ida_process_streams($mat,
			     $in, [$filler],
			     $out, $emptiers,
			     $bytes_to_read,
			     $inorder, $outorder);
  if (defined ($rc)) {
    return ($key,$mat,$rc);
  } else {
    return undef;
  }
}

sub ida_combine {
  my $self;
  my $class;
  if ($_[0] eq $classname or ref($_[0]) eq $classname) {
    $self  = shift;
    $class = ref($self) || $self;
  } else {
    $self=$classname;
    $class=$classname;
  }
  my %o=
    (
     quorum => undef,
     shares => undef,   # only needed if key supplied
     width => undef,
     # supply either a list of key parameters and a list of keys or a
     # pre-inverted matrix generated from those key details
     key => undef,
     matrix => undef,
     sharelist => undef,
     # source, sinks
     fillers => undef,
     emptier => undef,
     # misc options
     bufsize => 4096,
     bytes => 0,
     # byte order flags
     inorder => 0,
     outorder => 0,
     @_,
    );

  # copy all options into local variables
  my ($k,$n,$w,$key,$mat,$sharelist,$fillers,$emptier,
      $bufsize,$inorder,$outorder,$bytes_to_read) =
	map {
	  exists($o{$_}) ? $o{$_} : undef;
	} qw(quorum shares width key matrix sharelist fillers
	     emptier  bufsize inorder outorder bytes);

  # validity checks
  unless ($w == 1 or $w == 2 or $w == 4) {
    carp "Width must be one of 1, 2, 4";
    return undef;
  }
  unless ($k > 0 and $k < 256 ** $w) {
    carp "Quorum value out of range";
    return undef;
  }
  unless (ref($fillers) and scalar(@$fillers) == $k) {
    carp "fillers must be a list of $k items (one for each share)";
    return undef;
  }
  unless (defined($emptier)) {
    carp "need an emptier to write data to";
    return undef;
  }
  unless (defined($bufsize) and $bufsize > 0) {
    carp "Bad bufsize";
    return undef;
  }
  unless (defined($inorder) and $inorder >= 0 and $inorder <= 2) {
    carp "inorder ($inorder) != 0 (native), ".
      "1 (little-endian) or 2 (big-endian)";
    return undef;
  }
  unless (defined($outorder) and $outorder >= 0 and $outorder <= 2) {
    carp "outorder ($outorder) != 0 (native), ".
      "1 (little-endian) or 2 (big-endian)";
    return undef;
  }
  if (defined($key)) {
    if (ida_check_key($k,$n,$w,$key)) {
      carp "Invalid key supplied";
      return undef;
    }
  } else {
    $o{"shares"}=$k;		# needed for ida_check_transform_opts
    $n=$k;
  }
  if (ida_check_transform_opts(%o)) {
    carp "Can't continue due to problem with transform opts";
    return undef;
  }
  if (defined($bytes_to_read) and $bytes_to_read < 0) {
    carp "bytes parameter must be 0 (read until eof) or greater";
    return undef;
  }

  if (defined($key)) {
    ida_check_list($sharelist,"share",0,$k-1);
    unless (scalar(@$sharelist) == $k) {
      carp "sharelist does not have k=$k elements";
      return undef;
    }
    #warn "Creating and inverting matrix from key\n";
    $mat=ida_key_to_matrix(%o, "skipchecks?" => 0, "invert?" => 1);
    unless (defined($mat)) {
      carp "Failed to invert transform matrix (this shouldn't happen)";
      return undef;
    }
  }

  # create the buffer matrices and start the transform
  my $in = Math::FastGF2::Matrix->new(rows=>$k,
				      cols=>$bufsize,
				      width=>$w,
				      org => "rowwise");
  my $out= Math::FastGF2::Matrix->new(rows=>$k,
				      cols=>$bufsize,
				      width=>$w,
				      org => "colwise");
  unless (defined($in) and defined($out)) {
    carp "failed to allocate input/output buffer matrices";
    return undef;
  }
  my @vals=$mat->getvals(0,0,$k * $n);
  #warn "matrix is [" . (join ", ", map
  #			{sprintf("%02x",$_) } @vals) . "] (" .
  #		  scalar(@vals) . " values)\n";

  return ida_process_streams($mat,
			     $in, $fillers,
			     $out, [$emptier],
			     $bytes_to_read,
			     $inorder, $outorder);

}


1;
__END__

=head1 NAME

Crypt::IDA - Michael Rabin's Information Dispersal Algorithm

=head1 SYNOPSIS

  use Crypt::IDA ":default";

  $source=fill_from_string ($string,$align);
  $source=fill_from_fh     ($fh,$align,$offset);
  $source=fill_from_file   ($filename,$align,$offset);
  $sink=empty_to_string    (\$string);
  $sink=empty_to_fh        ($fh,$offset);
  $sink=empty_to_file      ($filename,$mode,$offset);
  ($key,$mat,$bytes) = ida_split ( ... );
  $bytes             = ida_combine ( ... );

=head1 DESCRIPTION

This module splits a secret into one or more "shares" which have the
property that if a certain number of shares (the "quorum" or
"threshold") are presented in the combine step, the secret can be
recovered. The algorithm should be cryptographically secure in the
sense that if fewer shares than the quorum are presented, no
information about the secret is revealed.

=head2 EXPORT

No methods are exported by default. All methods may be called by
prefixing the method names with the module name, eg:

 $source=Crypt::IDA::fill_from_string($string,$align)

Alternatively, routines can be exported by adding ":default" to the
"use" line, in which case the routine names do not need to be prefixed
with the module name, ie:

  use Crypt::IDA ":default";
  
  $source=fill_from_string ($string,$align);
  # ...

Some extra ancillary routines can also be exported with the ":extras"
(just the extras) or ":all" (":extras" plus ":default") parameters to
the use line. See the section L<ANCILLARY ROUTINES> for details.

=head1 GENERAL OPERATION

=head2 Naming conventions

The following variable names will be used throughout this
documentation:

  $n        number of shares to create
  $k        number of shares needed to combine (ie, the "quorum")
  $w        width (treat input/output as being 1, 2 or 4-byte words)
  $align    null-pad input up a multiple of $align bytes
  $key      key parameter used to create transform matrix
  $mat      transform matrix/inverse transform matrix

=head2 Stream-processing design pattern

Rather than implement separate C<ida_split_string> or
C<ida_split_file> methods, a more flexible design which decouples the
details of the input and output streams from the actual processing is
used. In terms of design patterns, the C<ida_split> and C<ida_combine>
routines operate as stream processors, and use user-supplied callbacks
to read some bytes of input or write some bytes of output. Therefore,
the split and combine tasks break down into three steps:

=over

=item 1. Set up fill handler(s)

=item 2. Set up empty handler(s)

=item 3. Call processing routine (ida_split/ida_combine)

=back

For the C<ida_split> routine, a single "fill" handler is required,
while one or more "empty" handlers are required (one for each share to
be output). For the C<ida_combine> routine, the opposite is true: one
or more "fill" handlers are required (corresponding to the shares to
be combined), while a single "empty" handler (for the recombined
secret) is required.

The C<fill_from_*> and C<empty_to_*> routines create callbacks which
can be used by C<ida_split>/C<ida_combine>. Routines are provided for
creating callbacks given a string, filename or open file
handle. Custom callbacks (such as for reading/writing on a network
socket connection or an IPC message queue) can also be written quite
easily. See the section L<Writing Custom Callbacks> for more details.

=head2 Keys and transform matrices

Both the split and combine algorithms operate by performing matrix
multiplication over the input. In the case of the split operation, the
transform matrix has n rows (n=number of shares) and k columns
(k=quorum), while in the case of combine operation, the transform
matrix has k rows and k columns. Either operation is described simply
as the matrix multiplication:

 transform x input = output

The input matrix always has k rows, while the output matrix will have
n rows for the split operation, or k rows for the combine
operation. Both input and output matrices will have a number of
columns related to the length of the secret being
split/combined. (Actually, in this implementation, the number of
columns in the input/output matrix is unimportant, since the matrices
are treated as circular buffers with columns being reused when
necessary, but the general idea still stands).

The transform matrix must have the property that any subset of k rows
represent linearly independent basis vectors. If this is not the case
then the transform cannot be reversed. This need not be a concern for
most users of this module, since if the ida_split routine is not
provided a transform matrix parameter, it will generate one of the
appropriate form, which guarantees (in the mathematical sense) that
the process is reversible. However, understanding the requirement of
linear independence is important in case a user-supplied matrix is
provided, and also for understanding the "key" parameter to the
split/combine routines. A "key" is defined as a list of field elements
(ie, 8-bit, 16-bit or 32-bit values):

 x , x ,  ... , x , y , y , ... , y
  1   2          n   1   2         k

whose values must all be distinct. If a key is supplied to the split
routine, these values are used to create a Cauchy-form transform
matrix:

              k columns
 
 |     1        1             1     |
 |  -------  -------  ...  -------  |
 |  x1 + y1  x1 + y2       x1 + yk  |
 |                                  |
 |     1        1             1     |
 |  -------  -------  ...  -------  |
 |  x2 + y1  x2 + y2       x2 + yk  |  n rows
 |                                  |
 |     :        :      :      :     |
 |                                  |
 |     1        1             1     |
 |  -------  -------  ...  -------  |
 |  xn + y1  xn + y2       xn + yk  |

This matrix has the desired property that any subset of k rows are
linearly independent, which leads to the property that the transform
can be reversed (via being able to create an inverse matrix from those
k rows). The actual requirements for a Cauchy-form matrix are slightly
more complicated than saying that all xi, yi values be distinct, but
they reduce to exactly that for Galois Fields.

If the same key is supplied to the combine routine (along with a list
of rows to be created), the appropriate submatrix is generated and
inverted. This inverted matrix is then used as the transform matrix
for the combine algorithm.

For more information, see the sections for L<KEY MANAGEMENT>, 
L<SPLIT OPERATION>, L<COMBINE OPERATION> and the L<SEE ALSO> section.

=head1 FILL/EMPTY CALLBACKS

=head2 "Fill" Callbacks

Fill callbacks are created by a call to one of:

 $source=fill_from_string ($string,$align);
 $source=fill_from_fh     ($fh,$align,$offset);
 $source=fill_from_file   ($filename,$align,$offset);

The C<$string>, C<$fh> and C<$filename> parameters should be
self-explanatory. The $offset parameter, where supplied, specifies an
offset to seek to in the file/file handle I<before> any reading takes
place. The C<$offset> parameter may be omitted, in which case it
defaults to 0, i.e., the start of the file.

The $align parameter specifies that the input is to be null-padded up
to a multiple of $align bytes, should it not already be so-aligned.
The C<ida_split> routine requires that the input be a multiple of C<$k
* $w> bytes in length, so this is the usual value to pass for the
C<$align> parameter. If C<$align> is not specified, it defaults to 1,
meaning the input is byte-aligned, and no padding bytes will be placed
at the end of the file/string. Also note that if an C<$align>
parameter is used in conjunction with the C<$offset> parameter, that
the input will be aligned to be a multiple of C<$align> bytes
starting from I<$offset>, and not from the start of the file.

Also, be aware that if the input secret needs to be padded before
calling C<ida_split> that you will need to have some way of removing
those padding bytes after recovering the secret with C<ida_combine>.
This can be accomplished by removing null bytes from the end of the
secret (provided trailing nulls in the original secret are
prohibited), or (as is preferable for splitting/combining binary
files), by recording the original (unpadded) size of the secret and
truncating the reconstituted secret down to that size after calling
C<ida_combine>.

=head2 "Empty" Callbacks

The following routines are available for creating "empty" callbacks:

  $sink=empty_to_string    (\$string);
  $sink=empty_to_fh        ($fh,$offset);
  $sink=empty_to_file      ($filename,$perm,$offset);

All parameters with the same name are the same as in the "fill"
callbacks. Additionally, note that:

=over

=item * empty_to_string requires a I<reference> to a string variable
(to enable the callback to modify the string);

=item * empty handlers do not pad the output stream, so they don't
need an C<$align> parameter; and

=item * empty_to_file takes a C<$perm> (file permission) parameter,
which defaults to 0644 if not specified.

=back

As with the fill handler routines, these routines return a hash
reference (which contains the actual callback) if successful, or undef
if there was a problem (in which case file-related problems will be
reported in $!).

The empty_to_file routine will create the output file if it does not
already exist.

=head1 SPLIT OPERATION

The template for a call to C<ida_split>, showing all default values,
is as follows:

 ($key,$mat,$bytes) = ida_split (
     quorum => undef,
     shares => undef,
     width => undef,      # operate on words of 1, 2 or 4 bytes
     # supply a key, a matrix, or  neither (in
     # which case a key will be randomly generated)
     key => undef,
     matrix => undef,
     # optionally specify which shares to produce
     sharelist => undef,  # [ $row1, $row2, ... ]
     # source, sinks
     filler => undef,
     emptiers => undef,   # [ $empty1, $empty2, ... ]
     # misc. options
     rand => "/dev/urandom",
     bufsize => 4096,
     bytes => 0,
     # byte order flags
     inorder => 0,
     outorder => 0,
 );

Many of the parameters above have already been described earlier.  The
new parameters introduced here are:

=over

=item * If the key and matrix parameters are unset, then a random
key/transform matrix will be generated and used to create the
shares. For a discussion of cases where you might want to override
this behaviour and supply your own values for these parameters, see
the L<Keys and transform matrices> and L<KEY MANAGEMENT> sections.

=item * sharelist is a reference to a list of rows to be operated on;
if specified, only shares corresponding to those rows in the transform
matrix will be created.

=item * emptiers is a reference to a list of empty callbacks. The list
should contain one empty callback for each share to be produced.

=item * rand can be set to "rand", in which case Perl's default
C<rand()> function will be used for generating keys. Otherwise, the
parameter is taken to be a file containing the random number to be
used (C</dev/urandom> and C</dev/random> are special devices on Linux
systems which generate different random numbers each time they are
read; see their man pages for details).

=item * bufsize specifies the size of the input and output buffer
matrices in terms of the number of columns. Any integer value greater
than 0 is allowed. Larger buffer size should improve the performance
of the algorithm, as fewer I/O calls and matrix multiply calls (on
larger chunks of data) will be required.

=item * bytes specifies how many bytes of input to read. This may be
set to zero to indicate that all bytes up to EOF should be read. This
value must be a multiple of quorum x width

=item * inorder and outorder can be used to specify the byte order of
the input and output streams, respectively. The values can be set to 0
(stream uses native byte order), 1 (stream uses little-endian byte
order) or 2 (stream uses big-endian byte order). If these values are
set to 1 or 2 and that byte order is different from the system's byte
order then bytes within words will be swapped to the correct order
before being written to the input buffer or written out from the
output buffer. These options have no effect when the width is set to 1
byte.

=back

The function returns three return values, or undef if there was an
error. The return values are:

=over

=item * C<$key>, which will be undef if the user supplied a matrix
parameter, or the value of the key used to create the transform matrix
otherwise

=item * C<$mat>, which is the matrix used to create the shares. If the
user specified a sharelist option, then this returned matrix will
include only the rows of the transform matrix specified in the
sharelist (in the order specified).

=item * C<$bytes>, which is the number of input bytes actually read
from the input.

=back

Since the "key" parameter may not be returned in all cases, the
preferred method for detecting failure of the routine is to check
whether the C<$mat> parameter returns undef, as in the following:

 ($key,$mat,$bytes) = ida_split ( ... );
 unless (defined ($mat)) {
  # handle ida_split failure
  # ...
 }

This should work in all cases, regardless of whether a key or matrix
was supplied or automatically generated.

=head1 COMBINE OPERATION

The template for a call to C<ida_combine> is as follows:

 $bytes_read = ida_combine (
     quorum => undef,
     width => undef,
     shares => undef,     # use in conjunction with key
     # supply either a key or a pre-inverted matrix
     key => undef,
     matrix => undef,
     sharelist => undef,  # use in conjunction with key
     # sources, sink
     fillers => undef,    # [$filler1, $filler2, ... ]
     emptier => undef,
     # misc options
     bufsize => 4096,
     bytes => 0,
     # byte order flags
     inorder => 0,
     outorder => 0,
 );

Most options should be obvious, but note:

=over

=item * fillers should be a reference to a list of k fill handlers,
corresponding to the shares to be combined

=item * if a matrix is supplied, it must be the inverse of some
submatrix (some k rows) of the original transform matrix; the
C<ida_combine> routine I<does not> invert a supplied matrix.

=item * if a key parameter is supplied, both the shares parameter and
sharelist parameter must be given

=item * shares is the total number of shares that were created when
calling C<ida_split>. This is required when passing a key parameter in
order to facilitate error checking, since it provides a means of
checking which values in the key should represent x_i values, and
which should represent y_i values.

=item * sharelist is also required when a key is passed, as otherwise
the routine does not know which k shares are being combined. The
sharelist parameter should be a list of k distinct row numbers. Also,
each element in the sharelist array should match up to the appropriate
element in the fillers array.

=item * if a key parameter is supplied, the C<ida_combine> routine
will generate the appropriate transform matrix I<and its inverse> (in
contrast to the case where a matrix parameter is supplied).

=back

The return value is the number of bytes actually written to the output
stream, or undef if there was an error. As noted earlier, this value
may be larger than the initial size of the secret due to padding to
align the input to quorum x width bytes. Strategies for dealing with
this have also been discussed.

=head1 ANCILLARY ROUTINES

The extra routines are exported by using the ":extras" or ":all"
parameter with the initial "use" module line. With the exception of
key-generation and key-testing routines, these will probably not be
needed for most applications. The extra routines are as follows:

 $rng=ida_rng_init($bytes,$source)
 $val=$rng->();			# get a new random value
 $rng->("anything");		# decommision $rng

This routine initialises a source of random numbers. The $bytes
parameter should be 1, 2 or 4. The (optional) $source parameter has
the same semantics as the "random" parameter to C<ida_split> (ie, use
"rand" or the name of a file to read random bytes from).

 ida_fisher_yates_shuffle(\@list,$howmany);

Shuffles elements of C<@list1> and (optionally) deletes all but
$howmany of those elements. Shuffling (and deletion) is done in-place
on the passed list.

 $keyref=ida_generate_key($k, $n, $w, $rng);

Generates a new random key. All parameters are required. Result is a
reference to a list of $k + $n distinct elements.

 if (ida_check_key($keyref)) {
   # check of key failed
   # ...
 }

Takes a reference to a list of $k + $n elements and checks that the
list is a valid key. Returns 0 to indicate that the key is valid.

=head1 KEY MANAGEMENT

The C<ida_split> routine takes a secret and creates several "shares"
from it. However, unless information about the contents of the
original transform matrix (or the "key" from which it is derived) is
available, it will be impossible to reconstruct the secret from these
shares at a later time. This module does not implement any particular
key management strategy. It is up to the application using the module
to implement their own key management strategy by saving information
about the transform matrix (or key) either passed into or returned
from the call to C<ida_split>. Broadly speaking, there are two
approaches which may be used:

=over

=item 1. Caller creates/saves the $key parameter at a secure central
location, and associates each of the created shares with a row number
(0 .. $n-1); or

=item 2. Caller creates/saves the 'matrix' parameter/$mat return value
and stores an association between each share and the corresponding row
of that matrix.

=back

In the first approach, a central authority is required to securely
store the key (in either $key or $mat forms). This will mitigate
against fully exploiting the "Distributed/Dispersed" part of the
algorithm, though, since the protocol has a single point of
failure/attack and the central authority is required to reconstruct
the secret.

In the second approach, the matrix rows can be effectively associated
with the shares by transmitting them to each recipient shareholder
I<along with> the shares themselves. Shareholders can then
reconstruct the secret without the participation of the Dealer (the
creator of the shares).

An implementation of the second approach (sans any distribution
mechanism) is provided in the Crypt::IDA::ShareFile module.

=head2 Adding extra shares at a later time

Adding extra shares to an IDA system is possible, and might be
desireable if the goal is to increase the level of redundancy of
stored data. If the Dealer keeps a copy of the original key, then it
is possible to create extra shares at a later time. It is, however,
impossible to modify the quorum value without destroying all shares
and recreating the threshold system with the new quorum value. In
order to add new shares at a later time, it is also assumed that the
Dealer continues to have access to the secret.

The procedure for adding a share is to randomly determine a new value
x_n+1 which is different from any existing x_i, y_i, and to insert it
into the correct position in the key list, ie:

 x , x ,  ... , x , x   , y , y , ... , y
  1   2          n   n+1   1   2         k

The new key can be passed to C<ida_split> in order to create the new
share (or shares; several new x-values may be inserted). The
C<sharelist> option may be passed to C<ida_split> to instruct the
routine to create only the new shares, and avoid re-creating any
existing shares.

If the original matrix was stored, but not the key which it was
created from, the situation is more complex. Creating new shares can
be accomplished by creating a new matrix row, and then testing that
each subset of k rows from this new matrix are linearly independent
(eg, by proving that each of the submatrices can be inverted). This
module does not implement such a feature, so it is up to the user to
provide their own code to do this, should it be required.
Alternatively, consider storing the key instead of the resulting
matrix, as above.

=head2 In the event of lost or stolen shares

The security of this system relies on an attacker not being able to
collect k shares. If some shares are lost or thought to have been
stolen (or copied), then the security of the secret may be at
risk. This is not a matter of insecurity in the algorithm. Rather, it
increases the risk since an attacker (who may be a shareholder) now
potentially has to find or steal fewer shares in order to reconstruct
the secret. In cases like this, the pragmatic approach will be to
destroy any existing shares of the secret and to recreate a new set of
shares and distribute them to the shareholders. Different parameters
for the quorum and number of shares may be chosen at this time, as may
the distribution of shares among shareholders.

=head1 TECHNICAL DETAILS

This section is intended mainly for the curious: mainly those wishing
to extend the module or write code which can inter-operate with the
implementation presented here.

=head2 Field implementation

All operations are carried out by treating input bytes/words as being
polynomials in GF(2^8), GF(2^16) or GF(2^32). The implementation of
arithmetic in these fields is handled by the Math::FastGF2 and
Math::FastGF2::Matrix modules. The irreducible field polynomials used
by those modules are:

                8    4    3
   GF(2^8)     x  + x  + x  + x + 1     (0x11b)
 
                16    5    3
   GF(2^16)    x   + x  + x  + x  + 1   (0x1002b)
 
                32    7    3    2
   GF(2^32)    x   + x  + x  + x  + 1   (0x10000008d)

Anyone wishing to implement compatible encoders/decoders should ensure
that the polynomials used in their implementation match these.

=head2 Reed-Solomon Encoding

Although this module was not written specifically with Reed-Solomon
Erasure Codes in mind, the underlying arithmetic and matrix
multiplication is the same as Rabin's IDA. The module can, with a
little work, be made to work as a Reed-Solomon encoder/decoder. The
basic idea (which may be implemented in a future release) is to first
create either a Cauchy-form matrix as described above, or a
Vandermonde matrix of the following form:

 |     0    1    2          k-1  |
 |    0    0    0   ...    0     |
 |                               |
 |     0    1    2          k-1  |
 |    1    1    1   ...    1     |
 |                               |
 |    :    :    :    :     :     |
 |                               |
 |     0    1    2          k-1  |
 |  n-1  n-1  n-1   ...  n-1     |

All arithmetic operations should, of course, be performed on Galois
Field elements, rather than integers. Whichever matrix form is chosen,
the next step is to use elementary column operations on the matrix
until the top k rows form an identity matrix (again, all arithmetic
must treat the numbers as Galois Field polynomials). The matrix can
then be passed along to C<ida_split>, which will generate n shares as
usual, with the first k of these being unencrypted slices of the
original file (ie, containing every k'th character/word, starting at
offset 0, 1, ... , k-1) with the remaining n - k shares being the
Erasure Codes. As with Rabin's scheme, any k of the shares may be
presented to C<ida_combine> (along with the appropriate inverse matrix
calculated from k rows of the split transform matrix) to reconstruct
the original file.

=head2 Writing Custom Callbacks

The following code can be used as a template for writing routines
which create fill/empty callbacks which can be passed to C<ida_split>
and C<ida_combine>:

 sub create_my_ida_callback {
   my ($arg1, $arg2, ... ) = @_;

   # do some initialisation based on args, such as opening files,
   # connecting to a database, saving details of an IPC message queue,
   # etc.
 
   # for "fill" callbacks:
   return {
	   SUB => sub {
	     my $len=shift;
	     my $string;

             # some code to get/produce up to $len bytes of input and
             # place it in $string.  Since this is a closure, the
             # callback has access to the initial $arg1, $arg2 and any
             # other variables created in the enclosing routine.

	     if ($some_error_occurred) {
	       return undef;
	     } elsif ($no_more_input) {
	       return "";
	     } else {
	       return $string;
	     }
           },
	  };
 
   # for "empty" callbacks:
   return {
	   SUB => sub {
	     my $string=shift;

             # some code to save/consume new data bytes passed in
             # $string. The routine should return the number of bytes
             # actually processed, or undef if there was a (write)
             # error.

	     if ($some_error_occurred) {
	       # optionally set $! with error message
	       return undef;
	     } else {
	       return $number_of_bytes_actually_saved;
	     }
           },
	  };
 }

Note that callbacks are written using Perl's closure mechanism rather
than by passing simple code (subroutine) references. This is done to
allow the callback to be "customised" to use a particular file handle,
string, etc., as input or output. See the L<What's a closure?> section
in the Perl FAQ for more details on this construct. Also, a hashref is
used rather than a simple coderef since the processing routines use
that hash to store bookkeeping information such as buffer fill levels,
read/write pointers and so on.

The C<ida_split> and C<ida_combine> routines are written in such a way
that they handle most of the logic involved with buffering of input
and output and the details of reading/writing values in the
input/output matrices.  This means that callbacks can usually be kept
very simple and, for the most part, stateless. Specifically, if an
empty handler cannot process all bytes of input presented to it in one
call, it simply returns the number of bytes it actually
processed. There is no need for it to save any unprocessed part of the
input, and doing so will probably result in an error. Since the
calling routines know how many unprocessed bytes remain in the output
buffer, it will arrange so that the next time that particular empty
handler is called, it will receive those unprocessed bytes at the
start of its input string.

The one exception to this "stateless" operation is in the case where a
fill handler must pad the input stream to be a multiple of $align
bytes. This can be accomplished by either pre-padding the input stream
in the callback initialisation phase (when the stream length is known
in advance, such as with a string input), or by maintaining "bytes
read" and "EOF" state variables, updating them after every call to the
callback, and using them to return extra padding bytes after the
stream's natural end-of-file, where appropriate.

Please consult the source code for the existing C<fill_from_*> and
C<empty_to_*> callback creation code for working examples.

=head1 KNOWN BUGS

There may be a weakness in the current implementation of the random
key generation routine when a 1-byte word size is used, in that
regardless of the random-number generator parameter passed to
C<ida_split>, the routine will always use Perl's internal C<rand()>
function. The code currently includes a workaround which should at
least prevent a sequence-prediction attack on the RNG. While I can see
no way to effectively attack the current implementation (due to the
security afforded by the simple act of dispersing shares), it is
clearly desirable to use the highest-quality RNG available in all
cases, and this should be implemented in a future release. For the
moment, if the possibility of a weakness in this implementation is
unacceptable, it can be avoided simply by using a width parameter of 2
or 4, in which cases the high-quality RNG will always be used.

On a related note, defaulting to the use of C</dev/urandom> instead of
C</dev/random> may be considered a bug by some people.

=head1 SEE ALSO

I<"Efficient dispersal of information for security, load balancing,
and fault tolerance">, by Michael O. Rabin. JACM Volume 36, Issue 2
(1989).

Description of the Information Dispersal Algorithm, which this module
implements. This should be a faithful implementation of the original
idea, although the issue of padding is not covered sufficiently in the
paper, and this may be a point of divergence from the original
intention.

I<http://parchive.sourceforge.net/>

A similar project, in that it uses 16-bit Galois Field arithmetic to
perform the same kinds of arithmetic operations on input files. The
polynomial used in parchive (0x1100b) is different from the one used
here (0x1002b), however. Also, parchive uses the more traditional
Reed-Solomon mode of operation, with an emphasis on forward
error-correction, whereas this module focuses more on the creation of
distributed shares in order to achieve secure distribution of a
secret.

I<http://www.cs.utk.edu/~plank/plank/papers/SPE-9-97.html> "A Tutorial
on Reed-Solomon Coding for Fault-Tolerance in RAID-like Systems", by
James S. Plank.

The description of the use of a particular Vandermonde matrix to
guarantee linear independence of each row in the transform matrix (as
described above) is due to a later erratum to this paper. My
description of Reed-Solomon coding in general also follows this
paper. The use of Cauchy-form matrices for guaranteeing linear
independence (in both IDA and RS modes) also seems to be widely-known
as well.

=head1 FUTURE VERSIONS

It is likely that the following changes/additions will be made in
future versions:

=over

=item * Add support for producing Reed-Solomon Erasure Codes using the
method described earlier.

=item * Update the matrix processing code so that it can detect when
padding of input is required and handle it by itself. The changes
required to implement this can be made in such a way as to preserve
compatibility with any code implemented using the current semantics.

=item * Offer the choice of padding input with random padding rather
than null padding. While it's beyond the scope of this document to
present an analysis of the algorithm from a cryptographic standpoint,
it may be possible that padding with predictable zero bytes may weaken
the security of this implementation. Padding with random data should
remove that potential weakness.

=item * Force or give the option of always using the highest-quality
RNG available (see L<KNOWN BUGS>).

=item * Give the option of using other RNG sources (such as for
inferior platforms which do not have an equivalent of /dev/[u]random)

=back

=head1 AUTHOR

Declan Malone, E<lt>idablack@sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Declan Malone

This package is free software; you can redistribute it and/or modify
it under the terms of version 2 (or, at your discretion, any later
version) of the "GNU General Public License" ("GPL").

Please refer to the file "GNU_GPL.txt" in this distribution for
details.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
