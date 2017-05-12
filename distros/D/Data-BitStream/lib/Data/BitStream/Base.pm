package Data::BitStream::Base;
use strict;
use warnings;
use Carp;
BEGIN {
  $Data::BitStream::Base::AUTHORITY = 'cpan:DANAJ';
  $Data::BitStream::Base::VERSION   = '0.08';
}

our $CODEINFO = [ { package   => __PACKAGE__,
                    name      => 'Unary',
                    universal => 0,
                    params    => 0,
                    encodesub => sub {shift->put_unary(@_)},
                    decodesub => sub {shift->get_unary(@_)},
                  },
                  { package   => __PACKAGE__,
                    name      => 'Unary1',
                    universal => 0,
                    params    => 0,
                    encodesub => sub {shift->put_unary1(@_)},
                    decodesub => sub {shift->get_unary1(@_)},
                  },
                  { package   => __PACKAGE__,
                    name      => 'BinWord',
                    universal => 0,
                    params    => 1,
                    encodesub => sub {shift->put_binword(@_)},
                    decodesub => sub {shift->get_binword(@_)},
                  },
                ];

use Moo::Role;
use MooX::Types::MooseLike::Base qw/Int Bool Str ArrayRef/;

# pos is ignored while writing
has 'pos'     => (is => 'ro', writer => '_setpos', default => sub{0});
has 'len'     => (is => 'ro', writer => '_setlen', default => sub{0});
has 'mode'    => (is => 'rw', default => sub{'rdwr'});
has '_code_pos_array' => (is => 'rw',
                          isa => ArrayRef[Int],
                          default => sub {[]} );
has '_code_str_array' => (is => 'rw',
                          isa => ArrayRef[Str],
                          default => sub {[]} );

has 'file'         => (is => 'ro', writer => '_setfile');
has 'fheader'      => (is => 'ro', writer => '_setfheader');
has 'fheaderlines' => (is => 'ro');

has 'writing' => (is => 'ro', isa => Bool, writer => '_setwrite', default => sub {1});

# Useful for testing, but time consuming.  Not so bad now that all the test
# suites call put_*  ~30 times with a list instead of per-value ~30,000 times.
# It still makes the test suite take about 20% longer.
#
# after '_setpos' => sub {
#   my $self = shift;
#   my $pos = $self->pos;
#   my $len = $self->len;
#   die "position must be >= 0" if $pos < 0;
#   die "position must be <= length" if $pos > $len;
#   $pos;
# };

sub BUILD {
  my $self = shift;

  # Looks like some systems aren't setting these correctly via the default.
  # I cannot reproduce the issue even with the same versions of Perl, Moo,
  # and Class::XSAccessor.  So, we'll set them here.
  $self->_code_pos_array([]);
  $self->_code_str_array([]);
  $self->_setpos(0);
  $self->_setlen(0);

  # Change mode to canonical form
  my $curmode = $self->mode;
  my $is_writing;
  if    ($curmode eq 'read')      { $curmode = 'r'; }
  elsif ($curmode eq 'readonly')  { $curmode = 'ro'; }
  elsif ($curmode eq 'write')     { $curmode = 'w'; }
  elsif ($curmode eq 'writeonly') { $curmode = 'wo'; }
  elsif ($curmode eq 'readwrite') { $curmode = 'rw'; }
  elsif ($curmode eq 'rdwr')      { $curmode = 'rw'; }
  elsif ($curmode eq 'append')    { $curmode = 'a'; }
  die "Unknown mode: $curmode" unless $curmode =~ /^(?:r|ro|w|wo|rw|a)$/;
  $self->mode( $curmode );

  # Set writing based on mode
  if    ($curmode =~ /^ro?$/) { $is_writing = 0; }
  elsif ($curmode =~ /^wo?$/) { $is_writing = 1; }
  elsif ($curmode eq 'rw')    { $is_writing = 1; }
  elsif ($curmode eq 'a')     { $is_writing = 0; }

  if ($is_writing) {
    $self->_setwrite(1);
    $self->write_open;
  } else {
    $self->_setwrite(0);
    $self->read_open;
  }

  $self->write_open if $curmode eq 'a';
  # TODO: writeonly doesn't really work
}

sub DEMOLISH {
  my $self = shift;
  $self->write_close if $self->writing;
}

