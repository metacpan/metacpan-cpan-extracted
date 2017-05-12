package Data::BitStream;
# I have tested with 5.6.2 through 5.17.7 using Mouse.
# Moo requires perl 5.8.1, Moose requires 5.8.3.
use strict;
use warnings;

our $VERSION = '0.08';

# Since we're using Moo, things get rather messed up if we try to
# inherit from Exporter.  Really all we want is the ability to let people
# use a couple convenience functions, so just grab the import method.
use Exporter qw(import);
our @EXPORT_OK = qw( code_is_supported code_is_universal );


# Our class methods to support referencing codes by text names.
my %codeinfo;

sub add_code {
  my $rinfo = shift;
  die "add_code needs a hash ref" unless defined $rinfo && ref $rinfo eq 'HASH';
  foreach my $p (qw(package name universal params encodesub decodesub)) {
    die "invalid registration: missing $p" unless defined $$rinfo{$p};
  }
  my $name = lc $$rinfo{'name'};
  if (defined $codeinfo{$name}) {
    return 1 if $codeinfo{$name}{'package'} eq $$rinfo{'package'};
    die "module $$rinfo{'package'} trying to reuse code name '$name' already in use by $codeinfo{$name}{'package'}";
  }
  $codeinfo{$name} = $rinfo;
  1;
};

sub _find_code {
  my $code = lc shift;

  return $codeinfo{$code} if defined $codeinfo{$code};

  # Load codes from base
  if (   defined $Data::BitStream::Base::CODEINFO
      && ref $Data::BitStream::Base::CODEINFO eq 'ARRAY') {
    foreach my $r (@{$Data::BitStream::Base::CODEINFO}) {
      next unless ref $r eq 'HASH';
      add_code($r);
    }
  }

  # Load info for all code modules that have been included
  foreach my $module (keys %Data::BitStream::Code::) {
    # module is 'Gamma::'  mname is 'Gamma'
    my ($mname) = $module =~ /(.+)::$/;
    next unless defined $mname;
    # Load the CODEINFO variable, skip if it isn't found
    my $rinfo;
    {
      my $pname = 'Data::BitStream::Code::' . $module;
      no strict 'refs';  ## no critic
      $rinfo = ${$pname}{'CODEINFO'};
      next unless defined $rinfo;
      next unless $rinfo =~ s/^\*//;
      $rinfo = ${$rinfo};
    }
    next unless defined $rinfo;
    if (ref $rinfo eq 'HASH') {
      add_code($rinfo);
    } elsif (ref $rinfo eq 'ARRAY') {
      foreach my $r (@{$rinfo}) {
        next unless ref $r eq 'HASH';
        add_code($r);
      }
    }
  }

  $codeinfo{$code};
};

sub code_is_supported {
  my $code = lc shift;
  my $param;  $param = $1 if $code =~ s/\((.+)\)$//;
  return defined _find_code($code);
}

sub code_is_universal {
  my $code = lc shift;
  my $param;  $param = $1 if $code =~ s/\((.+)\)$//;
  my $inforef = _find_code($code);
  return unless defined $inforef;  # Unknown code.
  return $inforef->{'universal'};
}


# Pick one implementation as the default.
#
# BLVec uses the Data::BitStream::XS class, and is 50-100x faster than the
# others for most codes.
#
# WordVec is the preferred Pure Perl implementation, being both space and time
# efficient.
#
# String is simple and surprisingly fast, but uses more memory (1 byte per bit).
#
# Vec is deprecated.
#
# MinimalVec is for example only.
#
# BitVec uses Bit::Vector to try to obtain better performance.  While a few
# operations (e.g. get_unary) can be fast, in general it is as slow or slower
# than the WordVec implementation.  The main issue is that Bit::Vector uses a
# little-endian representation which does not match what we want.
#
# bench-codes with many codes, sum:
#
#   BLVec       4829 ns encode    11102 ns decode   71   x
#   String    403470 ns encode   494878 ns decode    1.3 x
#   WordVec   457533 ns encode   676737 ns decode    1.0
#   BitVec    492701 ns encode   666711 ns decode    0.98x
#   Vec       549342 ns encode   927764 ns decode    0.77x
#   MinmlVec  554690 ns encode  8252307 ns decode    0.13x
#
# A 32-bit HP 9000/785 gave similar results though ~15x slower overall.

