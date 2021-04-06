# -*- mode: Perl -*-

##########################################################################
#
#   HexDump.pm  -  Hexadecial Dumper
#
# Copyright (c) 1998, 1999, Fabien Tassin <fta@oleane.net>
##########################################################################
# ABSOLUTELY NO WARRANTY WITH THIS PACKAGE. USE IT AT YOUR OWN RISKS.
##########################################################################

package Data::HexDump;
$Data::HexDump::VERSION = '0.04';
use 5.006;
use strict;
use warnings;

use parent 'Exporter';
use Carp;
use FileHandle;

our @EXPORT = qw( HexDump );

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->{'readsize'} = 128;
  return $self;
}

sub DESTROY {
  my $self = shift;
  $self->{'fh'}->close if defined $self->{'file'};
}

sub file {
  my $self = shift;
  my $file = shift;
  $self->{'file'} = $file if defined $file;
  $self->{'file'};
}

sub fh {
  my $self = shift;
  my $fh = shift;
  $self->{'fh'} = $fh if defined $fh;
  $self->{'fh'};
}

sub data {
  my $self = shift;
  my $data = shift;
  $self->{'data'} = $data if defined $data;
  $self->{'data'};
}

sub block_size {
  my $self = shift;
  my $bs = shift;
  $self->{'blocksize'} = $bs if defined $bs;
  $self->{'blocksize'};
}

sub dump {
  my $self = shift;

  my $out;
  my $l;
  $self->{'i'} = 0 unless defined $self->{'i'};
  $self->{'j'} = 0 unless defined $self->{'j'};
  my $i = $self->{'i'};
  my $j = $self->{'j'};
  unless ($i || $j) {
    $out = "          ";
    $l = "";
    for (my $i = 0; $i < 16; $i++) {
      $out .= sprintf "%02X", $i;
      $out .= " " if $i < 15;
      $out .= "- " if $i == 7;
      $l .= sprintf "%X", $i;
    }
    $i = $j = 0;
    $out .= "  $l\n\n";
  }
  return undef if $self->{'eod'};
  $out .= sprintf "%08X  ", $j * 16;
  $l = "";
  my $val;
  while (($val = $self->get) ne '') {
    while (length $val && defined (my $v = substr $val, 0, 1, '')) {
      $out .= sprintf "%02X", ord $v;
      $out .= " " if $i < 15;
      $out .= "- " if $i == 7 &&
                      (length $val || !($self->{'eod'} || length $val));
      $i++;
      $l .= ord($v) >= 0x20 && ord($v) <= 0x7E ? $v : ".";
      if ($i == 16) {
        $i = 0;
        $j++;
        $out .= "  " . $l;
        $l = "";
        $out .= "\n";
        if (defined $self->{'blocksize'} && $self->{'blocksize'} &&
                    ($j - $self->{'j'}) > $self->{'blocksize'} / 16) {
          $self->{'i'} = $i;
          $self->{'j'} = $j;
          $self->{'val'} = $val;
          return $out;
        }
        $out .= sprintf "%08X  ", $j * 16 if length $val || !length $val &&
                                             !$self->{'eod'};
      }
    }
  }
  if ($i || (!$i && !$j)) {
    $out .= " " x (3 * (17 - $i) - 2 * ($i > 8));
    $out .= "$l\n";
  }
  $self->{'i'} = $i;
  $self->{'j'} = $j;
  $self->{'val'} = $val;
  return $out;
}