my $_host_word_size;    # maxbits
my $_all_ones;          # maxval

BEGIN {
  use Config;
  $_host_word_size =
   (   (defined $Config{'use64bitint'} && $Config{'use64bitint'} eq 'define')
    || (defined $Config{'use64bitall'} && $Config{'use64bitall'} eq 'define')
    || (defined $Config{'longsize'} && $Config{'longsize'} >= 8)
   )
   ? 64
   : 32;
  no Config;

  # Check sanity of ~0
  my $notzero = ~0;
  if ($_host_word_size == 32) {
    die "Config says 32-bit Perl, but int is $notzero" if ~0 != 0xFFFFFFFF;
  } else {
    die "Config says 64-bit Perl, but int is $notzero" if ((~0 >> 16) >> 16) != 0xFFFFFFFF;
  }

  # 64-bit seems broken in Perl 5.6.2 on the 32-bit system I have (and at
  # least one CPAN Tester shows the same).  Try:
  #     perl -e 'die if 18446744073709550593 == ~0'
  # That inexplicably dies on 64-bit 5.6.2.  It works fine on 5.8.0 and later.
  #
  # Direct method, pre-5.8.0 Perls.
  #   $_host_word_size = 32 if $] < 5.008;
  # Detect the symptoms (should allow 5.6.2 on 64-bit O/S to work fine):
  if ( ($_host_word_size == 64) && (18446744073709550592 == ~0) ) {
    $_host_word_size = 32;
  }

  $_all_ones = ($_host_word_size == 32) ? 0xFFFFFFFF : ~0;
}
# Moo 1.000007 doesn't allow inheritance of 'use constant'.
#use constant maxbits => $_host_word_size;
#use constant maxval  => $_all_ones;
# Use a sub with empty prototype (see perlsub documentation)
sub maxbits () { $_host_word_size }  ## no critic (ProhibitSubroutinePrototypes)
sub maxval  () { $_all_ones }        ## no critic (ProhibitSubroutinePrototypes)

sub rewind {
  my $self = shift;
  $self->error_stream_mode('rewind') if $self->writing;
  $self->_setpos(0);
  1;
}
sub skip {
  my $self = shift;
  $self->error_stream_mode('skip') if $self->writing;
  my $skip = shift;
  my $pos = $self->pos;
  my $len = $self->len;
  my $newpos = $pos + $skip;
  $self->error_off_stream('skip') if $newpos < 0 || $newpos > $len;
  $self->_setpos($newpos);
  1;
}
sub exhausted {
  my $self = shift;
  $self->error_stream_mode('exhausted') if $self->writing;
  $self->pos >= $self->len;
}
sub erase {
  my $self = shift;
  $self->_setlen(0);
  $self->_setpos(0);
  # Writing state is left unchanged
  # You want an after method to handle the data
}
sub read_open {
  my $self = shift;
  $self->error_stream_mode('read') if $self->mode eq 'wo';
  $self->write_close if $self->writing;
  my $file = $self->file;
  if (defined $file) {
    open(my $fp, "<", $file) or die "Cannot open file '$file' for read: $!\n";
    my $headerlines = $self->fheaderlines;
    if (defined $headerlines) {
      # Read in their header
      my $header = '';
      while ($headerlines-- > 0) {
        $header .= <$fp>;
      }
      $self->_setfheader($header);
    }
    binmode $fp;
    # Turn off file linking while calling from_raw
    my $saved_mode = $self->mode;
    $self->_setfile( undef );
    $self->mode( 'rw' );
    my $bits = <$fp>;
    {
      local $/;
      $self->from_raw( <$fp>, $bits );
    }
    close $fp;
    # link us back.
    $self->_setfile( $file );
    $self->mode( $saved_mode );
  }
  1;
}
sub write_open {
  my $self = shift;
  $self->error_stream_mode('write') if $self->mode eq 'ro';
  if (!$self->writing) {
    $self->_setwrite(1);
    # pos is now ignored
  }
  1;
}
sub write_close {
  my $self = shift;
  if ($self->writing) {
    $self->_setwrite(0);
    $self->_setpos($self->len);

    my $file = $self->file;
    if (defined $file) {
      open(my $fp, ">", $file) or die "Cannot open file $file for write: $!\n";
      my $header = $self->fheader;
      print $fp $header, "\n" if defined $header && length($header) > 0;
      binmode $fp;
      print $fp $self->len, "\n";
      print $fp $self->to_raw;
      close $fp;
    }
  }
  1;
}


