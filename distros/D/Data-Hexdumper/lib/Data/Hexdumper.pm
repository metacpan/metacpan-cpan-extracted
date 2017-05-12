package Data::Hexdumper;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);

$VERSION = "3.0001";

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(hexdump);

use constant BIGENDIAN    => (unpack("h*", pack("s", 1)) =~ /01/);
use constant LITTLEENDIAN => (unpack("h*", pack("s", 1)) =~ /^1/);

# static data, tells us the length of each type of word
my %num_bytes=(
  '%C'  => 1, # unsigned char
  '%S'  => 2, # unsigned 16-bit
  '%L'  => 4, # unsigned 32-bit
  '%L<' => 4, # unsigned 32-bit, little-endian
  '%L>' => 4, # unsigned 32-bit, big-endian
  '%V'  => 4, # unsigned 32-bit, little-endian
  '%N'  => 4, # unsigned 32-bit, big-endian
  '%S<' => 2, # unsigned 16-bit, little-endian
  '%S>' => 2, # unsigned 16-bit, big-endian
  '%v'  => 2, # unsigned 16-bit, little-endian
  '%n'  => 2, # unsigned 16-bit, big-endian
  '%Q'  => 8, # unsigned 64-bit
  '%Q<' => 8, # unsigned 64-bit, little-endian
  '%Q>' => 8, # unsigned 64-bit, big-endian
);

my %number_format_to_new_format = (
  'C'  => '  %4a : %16C : %d',
  'S'  => '  %4a : %8S         : %d',
  'S<' => '  %4a : %8S<         : %d',
  'S>' => '  %4a : %8S>         : %d',
  'L'  => '  %4a : %4L             : %d',
  'L<' => '  %4a : %4L<             : %d',
  'L>' => '  %4a : %4L>             : %d',
  'Q'  => '  %4a : %2Q               : %d',
  'Q<' => '  %4a : %2Q<               : %d',
  'Q>' => '  %4a : %2Q>               : %d',
);

=head1 NAME

Data::Hexdumper - Make binary data human-readable

=head1 SYNOPSIS

    use Data::Hexdumper qw(hexdump);
    print hexdump(
      data           => $data, # what to dump
      # NB number_format is deprecated
      number_format  => 'S',   # display as unsigned 'shorts'
      start_position => 100,   # start at this offset ...
      end_position   => 148    # ... and end at this offset
    );
    print hexdump(
      "abcdefg",
      { output_format => '%4a : %C %S< %L> : %d' }
    );

=head1 DESCRIPTION

C<Data::Hexdumper> provides a simple way to format arbitrary binary data
into a nice human-readable format, somewhat similar to the Unix 'hexdump'
utility.

It gives the programmer a considerable degree of flexibility in how the
data is formatted, with sensible defaults.  It is envisaged that it will
primarily be of use for those wrestling alligators in the swamp of binary
file formats, which is why it was written in the first place.

=head1 SUBROUTINES

The following subroutines are exported by default, although this is
deprecated and will be removed in some future version.  Please pretend
that you need to ask the module to export them to you.

If you do assume that the module will always export them, then you may
also assume that your code will break at some point after 1 Aug 2012.

=head2 hexdump

Does everything.  Takes a hash of parameters, one of which is mandatory,
the rest having sensible defaults if not specified.  Available parameters
are:

=over

=item data

A scalar containing the binary data we're interested in.  This is
mandatory.

=item start_position

An integer telling us where in C<data> to start dumping.  Defaults to the
beginning of C<data>.

=item end_position

An integer telling us where in C<data> to stop dumping.  Defaults to the
end of C<data>.

=item number_format

This is deprecated.  See 'INCOMPATIBLE CHANGES' below.  If you use this
your data will be padded with NULLs to be an integer multiple of 16 bytes.
You can expect number_format to be removed at some point in 2014 or later.

A string specifying how to format the data.  It can be any of the following,
which you will notice have the same meanings as they do to perl's C<pack>
function:

=over

=item C - unsigned char

=item S - unsigned 16-bit, native endianness

=item v or SE<lt> - unsigned 16-bit, little-endian

=item n or SE<gt> - unsigned 16-bit, big-endian

=item L - unsigned 32-bit, native endianness

=item V or LE<lt> - unsigned 32-bit, little-endian

=item N or LE<gt> - unsigned 32-bit, big-endian

=item Q - unsigned 64-bit, native endianness

=item QE<lt> - unsigned 64-bit, little-endian

=item QE<gt> - unsigned 64-bit, big-endian

=back

Note that 64-bit formats are *always* available,
even if your perl is only 32-bit.  Similarly, using E<lt> and E<gt> on
the S and L formats always works, even if you're using a pre 5.10.0 perl.
That's because this code doesn't use C<pack()>.

=item output_format

