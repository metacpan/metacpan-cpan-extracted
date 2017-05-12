# Data-Hexify.pm -- Perl extension for hexdumping arbitrary data
# RCS Info        : $Id: Data-Hexify.pm,v 1.6 2004/11/05 09:17:14 jv Exp $
# Author          : Johan Vromans
# Created On      : Sat Jun 19 12:31:21 2004
# Last Modified By: Johan Vromans
# Last Modified On: Fri Nov  5 10:17:11 2004
# Update Count    : 37
# Status          : Unknown, Use with caution!

package Data::Hexify;

use 5.006;
use strict;
use warnings;

################ Exporter Section ################

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT      = qw(Hexify);
our %EXPORT_TAGS = ( all => [ @EXPORT ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{all} } );

################ Preamble ################

our $VERSION = '1.00';

use Carp;

my $usage = "Usage: Hexify(<data ref> [ , <hash or hashref> ])\n";

################ Code ################

sub Hexify {

    use bytes;

    # First argument: data or reference to the data.
    my $data = shift;
    my $dr = ref($data) ? $data : \$data;

    my $start  = 0;		# first byte to dump
    my $lastplusone = length($$dr); # first byte not to dump
    my $align  = 1;		# align
    my $chunk  = 16;		# bytes per line
    my $first  = $start;	# number of 1st byte
    my $dups   = 0;		# output identical lines
    my $group  = 1;		# group per # bytes

    my $show   = sub { my $t = shift;
		       $t =~ tr /\000-\037\177-\377/./;
		       $t;
		 };

    # Check for second argument.
    if ( @_ ) {

	# Second argument: options hash or hashref.
	my %atts = ( align      => $align,
		     chunk      => $chunk,
		     showdata   => $show,
		     start      => $start,
		     length     => $lastplusone - $start,
		     duplicates => $dups,
		     first      => undef,
		     group	=> 1,
		   );

	if ( @_ == 1 ) {	# hash ref
	    my $a = shift;
	    croak($usage) unless ref($a) eq 'HASH';
	    %atts = ( %atts, %$a );
	}
	elsif ( @_ % 2 ) {	# odd
	    croak($usage);
	}
	else {			# assume hash
	    %atts = ( %atts, @_ );
	}

	my $length;
	$start  = delete($atts{start});
	$length = delete($atts{length});
	$align  = delete($atts{align});
	$chunk  = delete($atts{chunk});
	$show   = delete($atts{showdata});
	$dups   = delete($atts{duplicates});
	$group  = delete($atts{group});
	$first  = defined($atts{first}) ? $atts{first}  : $start;
	delete($atts{first});

	if ( %atts ) {
	    croak("Hexify: unrecognized options: ".
		  join(" ", sort(keys(%atts))));
	}

	# Sanity
	$start = 0 if $start < 0;
	$lastplusone = $start + $length;
	$lastplusone = length($$dr)
	  if $lastplusone > length($$dr);
	$chunk = 16 if $chunk <= 0;
	if ( $chunk % $group ) {
	    croak("Hexify: chunk ($chunk) must be a multiple of group ($group)");
	}
    }
    $group *= 2;

    #my $fmt = "  %04x: %-" . (3 * $chunk - 1) . "s  %-" . $chunk . "s\n";
    my $fmt = "  %04x: %-" . (2*$chunk + $chunk/($group/2) - 1) . "s  %-" . $chunk . "s\n";
    my $ret = "";

    if ( $align && (my $r = $first % $chunk) ) {
	# This piece of code can be merged into the main loop.
	# However, this piece is only executed infrequently.
	my $lead = " " x $r;
	my $firstn = $chunk - $r;
	$first -= $r;
	my $n = $lastplusone - $start;
	$n = $firstn if $n > $firstn;
	my $ss = substr($$dr, $start, $n);
	(my $hex = $lead . $lead . unpack("H*",$ss)) =~ s/(.{$group})(?!$)/$1 /g;
	$ret .= sprintf($fmt, $first, $hex,
			$lead . $show->($ss));
	$start += $n;
	$first += $chunk;
    }

    my $same = "";
    my $didsame = 0;
    my $dupline = "          |\n";

    while ( $start < $lastplusone ) {
	my $n = $lastplusone - $start;
	$n = $chunk if $n > $chunk;
	my $ss = substr($$dr, $start, $n);

	if ( !$dups ) {
	    if ( $ss eq $same && ($start + $n) < $lastplusone ) {
		if ( !$didsame ) {
		    $ret .= $dupline;
		    $same = $ss;
		    $didsame = 1;
		}
		next;
	    }
	    else {
		$same = "";
		$didsame = 0;
	    }
	}
	$same = $ss;

	(my $hex = unpack("H*", $ss)) =~ s/(.{$group})(?!$)/$1 /g;
	$ret .= sprintf($fmt, $first, $hex, $show->($ss));
    }
    continue {
	$start += $chunk;
	$first += $chunk;
    }

    $ret;
}