####### Error handling
#
# This section has two purposes:
#   1. enforce a common set of failure messages for all codes.
#   2. enable the position to be reset to the start of a code on an error.
#
# Number 2 is relatively complex since codes can be composed of other codes,
# and we want to back up to the start of the outermost code.  We set up a stack
# of saved positions which can be used when an error occurs.
#
# If your code methods do not either call other codes or make multiple calls to
# read / skip, then there really is no extra effort.  If they do, then it is
# important to call code_pos_start() before starting, code_pos_set() before
# each successive value, and code_pos_end() when done.  What you get in return
# is not having to worry about how far you've read -- the position will be
# restored to the start of the outermost code.
#
# From the user's point of view, this means if they try to read a complicated
# code and it is invalid, the position is left unchanged, instead of some
# random distance forward in the stream.

sub code_pos_start {  # Starting a code
  my $self = shift;
  my $name = shift;
  push @{$self->_code_pos_array}, $self->pos;
  push @{$self->_code_str_array}, $name;
  #print STDERR "error stack is ", join(",", @{$self->_code_str_array}), "\n";
}
sub code_pos_set {    # Replace position
  my $self = shift;
  $self->_code_pos_array->[-1] = $self->pos;
}
sub code_pos_end {    # Remove position -- we're not in this code any more
  my $self = shift;
  pop @{$self->_code_pos_array};
  pop @{$self->_code_str_array};
}
sub _code_restore_pos {  # Returns string of code name
  my $self = shift;
  # Check that we aren't trying to restore a position while writing
  if ($self->writing and @{$self->_code_pos_array}) {
    confess "Found code position while error in writing: " . $self->_code_str_array->[0];
  }
  # Put position back to start of topmost code
  if (@{$self->_code_pos_array}) {
    $self->_setpos($self->_code_pos_array->[0]);
    @{$self->_code_pos_array} = ();
  }
  my $codename = '';
  if (@{$self->_code_str_array}) {
    $codename = $self->_code_str_array->[0] if defined $self->_code_str_array->[0];
    @{$self->_code_str_array} = ();
  }
  $codename;
}

# This can be called after any code routines have been used, to verify they
# cleaned up after themselves.  Failing this usually means someone died inside
# an eval, while being called by a code routine.  It's also possible a broken
# code routine did a code_pos_start then returned without a matching end.
sub code_pos_is_set {
  my $self = shift;
  return unless @{$self->_code_pos_array};   # return undef if nothing.

  my $text = join(",", @{$self->_code_str_array});
  $text;
}

sub error_off_stream {
  my $self = shift;
  my $skipping = shift;

  # Give the skip error only if we were not reading a code.
  if ( (defined $skipping) && (@{$self->_code_pos_array} == 0) ) {
    croak "skip off end of stream";
  }

  my $codename = $self->_code_restore_pos();
  $codename = " ($codename)" if $codename ne '';
  croak "read off end of stream$codename";
}
sub error_stream_mode {
  my $self = shift;
  my $type = shift;
  my $codename = $self->_code_restore_pos();
  $codename = " ($codename)" if $codename ne '';

  croak "write while stream opened readonly"
        if ($type eq 'write') && ($self->mode eq 'ro');
  croak "read while stream opened writeonly"
        if ($type eq 'read')  && ($self->mode eq 'wo');

  if ($self->writing) {
    if    ($type eq 'rewind') { croak "rewind while writing$codename"; }
    elsif ($type eq 'read'  ) { croak "read while writing$codename"; }
    elsif ($type eq 'skip'  ) { croak "skip while writing$codename"; }
    elsif ($type eq 'exhausted') { croak "exhausted while writing$codename"; }
  } else {
    if    ($type eq 'write' ) { croak "write while reading$codename"; }
  }
  croak "Mode error$codename: $type";
}
sub error_code {
  my $self = shift;
  my $type = shift;
  my $text = shift;
  if ($type eq 'zeroval') {    # Implied text
    $type = 'value';
    $text = 'value must be >= 0';
  }
  if ($type eq 'range') {      # Range is given the value, the min, and the max
    $type = 'value';
    if (!defined $text) {
      $text = 'value out of range';
    } else {
      my $min = shift;
      my $max = shift;
      $text = "value $text out of range";
      $text .= " $min - $max" if defined $min && defined $max;
    }
  }
  my $codename = $self->_code_restore_pos();
  my $trailer = '';
  $trailer .= " ($codename)" if $codename ne '';
  $trailer .= ": $text" if defined $text;
  if    ($type eq 'param')  { croak "invalid parameters$trailer"; }
  elsif ($type eq 'value')  { croak "invalid value$trailer"; }
  elsif ($type eq 'string') { croak "invalid string$trailer"; }
  elsif ($type eq 'base')   { croak "code error: invalid base$trailer";}
  elsif ($type eq 'overflow'){croak "code error: overflow$trailer";}
  elsif ($type eq 'short')  { croak "short read$trailer"; }
  elsif ($type eq 'assert') { confess "internal assert$trailer"; }
  else                      { confess "Unknown error$trailer"; }
}