use Moo;
if (eval {require Data::BitStream::BLVec}) {
  extends 'Data::BitStream::BLVec';
} else {
  extends 'Data::BitStream::WordVec';
}

# get and put methods for referencing codes by text names
sub code_put {
  my $self = shift;
  my $code = lc shift;
  my $param;  $param = $1 if $code =~ s/\((.+)\)$//;
  my $inforef = _find_code($code);
  die "Unknown code $code" unless defined $inforef;
  my $sub = $inforef->{'encodesub'};
  die "No encoding sub for code $code!" unless defined $sub;
  if ($inforef->{'params'}) {
    die "Code $code needs a parameter" unless defined $param;
    return $sub->($self, $param, @_);
  } else {
    die "Code $code does not have parameters" if defined $param;
    return $sub->($self, @_);
  }
}

sub code_get {
  my $self = shift;
  my $code = lc shift;
  my $param;  $param = $1 if $code =~ s/\((.+)\)$//;
  my $inforef = _find_code($code);
  die "Unknown code $code" unless defined $inforef;
  my $sub = $inforef->{'decodesub'};
  die "No decoding sub for code $code!" unless defined $sub;
  if ($inforef->{'params'}) {
    die "Code $code needs a parameter" unless defined $param;
    return $sub->($self, $param, @_);
  } else {
    die "Code $code does not have parameters" if defined $param;
    return $sub->($self, @_);
  }
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;
__END__


# ABSTRACT: A bit stream class including integer coding methods

=pod

=encoding utf8


=head1 NAME

Data::BitStream - A bit stream class including integer coding methods


=head1 VERSION

version 0.08


=head1 SYNOPSIS

  use Data::BitStream;
  my $stream = Data::BitStream->new;
  $stream->put_gamma($_) for 1 .. 20;
  printf "20 numbers stored in %.2f bits each\n", $stream->len / 20;
  $stream->rewind_for_read;
  my @values = $stream->get_gamma(-1);

  $stream->erase_for_write;         # Clear the stream and open for write
  my @data = map { int(1000/$_) } 1..1000;  # Make some data
  my $k = 2;
  $stream->put_arice($k, @data);    # Store with adaptive Rice coding
  printf "1000 numbers stored in %.2f bits each\n", $stream->len / 1000;
  
See the examples for more uses.


=head1 DESCRIPTION

A Moo class providing read/write access to bit streams including support
for numerous variable length codes.  Adding new codes as roles is easily done.
An adaptive code (ARice) is included that typically will use fewer bits on
most inputs than fixed codes.

Bit streams are often used in data compression and in embedded products where
memory is at a premium.  Using variable length codes allows high performance
compression of integer data.  Common codes such as fixed-bit-length, unary,
gamma, delta, Golomb, and Rice codes are included, as well as many
interesting other codes such as Levenstein, Even-Rodeh,
Fibonacci C1 and C2, generalized Fibonacci, and Goldbach codes to name
a few.  Flexible codes such as Comma, Taboo, Start-Stop codes are also
implemented.

One common application is lossless image compression, where a predictor turns
each pixel into a small error term, which can then be efficiently encoded.
Another application is storing opcodes that have a very uneven distribution
(e.g. some opcodes are very common, some are uncommon).

For higher performance, the L<Data::BitStream::XS> module can be installed,
which will speed up operation of this module greatly.  It may also be used
directly if the absolute best speed must be obtained, although that bypasses
Moo/Moose and hence will not allow custom roles.


=head1 EXAMPLES

=head2 Display bit patterns for some codes

  use Data::BitStream;
  sub string_of { my $stream = Data::BitStream->new;
                  $_[0]->($stream);
                  return $stream->to_string; }
  my @codes = qw(Gamma Delta Omega Fib);
  printf "%5s  " . (" %-11s" x scalar @codes) . "\n", 'N', @codes;
  foreach my $n (0 .. 20) {
    printf "%5d  ", $n;
    printf " %-11s", string_of(sub{shift->put_gamma($n)});
    printf " %-11s", string_of(sub{shift->put_delta($n)});
    printf " %-11s", string_of(sub{shift->put_omega($n)});
    printf " %-11s", string_of(sub{shift->put_fib($n)});
    print "\n";
  }


=head2 A simple predictor/encoder compression snippit

  use Data::BitStream;
  my $stream = Data::BitStream->new;
  # Loop over the data: characters, pixels, table entries, etc.
  foreach my $v (@values) {
    # predict the current value using your subroutine.  This routine
    # will use one or more previous values to estimate the current one.
    my $p = predict($v);
    # determine the signed difference.
    my $delta = $v - $p;
    # Turn this into an absolute difference suitable for coding.
    $delta = ($delta >= 0)  ?  2*$delta  :  -2*$delta-1;
    # Encode this using gamma encoding (or whichever works best for you).
    $stream->put_gamma($delta);
  }
  # Nicely packed up compressed data.
  my $compressed_data = $stream->to_raw;

This is a classic prediction-coding style compression method, used in many
applications.  Most lossless image compressors use this method, though often
with some extra steps further reduce the error term.  JPEG-LS, for example,
uses a very simple predictor, and puts its effort into relatively complex
bias estimations and adaptive determination of the parameter for Rice coding.

=head2 Convert Elias Delta encoded strings into Fibonacci encoded strings

  #/usr/bin/perl
  use Data::BitStream;
  my $d = Data::BitStream->new;
  my $f = Data::BitStream->new;
  while (<>) {
    chomp;
    $d->from_string($_);
    $f->erase_for_write;
    $f->put_fib( $d->get_delta(-1) );
    print scalar $f->to_string, "\n";
  }

=head2 Using a custom encoding method

  use Data::BitStream;
  Moo::Role->apply_roles_to_package('Data::BitStream',
     qw/Data::BitStream::Code::Escape/);

  my $stream = Data::BitStream->new;
  $stream->put_escape([4,7], 14, 28, 42, 56);   # Add four values
  $stream->rewind_for_read;
  my @values = $stream->get_escape([4,7], -1);

The escape code is not included by default, so this shows how we can add it
to the package.  You can also use C<Moo::Role->apply_roles_to_object> and
give it a stream object as the first argument, which will apply the role
just to the single stream.  Alternately, if you have Moose, you can use
C<Data::BitStream::Code::Escape->meta->apply($stream);> or other MOP
operations.

Note that if we used the text interface we don't have to do this, as the
Escape module includes code info that the L<Data::BitStream> module will
find by default.  This involves an extra lookup to find the method, but
is convenient:

  use Data::BitStream;
  use Data::BitStream::Code::Escape;
  my $stream = Data::BitStream->new;
  $stream->code_put("Escape(4-7)", 14, 28, 42, 56);
  $stream->rewind_for_read;
  my @values = $stream->code_get("Escape(4-7)", -1);




=head1 METHODS


=head2 CLASS METHODS

=over 4

=item B< new >

Creates a new object.  By default it has no associated file and is mode RW.
An optional hash of arguments may be supplied.  Examples:

  $stream = Data::BitStream->new( mode => 'ro' );

The stream is opened as a read-only stream.  Attempts to open it for write will
fail, hence all write / put methods will also fail.  This is most useful for
opening a file for read, which will ensure no changes are made.

Possible modes include C<'read' / 'r'>, C<'readonly' / 'ro'>, C<'write' / 'w'>,
C<'writeonly' / 'wo'>, C<'append' / 'a'>, and C<'readwrite' / 'rw' / 'rdwr'>.

  $stream = Data::BitStream->new( file    => "c.bsc",
                                  fheader => "HEADER $foo $bar",
                                  mode    => 'w' );

A file is associated with the stream.  Upon closing the file, going out of
scope, or otherwise being destroyed, the stream will be written to the file,
with the given header string written first.  While the current implementation
writes at close time, later implementations may write as the stream is written
to.

  $stream = Data::BitStream->new( file => "c.bsc",
                                  fheaderlines => 1,
                                  mode => 'ro' );

A file is associated with the stream.  The contents of the file will be
slurped into the stream.  The given number of header lines will be skipped
at the start.  While the current implementation slurps the contents, later
implementations may read from the file as the stream is read.

=item B< maxbits >

Returns the number of bits in a word, which is the largest allowed size of
the C<bits> argument to C<read> and C<write>.  This will be either 32 or 64.

=item B< code_is_supported >

Returns a hash of information about a code if it is known, and C<undef>
otherwise.

The argument is a text name, such as C<'Gamma'>, C<'Rice(2)'>, etc.

This method may be exported if requested.

=item B< code_is_universal >

Returns C<undef> if the code is not known, C<0> if the code is non-universal,
and a non-zero integer if it is universal.

The argument is a text name, such as C<'Gamma'>, C<'Rice(2)'>, etc.

A code is universal if there exists a constant C<C> such that C<C> plus the
length of the code is less than the optimal code length, for all values.  What
this typically means for us in practical terms is that non-universal codes
are fine for small numbers, but their size increases rapidly, making them
inappropriate when large values are possible (no matter how rare).  A
classic non-universal code is Unary coding, which takes C<k+1> bits to
store value C<k>.  This is very good if most values are 0 or near zero.  If
we have rare values in the tens of thousands, it's not so great.  It is
likely to be fatal if we ever come across a value of 2 billion.

This method may be exported if requested.

=item B< add_code >

Used for the dispatch table methods C<code_put> and C<code_get> as well as
other helper methods like C<code_is_universal> and C<code_is_supported>.
This is typically handled internally, but can be used to register a new code
or variant.  An example of an Omega-Golomb code:

   Data::BitStream::XS::add_code(
      { package   => __PACKAGE__,
        name      => 'OmegaGolomb',
        universal => 1,
        params    => 1,
        encodesub => sub {shift->put_golomb( sub {shift->put_omega(@_)}, @_ )},
        decodesub => sub {shift->get_golomb( sub {shift->get_omega(@_)}, @_ )},
      }
   );

which registers the name C<OmegaGolomb> as a new universal code that takes
one parameter.  Given a stream C<$stream>, this is now allowed:

   $stream->erase_for_write;
   $stream->code_put("OmegaGolomb(5)", 477);
   $stream->rewind_for_read;
   my $value = $stream->code_get("OmegaGolomb(5)");
   die unless $value == 477;

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

The position is advanced unless the second argument is the string 'readahead'.

Attempting to read past the end of the stream is a fatal error.  However,
readahead is allowed as it is speculative.  All positions past the end of
the stream will always be filled with zero bits.

=item B< skip($bits) >

Advances the position C<$bits> bits.  Used in conjunction with C<readahead>.

Attempting to skip past the end of the stream is a fatal error.

=item B< read_string($bits) >

Reads C<$bits> bits from the stream and returns them as a binary string, such
as C<'0011011'>.  Attempting to read past the end of the stream is a fatal
error.

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
In other words, C<$value> will be effectively masked before writing.

=item B< put_string(@strings) >

Takes one or more binary strings (e.g. C<'1001101'>, C<'001100'>) and
writes them to the stream. The number of bits used for each value is
equal to the string length.

=item B< put_stream($source_stream) >

Writes the contents of C<$source_stream> to the stream.  This is a helper
method that might be more efficient than doing it in one of the many other
possible ways.  The default implementation uses:

  $self->put_string( $source_stream->to_string );

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

=item B< erase >

Erases all the data, while the writing state is left unchanged.  The position
and length will both be 0 after this is finished.

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




=head2 OBJECT METHODS (I<coding>)

All coding methods are biased to 0.  This means values from 0 to 2^maxbits-1
(for universal codes) may be encoded, even if the original code as published
starts with 1.

All C<get_> methods take an optional count as the last argument.
If C<$count> is C<1> or not supplied, a single value will be read.
If C<$count> is positive, that many values will be read.
If C<$count> is negative, values are read until the end of the stream.

C<get_> methods called in list context will return a list of all values read.
Called in scalar context they return the last value read.

C<put_> methods take one or more values as input after any optional
parameters and write them to the stream.  All values must be non-negative
integers that do not exceed the maximum encodable value (typically ~0,
but may be lower for some codes depending on parameter, and
non-universal codes will be practically limited to smaller values).

=over 4

=item B< get_unary([$count]) >

=item B< put_unary(@values) >

Reads/writes one or more values from the stream in C<0000...1> unary coding.
Unary coding is only appropriate for relatively small numbers, as it uses
C<$value + 1> bits per value.

=item B< get_unary1([$count]) >

=item B< put_unary1(@values) >

Reads/writes one or more values from the stream in C<1111...0> unary coding.

=item B< get_binword($bits, [$count]) >

=item B< put_binword($bits, @values) >

Reads/writes one or more values from the stream as fixed-length binary
numbers, each using C<$bits> bits.

=item B< get_gamma([$count]) >

=item B< put_gamma(@values) >

Reads/writes one or more values from the stream in Elias Gamma coding.

=item B< get_delta([$count]) >

=item B< put_delta(@values) >

Reads/writes one or more values from the stream in Elias Delta coding.

=item B< get_omega([$count]) >

=item B< put_omega(@values) >

Reads/writes one or more values from the stream in Elias Omega coding.

=item B< get_levenstein([$count]) >

=item B< put_levenstein(@values) >

Reads/writes one or more values from the stream in Levenstein coding
(sometimes called Levenshtein or Левенште́йн coding).

=item B< get_evenrodeh([$count]) >

=item B< put_evenrodeh(@values) >

Reads/writes one or more values from the stream in Even-Rodeh coding.

=item B< get_goldbach_g1([$count]) >

=item B< put_goldbach_g1(@values) >

Reads/writes one or more values from the stream in Goldbach G1 coding.

=item B< get_goldbach_g2([$count]) >

=item B< put_goldbach_g2(@values) >

Reads/writes one or more values from the stream in Goldbach G2 coding.

=item B< get_fib([$count]) >

=item B< put_fib(@values) >

Reads/writes one or more values from the stream in Fibonacci coding.
Specifically, the order C<m=2> C1 codes of Fraenkel and Klein.

=item B< get_fibgen($m [, $count]) >

=item B< put_fibgen($m, @values) >

Reads/writes one or more values from the stream in generalized Fibonacci
coding.  The order C<m> should be between 2 and 16.  These codes are
described in Klein and Ben-Nissan (2004).  For C<m=2> the results are
identical to the standard C1 form.

=item B< get_fib_c2([$count]) >

=item B< put_fib_c2(@values) >

Reads/writes one or more values from the stream in Fibonacci C2 coding.
Specifically, the order C<m=2> C2 codes of Fraenkel and Klein.  Note that
these codes are not prefix-free, hence they will not mix well with other
codes in the same stream.

=item B< get_comma($bits [, $count]) >

=item B< put_comma($bits, @values) >

Reads/writes one or more values from the stream in Comma coding.  The number
of bits C<bits> should be between 1 and 16.  C<bits=1> implies Unary coding.
C<bits=2> is the ternary comma code.  No leading zeros are used.

=item B< get_blocktaboo($taboo [, $count]) >

=item B< put_blocktaboo($taboo, @values) >

Reads/writes one or more values from the stream in block-based Taboo coding.
The parameter C<taboo> is the binary string of the taboo code to use, such
as C<'00'>.  C<taboo='1'> implies Unary coding.  C<taboo='0'> implies Unary1
coding.  No more than 16 bits of taboo code may be given.
These codes are a more efficient version of comma codes, as they allow
leading zeros.

=item B< get_golomb($m [, $count]) >

=item B< put_golomb($m, @values) >

Reads/writes one or more values from the stream in Golomb coding.

=item B< get_golomb(sub { ... }, $m [, $count]) >

=item B< put_golomb(sub { ... }, $m, @values) >

Reads/writes one or more values from the stream in Golomb coding using the
supplied subroutine instead of unary coding, which can make them work with
large outliers.  For example to use Fibonacci coding for the base:

  $stream->put_golomb( sub {shift->put_fib(@_)}, $m, $value);

  $value = $stream->get_golomb( sub {shift->get_fib(@_)}, $m);

=item B< get_rice($k [, $count]) >

=item B< put_rice($k, @values) >

Reads/writes one or more values from the stream in Rice coding, which is
the time efficient case where C<m = 2^k>.

=item B< get_rice(sub { ... }, $k [, $count]) >

=item B< put_rice(sub { ... }, $k, @values) >

Reads/writes one or more values from the stream in Rice coding using the
supplied subroutine instead of unary coding, which can make them work with
large outliers.  For example to use Omega coding for the base:

  $stream->put_rice( sub {shift->put_omega(@_)}, $k, $value);

  $value = $stream->get_rice( sub {shift->get_omega(@_)}, $k);

=item B< get_gammagolomb($m [, $count]) >

=item B< put_gammagolomb($m, @values) >

Reads/writes one or more values from the stream in Golomb coding using
Elias Gamma codes for the base.  This is a convenience since they are common.

=item B< get_expgolomb($k [, $count]) >

=item B< put_expgolomb($k, @values) >

Reads/writes one or more values from the stream in Rice coding using
Elias Gamma codes for the base.  This is a convenience since they are common.

=item B< get_baer($k [, $count]) >

=item B< put_baer($k, @values) >

Reads/writes one or more values from the stream in Baer c_k coding.  The
parameter C<k> must be between C<-32> and C<32>.

=item B< get_boldivigna($k [, $count]) >

=item B< put_boldivigna($k, @values) >

Reads/writes one or more values from the stream in the Zeta coding of
Paolo Boldi and Sebastiano Vigna.  The parameter C<k> must be between C<1>
and C<maxbits> (C<32> or C<64>).  Typical values for C<k> are between C<2>
and C<6>.

=item B< get_arice(sub { ... }, $k [, $count]) >

=item B< put_arice(sub { ... }, $k, @values) >

Reads/writes one or more values from the stream in Adaptive Rice coding using
the supplied subroutine instead of Elias Gamma coding to encode the base.
The value of $k will adapt to better fit the values.  This interface will
likely change to make C<$k> a reference.

=item B< get_startstop(\@m [, $count]) >

=item B< put_startstop(\@m, @values) >

Reads/writes one or more values using Start/Stop codes.  The parameter is an
array reference which can be an anonymous array, for example:

  $stream->put_startstop( [0,3,2,0], @array );
  my @array2 = $stream->get_startstop( [0,3,2,0], -1);

=item B< get_startstepstop(\@m [, $count]) >

=item B< put_startstepstop(\@m, @values) >

Reads/writes one or more values using Start-Step-Stop codes.  The parameter
is an array reference which can be an anonymous array, for example:

  $stream->put_startstepstop( [3,2,9], @array );
  my @array3 = $stream->get_startstepstop( [3,2,9], -1);

=item B< code_get($code, [, $count]) >

=item B< code_put($code, @values ) >

These methods wrap up all the previous encoding and decoding methods in an
internal dispatch table.
C<code> is a text name of the code, such as C<'Gamma'>, C<'Fibonacci'>, etc.
Codes with parameters are called as C<'Rice(2)'>, C<'StartStop(0-0-2-4-14)'>,
etc.

  # $use_rice and $k obtained from options, parameters, or wherever.
  my $code = $use_rice ? "Rice($k)" : "Delta";
  my $nvalues = scalar @values;
  $stream->code_put($code, @values);
  # ....
  my @vals = $stream->code_get($code, $nvalues);
  print "Read $nvalues values with code '$code':  ", join(',', @vals), "\n";

=back




=head1 SEE ALSO

The L<Data::Buffer> module has some similarities, and may be easier to use if
your structure maps directly to typical C structs.  The main feature it has
that isn't replicated here is the template functionality.  The primary
difference is L<Data::BitStream> allows arbitrary bit lengths (it isn't byte
oriented), and of course all the different codes.  It also allows direct
storage of 64-bit integers, and bigints (using binary strings).

=over 4

=item L<Data::BitStream::Base>

=item L<Data::BitStream::WordVec>

=item L<Data::BitStream::Code::Gamma>

=item L<Data::BitStream::Code::Delta>

=item L<Data::BitStream::Code::Omega>

=item L<Data::BitStream::Code::Levenstein>

=item L<Data::BitStream::Code::EvenRodeh>

=item L<Data::BitStream::Code::Fibonacci>

=item L<Data::BitStream::Code::Additive>

=item L<Data::BitStream::Code::Golomb>

=item L<Data::BitStream::Code::Rice>

=item L<Data::BitStream::Code::GammaGolomb>

=item L<Data::BitStream::Code::ExponentialGolomb>

=item L<Data::BitStream::Code::StartStop>

=item L<Data::BitStream::Code::Baer>

=item L<Data::BitStream::Code::BoldiVigna>

=item L<Data::BitStream::Code::Comma>

=item L<Data::BitStream::Code::Taboo>

=item L<Data::BitStream::Code::ARice>

=back




=head1 AUTHORS

Dana Jacobsen <dana@acm.org>

=head1 COPYRIGHT

Copyright 2011-2014 by Dana Jacobsen <dana@acm.org>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
