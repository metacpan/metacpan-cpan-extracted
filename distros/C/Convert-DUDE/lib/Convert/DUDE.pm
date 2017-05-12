package Convert::DUDE;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.02';

use Unicode::String qw(utf8);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT = qw(to_dude from_dude);
    @EXPORT_OK = qw(dude_encode dude_decode);
    %EXPORT_TAGS = (
	all => [ @EXPORT, @EXPORT_OK ],
	encode => [ @EXPORT_OK ],
    );
}

{
    my $prefix = 'dq--';	# default
    sub prefix {
	shift;
	$prefix = shift if @_;
	$prefix;
    }
}

sub _die { require Carp; Carp::croak @_; }

# XXX don't use Convert::Base32
# XXX because Base32 tables in RACE / DUDE are different ...
use vars qw(%bits2char %char2bits);

%bits2char = qw@
00000 a
00001 b
00010 c
00011 d
00100 e
00101 f
00110 g
00111 h
01000 i
01001 j
01010 k
01011 m
01100 n
01101 p
01110 q
01111 r
10000 s
10001 t
10010 u
10011 v
10100 w
10101 x
10110 y
10111 z
11000 2
11001 3
11010 4
11011 5
11100 6
11101 7
11110 8
11111 9
    @; # End of qw

%char2bits = reverse %bits2char;

=begin algorithm

    let prev = 0x60
    for each input integer n (in order) do begin
      if n == 0x2D then output hyphen-minus
      else begin
        let diff = prev XOR n
        represent diff in base 16 as a sequence of quartets,
          as few as are sufficient (but at least one)
        prepend 0 to the last quartet and 1 to each of the others
        output a base-32 character corresponding to each quintet
        let prev = n
      end
    end

=end algorithm

=cut

sub dude_encode ($) {
    my $input = utf8(shift);

    my $output;
    my $prev = 0x60;
    for my $i (0 .. $input->length-1) {
	my $n = $input->substr($i, 1)->ord;
	if ($n == 0x2d) {
	    $output .= '-';
	    next;
	}

	my $diff = $prev ^ $n;

	my @quartets = unpack('B*', pack('n*', $diff)) =~ m/(.{4})/gs;
	shift @quartets while (@quartets && $quartets[0] eq '0000');

	my @fb_quartets = ((map { '1' . $_ } @quartets[0..$#quartets - 1]),
			   '0' . $quartets[-1]);
	$output .= $bits2char{$_} for (@fb_quartets);
	$prev = $n;
    }
    return $output;
}

sub to_dude($) {
    my $domain = shift;
    return __PACKAGE__->prefix . dude_encode($domain);
}

=begin algorithm

    let prev = 0x60
    while the input string is not exhausted do begin
      if the next character is hyphen-minus
      then consume it and output 0x2D
      else begin
        consume characters and convert them to quintets until
          encountering a quintet whose first bit is 0
        fail upon encountering a non-base-32 character or end-of-input
        strip the first bit of each quintet
        concatenate the resulting quartets to form diff
        let prev = prev XOR diff
        output prev
      end
    end
    encode the output sequence and compare it to the input string
    fail if they do not match (case-insensitively)

=end algorithm

=cut

sub dude_decode ($) {
    my $input = lc shift;

    my $prev = 0x60;
    my @input = split //, $input;

    my $output = Unicode::String->new;
    while (@input) {
	if ($input[0] eq '-') {
	    $output->append(Unicode::String::uchr(0x2d));
	    shift @input;
	    next;
	}

	my @quintets;
	CONSUME: while (1) {
	    unless (exists $char2bits{$input[0]}) {
		_die "encountered non-base-32 character: $input[0]";
	    }
	    unless (@input) {
		_die "reached end-of-input.";
	    }

	    my $quintet = $char2bits{shift @input};
	    push @quintets, $quintet;
	    last CONSUME if substr($quintet, 0, 1) eq '0';
	}

	my $diff = 0;
	my $order = 0;
	for my $quintet (reverse @quintets) {
	    $diff += ord(pack('B*', '0000' . substr($quintet, 1))) * (16 ** $order++);
	}
	$prev = $prev ^ $diff;
	$output->append(Unicode::String::uchr($prev));
    }

    unless (dude_encode($output->utf8) eq $input) {
	_die "uniqueness check (paranoia) failed.";
    }

    return $output->utf8;
}

sub from_dude ($) {
    my $dude = shift;
    my $prefix = __PACKAGE__->prefix;
    $dude =~ s/^$prefix//o;
    return dude_decode($dude);
}


1;

__END__

=head1 NAME

Convert::DUDE - Conversion between Unicode and DUDE

=head1 SYNOPSIS

  use Convert::DUDE ':all';

  # handles 'dq--' prefix
  $domain  = to_dude($utf8);
  $utf8    = from_dude($domain);

  # don't care about 'dq--' prefix
  # not exported by default	      
  $dudestr = dude_encode($utf8);
  $utf8    = dude_decode($dudestr);

=head1 DESCRIPTION

This module provides functions to convert between DUDE (Differential
Unicode Domain Encoding) and Unicode encodings.

Quoted from http://www.i-d-n.net/draft/draft-ietf-idn-dude-02.txt

  DUDE is a reversible transformation from a sequence of nonnegative
  integer values to a sequence of letters, digits, and hyphens (LDH
  characters).  DUDE provides a simple and efficient ASCII-Compatible
  Encoding (ACE) of Unicode strings for use with Internationalized
  Domain Names.

=head1 FUNCTIONS

Following two functions are exported to your package when you use
Convert::DUDE.

=over 4

=item to_dude

  $domain = to_dude($utf8);

takes UTF8-encoded string, encodes it in DUDE and adds 'dq--' prefix
in front.

=item from_dude

  $utf8 = from_dude($domain);

takes 'dq--' prefixed DUDE encoded string and decodes it to original
UTF8 strings.

=back

Following two functions can be exported to your package when you
import them explicitly.

=over 4

=item dude_encode

  $dude = dude_encode($utf8);

takes UTF8-encoded string, encodes it in DUDE. Note that it doesn't
care about 'dq--' prefix.

=item dude_decode

  $utf8 = dude_decode($dude);

takes DUDE encoded string and decodes it to original UTF8
strings. Note that it doesn't care about 'dq--' prefix.

=back

Those functions above may throw exeptions in case of error. You may
have to catch 'em with eval block.

=head1 CLASS METHODS

=over 4

=item prefix

  $prefix = Convert::DUDE->prefix;
  Convert::DUDE->prefix('xx--');

gets/sets DUDE prefix. 'dq--' for default.

=back

=head1 EXAMPLES

Here's a sample code which does RACE-DUDE conversion.

  use Convert::RACE;
  use Convert::DUDE;
  use Unicode::String qw(utf16);
	       
  my $race = "bq--aewrcsy";

  eval {
      my $utf16 = from_race($race);
      my $dude = to_dude(utf16($utf16)->utf8);
      print "RACE: $race => DUDE: $dude\n";
  };

  if ($@) {
      warn "Conversion failed: $@";
  }
  
=head1 CAVEATS

=over 4

=item *

There's no constraints on the input. See internet draft for nameprep
about IDN input validation.

=back

=head1 TODO

=over 4

=item *

Consider mixed-case annotation. See internet draft for DUDE for
details.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This module comes without warranty of any kind.

=head1 SEE ALSO

L<Convert::RACE>, http://www.i-d-n.net/, http://www.i-d-n.net/draft/draft-ietf-idn-dude-02.txt, L<Unicode::String>, L<Jcode>

=cut