####### Combination functions
sub erase_for_write {
  my $self = shift;
  $self->erase;
  $self->write_open if !$self->writing;
}
sub rewind_for_read {
  my $self = shift;
  $self->write_close if $self->writing;
  $self->rewind;
}


sub readahead {
  my $self = shift;
  my $bits = shift;
  $self->read($bits, 'readahead');
}
sub read {                 # You need to implement this.
  confess "The read method has not been implemented!";
}
sub write {                # You need to implement this.
  confess "The write method has not been implemented!";
}


sub put_unary {
  my $self = shift;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    warn "Trying to write large unary value ($val)" if $val > 10_000_000;

    # Since the write routine is allowed to take any number of bits when
    # writing 0 and 1, this works, and is very fast.
    $self->write($val+1, 1);

    # Alternate implementation, much slower for large values:
    #
    # if ($val < maxbits) {
    #   $self->write($val+1, 1);
    # } else {
    #   my $nbits  = $val % maxbits;
    #   my $nwords = ($val-$nbits) / maxbits;
    #   $self->write(maxbits, 0)  for (1 .. $nwords);
    #   $self->write($nbits+1, 1);
    # }
  }
  1;
}
sub get_unary {            # You ought to override this.
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('Unary');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $val = 0;

    # Simple code:
    #
    #   my $maxval = $len - $pos - 1;  # Maximum unary value in remaining space
    #   $val++ while ( ($val <= $maxval) && ($self->read(1) == 0) );
    #   die "read off end of stream" if $pos >= $len;
    #
    # Faster code, looks at 32 bits at a time.  Still comparatively slow.

    my $word = $self->read(maxbits, 'readahead');
    last unless defined $word;
    while ($word == 0) {
      $val += maxbits;
      $self->skip(maxbits);
      $word = $self->read(maxbits, 'readahead');
    }
    while (($word >> (maxbits-1) & 1) == 0) {
      $val++;
      $word <<= 1;
    }
    my $nbits = $val % maxbits;
    $self->skip($nbits + 1);

    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}

# Write unary as 1111.....0  instead of 0000.....1
sub put_unary1 {
  my $self = shift;

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    warn "Trying to write large unary value ($val)" if $val > 10_000_000;
    if ($val < maxbits) {
      $self->write($val+1, maxval() << 1);
    } else {
      my $nbits  = $val % maxbits;
      my $nwords = ($val-$nbits) / maxbits();
      $self->write(maxbits, maxval)  for (1 .. $nwords);
      $self->write($nbits+1, maxval() << 1);
    }
  }
  1;
}
sub get_unary1 {            # You ought to override this.
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  $self->code_pos_start('Unary1');
  while ($count-- > 0) {
    $self->code_pos_set;
    my $val = 0;

    # Simple code:
    #
    #   my $maxval = $len - $pos - 1;  # Maximum unary value in remaining space
    #   $val++ while ( ($val <= $maxval) && ($self->read(1) == 0) );
    #   die "read off end of stream" if $pos >= $len;
    #
    # Faster code, looks at 32 bits at a time.  Still comparatively slow.

    my $word = $self->read(maxbits, 'readahead');
    last unless defined $word;
    while ($word == maxval) {
      $val += maxbits;
      $self->skip(maxbits);
      $word = $self->read(maxbits, 'readahead');
    }
    while (($word >> (maxbits-1) & 1) != 0) {
      $val++;
      $word <<= 1;
    }
    my $nbits = $val % maxbits;
    $self->skip($nbits + 1);

    push @vals, $val;
  }
  $self->code_pos_end;
  wantarray ? @vals : $vals[-1];
}