This is an alternative and much more flexible (but more complex) method
of specifying the output format.  Instead of specifying a single format
for all your output, you can specify formats like:

  %4a : %C %S %L> %Q : %d

which will, on each line, display first the address (consisting of '0x'
and 4 hexadecimal digits, zero-padded if necessary), then a space, then
a colon, then a single byte of data, then a space, then an unsigned
16-bit value in native endianness, then a space, then an unsigned 32-bit
big-endian value, ... then a colon,
a space, then the characters representing your 15 byte record.

You can use exactly the same characters and character sequences as are
specified above for number_format, plus 'a' for the address, and 'd'
for the data.  To output a literal % character, use %% as is normal
with formats - see sprintf for details.  To output a literal E<lt> or E<gt>
character where it may be confused with any of the {S,L,Q}{E<lt>,E<gt>}
sequences, use %E<lt> or %E<gt>.  So, for example, to output a 16-bit
value in native endianness followed by <, use %S%<.

%a takes an optional base-ten number between the % and the a signifying
the number of hexadecimal digits.  This defaults to 4.

%{C,S,L,Q} also take an optional base-ten number between the % and the letter,
signifying the number of repeats.  These will be separated by spaces in
the output.  So '%4C' is equivalent to '%C %C %C %C'.

Anything else will get printed literally.  This format
will be repeated for as many lines as necessary.  If the amount of data
isn't enough to completely fill the last line, it will be padded with
NULL bytes.

To specify both number_format and output_format is a fatal error.

If neither are given, output_format defaults to:

  '  %4a : %16C : %d'

which is equivalent to the old-style:

  number_format => 'C'

=item suppress_warnings

Make this true if you want to suppress any warnings - such as that your
data may have been padded with NULLs if it didn't exactly fit into an
integer number of words, or if you do something that is deprecated.

=item space_as_space

Make this true if you want spaces (ASCII character 0x20) to be printed as
spaces Otherwise, spaces will be printed as full stops / periods (ASCII
0x2E).

=back

Alternatively, you can supply the parameters as a scalar chunk of data
followed by an optional hashref of the other options:

    $results = hexdump($string);
    $results = hexdump(
      $string,
      { start_position => 100, end_position   => 148 }
    );

=cut