# get data from different sources (scalar, filehandle, file..)
sub get {
  my $self = shift;

  my $buf;
  my $length = $self->{'readsize'};
  undef $self->{'val'} if defined $self->{'val'} && ! length $self->{'val'};
  if (defined $self->{'val'}) {
    $buf = $self->{'val'};
    undef $self->{'val'};
  }
  elsif (defined $self->{'data'}) {
    $self->{'data_offs'} = 0 unless defined $self->{'data_offs'};
    my $offset = $self->{'data_offs'};
    $buf = substr $self->{'data'}, $offset, $length;
    $self->{'data_offs'} += length $buf;
    $self->{'eod'} = 1 if $self->{'data_offs'} == length $self->{'data'};
  }
  elsif (defined $self->{'fh'}) {
    read $self->{'fh'}, $buf, $length;
    $self->{'eod'} = eof $self->{'fh'};
  }
  elsif (defined $self->{'file'}) {
    $self->{'fh'} = FileHandle->new($self->{'file'});
    read $self->{'fh'}, $buf, $length;
    $self->{'eod'} = eof $self->{'fh'};
  }
  else {
    print "Not yet implemented\n";
  }
  $buf;
}

sub HexDump ($) {
  my $val = shift;

  my $f = Data::HexDump->new();
  $f->data($val);
  $f->dump;
}

1;

=head1 NAME

Data::HexDump - Hexadecial Dumper

=head1 SYNOPSIS

Functional interface:

  use Data::HexDump;
  print HexDump($data_string);

OO interface:

  use Data::HexDump;
  my $dumper = Data::HexDump->new();
  print while $_ = $dumper->dump;

=head1 DESCRIPTION

This module will generate a hexadecimal dump of a data string or file.
You can either use the exported function,
as shown in the SYNOPSIS above,
or the OO interface, described below.

The second example from the SYNOPSIS generated this output:

           00 01 02 03 04 05 06 07 - 08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF

 00000000  23 21 2F 75 73 72 2F 62 - 69 6E 2F 70 65 72 6C 0A  #!/usr/bin/perl.
 00000010  75 73 65 20 73 74 72 69 - 63 74 3B 0A 75 73 65 20  use strict;.use
 00000020  77 61 72 6E 69 6E 67 73 - 3B 0A 0A 70 72 69 6E 74  warnings;..print
 00000030  20 22 48 65 6C 6C 6F 2C - 20 77 6F 72 6C 64 5C 6E   "Hello, world\n
 00000040  22 3B 0A                                           ";.

The result is returned in a string.
Each line of the result consists of the offset in the
source in the leftmost column of each line,
followed by one or more columns of data from the source in hexadecimal.
The rightmost column of each line shows the printable characters
(all others are shown as single dots).

=head2 Functional Interface

This module exports a single function, C<HexDump>,
which takes a scalar value and returns a string which
contains the hexdump of the passed data.


=head2 OO Interface

You first construct a C<Data::HexDump> object,
then tell it where to get the data from,
and then generate the hex dump:

    my $dh = Data::HexDump->new();

    $dh->data($scalar);      # dump the data in this scalar
    $dh->fh($fh);            # read this filehandle
    $dh->file($filename);    # read this file and dump contents

    print while $_ = $dh->dump;

The different potential sources for data are considered
in the order given above,
so if you pass to the C<data> method,
then any subsequent calls to C<fh()> or C<file()>
will have no effect.

=head1 SEE ALSO

L<Data::Hexify>, by Johan Vromans, is another simple option,
similar to this module. Last release in 2004.

L<Data::Hexdumper> (by David Cantrell, DCANTRELL)
is another hex dumper,
with more features than this module.

L<App::colourhexdump> (by Kent Fredric, RIP)
provides a script which gives colourised output
with character class highlighting.

L<Data::HexDump::Range> provides more functions, colour output,
and the ability to skip uninteresting parts of the input data.

L<Data::HexDump::XXD> provides hex dumps like xxd.
It doesn't say what xxd is, or provide a link,
and there's no example output.
But if you know and like xxd, this might be the one for you!

L<Devel::Hexdump> provides some configuration options,
but there are other more featured modules,
and this one doesn't have example output in the doc.

L<Data::Peek> is a collection of functions for displaying data,
including C<DHexDump> which generates a simple hex dump
from a string.

L<String::HexConvert> will convert ASCII strings to hex and reverse.


=head1 AUTHOR

Fabien Tassin E<lt>fta@oleane.netE<gt>


=head1 COPYRIGHT

Copyright (c) 1998-1999 Fabien Tassin. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