# binary values of given length
sub put_binword {
  my $self = shift;
  my $bits = shift;
  $self->error_code('param', "bits must be in range 0-" . maxbits)
                   if ($bits <= 0) || ($bits > maxbits);

  foreach my $val (@_) {
    $self->error_code('zeroval') unless defined $val and $val >= 0;
    $self->write($bits, $val);
  }
  1;
}
sub get_binword {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $bits = shift;
  $self->error_code('param', "bits must be in range 0-" . maxbits)
                   if ($bits <= 0) || ($bits > maxbits);
  my $count = shift;
  if    (!defined $count) { $count = 1;  }
  elsif ($count  < 0)     { $count = ~0; }   # Get everything
  elsif ($count == 0)     { return;      }

  my @vals;
  while ($count-- > 0) {
    my $val = $self->read($bits);
    last unless defined $val;
    push @vals, $val;
  }
  wantarray ? @vals : $vals[-1];
}


# Write one or more text binary strings (e.g. '10010')
sub put_string {
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  foreach my $str (@_) {
    next unless defined $str;
    $self->error_code('string') if $str =~ tr/01//c;
    my $bits = length($str);
    next unless $bits > 0;

    my $spos = 0;
    while ($bits >= 32) {
      $self->write(32, oct('0b' . substr($str, $spos, 32)));
      $spos += 32;
      $bits -= 32;
    }
    if ($bits > 0) {
      $self->write($bits, oct('0b' . substr($str, $spos, $bits)));
    }
  }
  1;
}
# Get a text binary string.  Similar to read, but bits can be 0 - len.
sub read_string {
  my $self = shift;
  $self->error_stream_mode('read') if $self->writing;
  my $bits = shift;
  $self->error_code('param', "bits must be >= 0") unless defined $bits && $bits >= 0;
  $self->error_code('short') unless $bits <= ($self->len - $self->pos);
  my $str = '';
  while ($bits >= 32) {
    $str .= unpack("B32", pack("N", $self->read(32)));
    $bits -= 32;
  }
  if ($bits > 0) {
    $str .= substr(unpack("B32", pack("N", $self->read($bits))), -$bits);
  }
  $str;
}

# Conversion to and from strings of 0's and 1's.  Note that the order is
# completely left to right based on what was written.

sub to_string {            # You should override this.
  my $self = shift;
  $self->rewind_for_read;
  $self->read_string($self->len);
}
sub from_string {          # You should override this.
  my $self = shift;
  #my $str  = shift;
  #my $bits = shift || length($str);
  $self->erase_for_write;
  $self->put_string($_[0]);
  $self->rewind_for_read;
}

# Conversion to and from binary.  Note that the order is completely left to
# right based on what was written.  This means it is an array of big-endian
# units.  This implementation uses 32-bit words as the units.

sub to_raw {               # You ought to override this.
  my $self = shift;
  $self->rewind_for_read;
  my $len = $self->len;
  my $pos = $self->pos;
  my $vec = '';
  while ( ($pos+31) < $len ) {
    $vec .= pack("N", $self->read(32));
    $pos += 32;
  }
  if ($pos < $len) {
    $vec .= pack("N", $self->read($len-$pos) << 32-($len-$pos));
  }
  $vec;
}
sub put_raw {              # You ought to override this.
  my $self = shift;
  $self->error_stream_mode('write') unless $self->writing;

  my $vec  = shift;
  my $bits = shift || int((length($vec)+7)/8);

  my $vpos = 0;
  while ($bits >= 32) {
    $self->write(32, unpack("N", substr($vec, $vpos, 4)));
    $vpos += 4;
    $bits -= 32;
  }
  if ($bits > 0) {
    my $nbytes = int(($bits+7)/8);             # this many bytes left
    my $pvec = substr($vec, $vpos, $nbytes);   # extract the bytes
    vec($pvec,33,1) = 0;                       # zero fill the 32-bit word
    my $word = unpack("N", $pvec);             # unpack the filled word
    $word >>= (32-$bits);                      # shift data to lower bits
    $self->write($bits, $word);                # write data to stream
  }
  1;
}
sub from_raw {
  my $self = shift;
  my $vec  = shift;
  my $bits = shift || int((length($vec)+7)/8);
  $self->erase_for_write;
  $self->put_raw($vec, $bits);
  $self->rewind_for_read;
}