sub hexdump {
  my @params = @_;
  # first let's see if we need to massage the data into canonical form ...
  if($#params == 0) {                 # one param: hexdump($string)
    @params = (data => $params[0]);
  } elsif($#params == 1 && ref($params[1])) { # two: hexdump($foo, {...})
    @params = (
      data => $params[0],
      %{$params[1]}
    )
  }

  my %params=@params;
  my($data, $number_format, $output_format, $start_position, $end_position)=
    @params{qw(data number_format output_format start_position end_position)};

  die("can't have both number_format and output_format\n")
    if($output_format && $number_format);
  my $addr = $start_position ||= 0;
  $end_position ||= length($data)-1;
  if(!$output_format) {
    # $output_format = '  %a : %C %C %C %C %C %C %C %C %C %C %C %C %C %C %C %C : %d';
    warn("Data::Hexdumper: number_format is deprecated\n")
      if($number_format && !$params{suppress_warnings});
    $number_format ||= 'C';
    if($number_format eq 'V') { $number_format = 'L<'; }
    if($number_format eq 'N') { $number_format = 'L>'; }
    if($number_format eq 'v') { $number_format = 'S<'; }
    if($number_format eq 'n') { $number_format = 'S>'; }
    $output_format = $number_format_to_new_format{$number_format} ||
      die("number_format not recognised\n");
  }

  my @format_elements_raw = split(//, $output_format);
  my @format_elements;
  while(@format_elements_raw) {
    push @format_elements, shift(@format_elements_raw);
    if($format_elements[-1] eq '%') {
      while(exists($format_elements_raw[0]) && $format_elements_raw[0] =~ /\d/) {
        $format_elements[-1] .= shift(@format_elements_raw);
      }
      if(exists($format_elements_raw[0]) && $format_elements_raw[0] =~ /[adCSLQ%<>]/) {
        $format_elements[-1] .= shift(@format_elements_raw);
      }
      if($format_elements[-1] =~ /%([%<>])/) { $format_elements[-1] = $1 }
       elsif($format_elements[-1] =~ /%\d*[QSL]/ &&
         exists($format_elements_raw[0]) &&
         $format_elements_raw[0] =~ /[<>]/
      ) { $format_elements[-1] .= shift(@format_elements_raw); }
    }
  }

  @format_elements = map {
    my $format = $_;
    my @r;
    if($format =~ /^([^%]|%\d*a|%\D|%$)/) { push @r, $format; }
     else {
      $format =~ /^%(\d+)(.*)/;
      push @r, ('%'.$2, ' ') x $1;
      pop @r; # get rid of the last space
    }
    @r;
  } @format_elements;

  my $chunk_length = 0;
  foreach my $format (grep { /^%[CSLQ]/ } @format_elements) {
    $chunk_length += $num_bytes{$format};
  }

  # sanity-check the parameters
  die("No data given to hexdump.") unless length($data);
  die("start_position must be numeric.") if($start_position=~/\D/);
  die("end_position must be numeric.") if($end_position=~/\D/);
  die("end_position must not be before start_position.")
    if($end_position < $start_position);

  # extract the required range and pad end with NULLs if necessary

  $data=substr($data, $start_position, 1+$end_position-$start_position);
  if(length($data) / $chunk_length != int(length($data) / $chunk_length)) {
    warn "Data::Hexdumper: data length isn't an integer multiple of lines\n".
         "so has been padded with NULLs at the end.\n"
      unless($params{suppress_warnings});
    $data .= pack('C', 0) x ($chunk_length - length($data) + int(length($data)/$chunk_length)*$chunk_length);
  }

  my $output=''; # where we put the formatted results

  while(length($data)) {
    # Get a chunk
    my $chunk = substr($data, 0, $chunk_length);
    $data = ($chunk eq $data) ? '' : substr($data, $chunk_length);

    my $characters = $chunk;
    # replace any non-printable character with .
    if($params{space_as_space}) {
      $characters =~ s/[^a-z0-9\\|,.<>;:'\@[{\]}#`!"\$%^&*()_+=~?\/ -]/./gi;
    } else {
      $characters =~ s/[^a-z0-9\\|,.<>;:'\@[{\]}#`!"\$%^&*()_+=~?\/-]/./gi;
    }

    foreach my $format (@format_elements) {
      if(length($format) == 1) { # pass straight through
        $output .= $format;
      } elsif($format =~ /%(\d*)a/) { # address
        my $nibbles = $1 || 4;
        $output .= sprintf("0x%0${nibbles}X", $addr);
      } elsif($format eq '%d') { # data
        $output .= $characters;
      } else {
        my $word = substr($chunk, 0, $num_bytes{$format});
        if(length($chunk) > $num_bytes{$format}) {
          $chunk = substr($chunk, $num_bytes{$format});
        } else { $chunk = ''; }
        $output .= _format_word($format, $word);
      }
    }
    $output .= "\n";
    $addr += $chunk_length;
  }
  $output;
}

sub _format_word {
  my($format, $data) = @_;

  # big endian
  my @bytes = map { ord($_) } split(//, $data);
  # make little endian if necessary
  @bytes = reverse(@bytes)
    if($format =~ /</ || ($format !~ />/ && LITTLEENDIAN));
  return join('', map { sprintf('%02X', $_) } @bytes);
}

=head1 SEE ALSO

L<Data::Dumper>

L<Data::HexDump> if your needs are simple

perldoc -f unpack

perldoc -f pack

=head1 INCOMPATIBLE CHANGES

'number_format' is now implemented in terms of 'output_format'.  Your data
will be padded to a multiple of 16 bytes.  Previously-silent code may now
emit warnings.

The mappings are:

  'C'  => '  %4a : %C %C %C %C %C %C %C %C %C %C %C %C %C %C %C %C : %d'
  'S'  => '  %4a : %S %S %S %S %S %S %S %S         : %d'
  'S<' => '  %4a : %S< %S< %S< %S< %S< %S< %S< %S<         : %d'
  'S>' => '  %4a : %S> %S> %S> %S> %S> %S> %S> %S>         : %d'
  'L'  => '  %4a : %L %L %L %L             : %d'
  'L<' => '  %4a : %L< %L< %L< %L<             : %d'
  'L>' => '  %4a : %L> %L> %L> %L>             : %d'
  'Q'  => '  %4a : %Q %Q               : %d'
  'Q<' => '  %4a : %Q< %Q<               : %d'
  'Q>' => '  %4a : %Q> %Q>               : %d'

and of course:

  'V' => 'L<'
  'N' => 'L>'
  'v' => 'S<'
  'n' => 'S>'

=head1 BUGS/LIMITATIONS

Behaviour of %a is not defined if your file is too big.

Behaviour of %NNa is not defined if NN is too big for your sprintf implementation
to handle 0x%0${NN}X.

=head1 FEEDBACK

I welcome constructive criticism and bug reports.  Please report bugs either
by email or via RT:
  L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Hexdumper>

The best bug reports contain a test file that fails with the current
code, and will pass once it has been fixed.  The code repository
is on Github:
  L<git://github.com/DrHyde/perl-modules-Data-Hexdumper.git>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2001 - 2012 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=head1 THANKS TO ...

MHX, for reporting a bug when dumping a single byte of data

Stefan Siegl, for reporting a bug when dumping an ASCII 0

Steffen Winkler, for inspiring me to use proper output formats

=cut

1;