################ Selftest ################

unless ( caller ) {

    package main;
    my $data = pack("C*", 0..255);
    my $res = "";
    $res .= Data::Hexify::Hexify(\$data,
				 length => 48);
    $res .= Data::Hexify::Hexify(\$data,
				 start => 14, length => 48);
    $res .= Data::Hexify::Hexify(\$data,
				 start => 3, length => 4);
    $res .= Data::Hexify::Hexify(\$data,
				 start => 3, length => 4, first => 7);
    my $exp = <<'EOD';
  0000: 00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f  ................
  0010: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0020: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
  0000:                                           0e 0f                ..
  0010: 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f  ................
  0020: 20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f   !"#$%&'()*+,-./
  0030: 30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d        0123456789:;<=  
  0000:          03 04 05 06                                ....         
  0000:                      03 04 05 06                        ....     
EOD

    die("Selftest error:\n".
	"Got:\n$res".
	"Expected:\n$exp") unless $res eq $exp;
}

################ End of Selftest ################

__END__

=head1 NAME

Data::Hexify - Perl extension for hexdumping arbitrary data

=head1 SYNOPSIS

  use Data::Hexify;
  print STDERR Hexify(\$blob);

=head1 DESCRIPTION

This module exports one subroutine: C<Hexify>.

C<Hexify> formats arbitrary (possible binary) data into a format
suitable for hex dumps in the style of C<xd> or C<hexl>.

The first, or only, argument to C<Hexify> contains the data, or a
reference to the data, to be hexified. Hexify will return a string that
prints as follows:

  0000: 70 61 63 6b 61 67 65 20 44 61 74 61 3a 3a 48 65  package Data::He
  0010: 78 69 66 79 3b 0a 0a 75 73 65 20 35 2e 30 30 36  xify;..use 5.006

and so on. At the left is the (hexadecimal) index of the data, then a
number of hex bytes, followed by the chunk of data with unprintables
replaced by periods.

The optional second argument to C<Hexify> must be a hash or a hash
reference, containing values for any of the following parameters:

=over 4

=item first

The first byte of the data to be processed. Default is to start from
the beginning of the data.

=item length

The number of bytes to be processed. Default is to proceed all data.

=item chunk

The number of bytes to be processed per line of output. Default is 16.

=item group

The number of bytes to be grouped together. Default is 1 (no
grouping). If used, it must be a divisor of the chunk size.

=item duplicates

When set, duplicate lines of output are suppressed and replaced by a
single line reading C<**SAME**>.

Duplicate suppression is enabled by default.

=item showdata

A reference to a subroutine that is used to produce a printable string
from a chunk of data. By default, a subroutine is used that replaces
unwanted bytes by periods.

The subroutine gets the chunk of data passed as argument, and should
return a printable string of at most C<chunksize> characters.

=item align

Align the result to C<chunksize> bytes. This is relevant only when
processing data not from the beginning. For example, when C<first> is 10,
the result would become:

  0000:                ...    74 61 3a 3a 48 65            ta::He
  0010: 78 69 66 79 3b ... 65 20 35 2e 30 30 36  xify;..use 5.006
  ... and so on ...

Alignment is on by default. Without alignment, the result would be:

  000a: 74 61 3a 3a 48 ... 79 3b 0a 0a 75 73 65  ta::Hexify;..use
  001a: 20 35 2e 30 30 ... 73 65 20 73 74 72 69   5.006;.use stri
  ... and so on ...

=item start

Pretend that the data started at this byte (while in reality it starts
at byte C<first>). The above example, with C<< start => 0 >>, becomes:

  0000: 74 61 3a 3a 48 ... 79 3b 0a 0a 75 73 65  ta::Hexify;..use
  0010: 20 35 2e 30 30 ... 73 65 20 73 74 72 69   5.006;.use stri
  ... and so on ...

=back

=head1 SEE ALSO

L<Data::Dumper>, L<YAML>.

=head1 AUTHOR

Johan Vromans, E<lt>jvromans@squirrel.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Squirrel Consultancy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any other version of Perl 5 you may have available.

=cut