# Conversion to and from your internal data.  This can be in any form desired.
# This could be a little-endian array, or a byte stream, or a string, etc.
# The main point is that we can get a single chunk that can be saved off, and
# later can restore the stream.  This should be efficient.

sub to_store {             # You ought to implement this.
  my $self = shift;
  $self->to_raw(@_);
}
sub from_store {           # You ought to implement this.
  my $self = shift;
  $self->from_raw(@_);
}

# Takes a stream and inserts its contents into the current stream.
# Non-destructive to both streams.
sub put_stream {
  my $self = shift;
  my $source = shift;
  return 0 unless defined $source && $source->can('to_string');

  # In an implementation, you could check if ref $source eq __PACKAGE__
  # and do something special.  BLVec / XS does this.

  # This is reasonably fast for most implementations.
  $self->put_string($source->to_string);
  # In theory this could be faster.  Since all the implementations have custom
  # string code, and none have custom raw code, it's currently slower.
  # $self->put_raw($source->to_raw, $source->len);
  1;
}



# Helper class methods for other functions
sub _floorlog2 {
  my $d = shift;
  my $base = 0;
  $base++ while ($d >>= 1);
  $base;
}
sub _ceillog2 {
  my $d = shift;
  $d--;
  my $base = 1;
  $base++ while ($d >>= 1);
  $base;
}
sub _bin_to_dec {
  no warnings 'portable';
  oct '0b' . substr($_[1], 0, $_[0]);
}
sub _dec_to_bin {
  # The following is typically fastest with 5.9.2 and later:
  #
  #   scalar reverse unpack("b$bits",($bits>32) ? pack("Q>",$v) : pack("V",$v));
  #
  # With 5.9.2 and later on a 64-bit machine, this will work quickly:
  #
  #   substr(unpack("B64", pack("Q>", $v)), -$bits);
  #
  # This is the best compromise that works with 5.8.x, BE/LE, and 32-bit:
  my $bits = shift;
  my $v = shift;
  if ($bits > 32) {
    # return substr(unpack("B64", pack("Q>", $v)), -$bits); # needs v5.9.2
    return   substr(unpack("B32", pack("N", $v>>32)), -($bits-32))
           . unpack("B32", pack("N", $v));
  } else {
    # return substr(unpack("B32", pack("N", $v)), -$bits); # slower
    return scalar reverse unpack("b$bits", pack("V", $v));
  }
}

no Moo::Role;
1;


# ABSTRACT: A Role implementing the API for Data::BitStream

=pod

=head1 NAME

Data::BitStream::Base - A Role implementing the API for Data::BitStream

=head1 SYNOPSIS

  use Moo;
  with 'Data::BitStream::Base';

=head1 DESCRIPTION

A role written for L<Data::BitStream> that provides the basic API, including
generic code for almost all functionality.

This is used by particular implementations such as L<Data::BitStream::String>
and L<Data::BitStream::WordVec>.




=head2 DATA

=over 4

=item B< pos >

A read-only non-negative integer indicating the current position in a read
stream.  It is advanced by C<read>, C<get>, and C<skip> methods, as well
as changed by C<to>, C<from>, C<rewind>, and C<erase> methods.

=item B< len >

A read-only non-negative integer indicating the current length of the stream
in bits.  It is advanced by C<write> and C<put> methods, as well as changed
by C<from> and C<erase> methods.

=item B< writing >

A read-only boolean indicating whether the stream is open for writing or
reading.  Methods for read such as
C<read>, C<get>, C<skip>, C<rewind>, C<skip>, and C<exhausted>
are not allowed while writing.  Methods for write such as
C<write> and C<put>
are not allowed while reading.

The C<write_open> and C<erase_for_write> methods will set writing to true.
The C<write_close> and C<rewind_for_read> methods will set writing to false.

The read/write distinction allows implementations more freedom in internal
caching of data.  For instance, they can gather writes into blocks.  It also
can be helpful in catching mistakes such as reading from a target stream.

=item B< mode >

The stream mode.  Especially useful when given a file.  The mode may be one of

  r    (read)
  ro   (readonly)
  w    (write)
  wo   (writeonly)
  rdwr (readwrite)
  a    (append)

=item B< file >

The name of a file to read or write (depending on the mode).

=item B< fheaderlines >

Only applicible when reading a file.  Indicates how many header lines exist
before the data.

=item B< fheader >

When writing a file, this is the header to write before the data.
When reading a file, this will be set to the header, if fheaderlines was given.

=back




=head2 CLASS METHODS

=over 4

=item B< maxbits >

Returns the number of bits in a word, which is the largest allowed size of
the C<bits> argument to C<read> and C<write>.  This will be either 32 or 64.

=item B< maxval >

Returns the maximum value we can handle.  This should be C< 2 ** maxbits - 1 >,
or C< 0xFFFF_FFFF > for 32-bit, and C< 0xFFFF_FFFF_FFFF_FFFF > for 64-bit.

=back




=head2 OBJECT METHODS (I<reading>)

These methods are only valid while the stream is in reading state.

=over 4

=item B< rewind >

Moves the position to the stream beginning.

=item B< exhausted >

Returns true is the stream is at the end.  Rarely used.

=item B< read($bits [, 'readahead']) >

Reads C<$bits> from the stream and returns the value.
C<$bits> must be between C<1> and C<maxbits>.

Returns undef if the current position is at the end of the stream.

Croaks with an off stream error if not enough bits are left in the stream.

The position is advanced unless the second argument is the string 'readahead'.

I<Note for implementations>: You have to implement this.

=item B< readahead($bits>) >

Identical to calling read with 'readahead' as the second argument.
Returns the value of the next C<$bits> bits (between C<1> and C<maxbits>).
Returns undef if the current position is at the end.
Allows reading past the end of the stream (fills with zeros as necessary).
Does not advance the position.

=item B< skip($bits) >

Advances the position C<$bits> bits.
Typically used in conjunction with C<readahead>.

=item B< get_unary([$count]) >

Reads one or more values from the stream in C<0000...1> unary coding.
If C<$count> is C<1> or not supplied, a single value will be read.
If C<$count> is positive, that many values will be read.
If C<$count> is negative, values are read until the end of the stream.

In list context this returns a list of all values read.  In scalar context
it returns the last value read.

I<Note for implementations>: You should have efficient code for this.

=item B< get_unary1([$count]) >

Like C<get_unary>, but using C<1111...0> unary coding.  Less common.

=item B< get_binword($bits, [$count]) >

Reads one or more values from the stream as fixed-length binary numbers, each
using C<$bits> bits.  The treatment of count and return values is identical to
C<get_unary>.

=item B< read_string($bits) >

Reads C<$bits> bits from the stream and returns them as a binary string, such
as '0011011'.

=back




=head2 OBJECT METHODS (I<writing>)

These methods are only valid while the stream is in writing state.

=over 4

=item B< write($bits, $value) >

Writes C<$value> to the stream using C<$bits> bits.
C<$bits> must be between C<1> and C<maxbits>, unless C<value> is 0 or 1, in
which case C<bits> may be larger than C<maxbits>.

The stream length will be increased by C<$bits> bits.
Regardless of the contents of C<$value>, exactly C<$bits> bits will be used.
If C<$value> has more non-zero bits than C<$bits>, the lower bits are written.
In other words, C<$value> will be masked before writing.

I<Note for implementations>: You have to implement this.

=item B< put_unary(@values) >

Writes the values to the stream in C<0000...1> unary coding.
Unary coding is only appropriate for relatively small numbers, as it uses
C<$value + 1> bits.

I<Note for implementations>: You should have efficient code for this.

=item B< put_unary1(@values) >

Like C<put_unary>, but using C<1111...0> unary coding.  Less common.

=item B< put_binword($bits, @values) >

Writes the values to the stream as fixed-length binary values.  This is just
a loop inserting each value with C<write($bits, $value)>.

=item B< put_string(@strings) >

Takes one or more binary strings, such as '1001101', '001100', etc. and
writes them to the stream.  The number of bits used for each value is equal
to the string length.

=item B< put_raw($packed, [, $bits]) >
Writes the packed big-endian vector C<$packed> which has C<$bits> bits of data.
If C<$bits> is not present, then C<length($packed)> will be used as the
byte-length.  It is recommended that you include C<$bits>.

=item B< put_stream($source_stream) >

Writes the contents of C<$source_stream> to the stream.  This is a helper
method that might be more efficient than doing it in one of the many other
possible ways.  Some functionally equivalent methods:

  $self->put_string( $source_stream->to_string );  # The default for put_stream

  $self->put_raw( $source_stream->to_raw, $source_stream->len );

  my $bits = $source_stream->len;
  $source_stream->rewind_for_read;
  while ($bits > 0) {
    my $wbits = ($bits >= 32) ? 32 : $bits;
    $self->write($wbits, $source_stream->read($wbits));
    $bits -= $wbits;
  }

=back




=head2 OBJECT METHODS (I<conversion>)

These methods may be called at any time, and will adjust the state of the
stream.

=over 4

=item B< to_string >

Returns the stream as a binary string, e.g. '00110101'.

=item B< to_raw >

Returns the stream as packed big-endian data.  This form is portable to
any other implementation on any architecture.

=item B< to_store >

Returns the stream as some scalar holding the data in some implementation
specific way.  This may be portable or not, but it can always be read by
the same implementation.  It might be more efficient than the raw format.


=item B< from_string($string) >

The stream will be set to the binary string C<$string>.

=item B< from_raw($packed [, $bits]) >

The stream is set to the packed big-endian vector C<$packed> which has
C<$bits> bits of data.  If C<$bits> is not present, then C<length($packed)>
will be used as the byte-length.  It is recommended that you include C<$bits>.

=item B< from_store($blob [, $bits]) >

Similar to C<from_raw>, but using the value returned by C<to_store>.

=back




=head2 OBJECT METHODS (I<other>)

=over 4

=item B< erase >

Erases all the data, while the writing state is left unchanged.  The position
and length will both be 0 after this is finished.

I<Note for implementations>: You need an 'after' method to actually erase the data.

=item B< read_open >

Reads the current input file, if one exists.

=item B< write_open >

Changes the state to writing with no other API-visible changes.

=item B< write_close >

Changes the state to reading, and the position is set to the end of the
stream.  No other API-visible changes happen.

=item B< erase_for_write >

A helper function that performs C<erase> followed by C<write_open>.

=item B< rewind_for_read >

A helper function that performs C<write_close> followed by C<rewind>.

=back




=head2 INTERNAL METHODS

These methods are used by roles.
As a stream user you should not be using these.

=over 4

=item B< code_pos_start >

=item B< code_pos_end >

=item B< code_pos_set >

Used to handle exceptions for codes that call other codes.  Generally used
in C< get_* > methods.  The primary reasoning for this is that we want to
unroll the stream location back to where the caller tried to read the code
on an error.  That way they can try again with a different code, or examine
the bits that resulted in an incorrect code.
C<code_pos_start> starts a new stack entry, C<code_pos_set> sets the start
of the current code so we know where to go back to, and C<code_pos_end>
indicates we're done so the code stack entry can be removed.

=item B< code_pos_is_set >

Returns the code stack or C<undef> if not in a code.  This should always be
C<undef> for users.  If it is not, it means some code routine finished
abnormally and didn't remove their error stack.

=item B< error_off_stream >

Croaks with a message about reading or skipping off the stream.  If this
happens inside a C<get_> method, it should indicate the outermost code that
was used.  The stream position is restored to the start of the outer code.

=item B< error_stream_mode >

Croaks with a message about the wrong mode being used.  This is what happens
when an attempt is made to write to a stream opened for reading, or read from
a stream opened for writing.

=item B< error_code >

Central routine that captures code errors, including incorrect parameters,
values out of range, overflows, range errors, etc.  All errors cause a croak
except assertions, which will confess (since they indicate a serious internal
issue).  Some additional information is also included if possible (e.g. the
outermost code being used, the allowed range, the value, etc.).

=back




=head1 SEE ALSO

=over 4

=item L<Data::BitStream>

=item L<Data::BitStream::String>

=item L<Data::BitStream::WordVec>

=back

=head1 AUTHORS

Dana Jacobsen E<lt>dana@acm.orgE<gt>

=head1 COPYRIGHT

Copyright 2011-2012 by Dana Jacobsen E<lt>dana@acm.orgE<gt>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
