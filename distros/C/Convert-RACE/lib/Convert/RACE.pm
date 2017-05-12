package Convert::RACE;

use strict;
use vars qw($VERSION @ISA @EXPORT);

BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT = qw(to_race from_race);

    $VERSION = '0.07';
}

use Carp ();
use Convert::Base32 qw(encode_base32 decode_base32);

use constant COMPRESS_EXCEPTION		=> 'Invalid encoding to compress';
use constant DECOMPRESS_EXCEPTION	=> 'Invalid format to decompress';

my $_prefix_tag = 'bq--';

sub prefix_tag {
    my $class = shift;
    $_prefix_tag = $_[0] if (@_);
    return $_prefix_tag;
}

sub to_race($) {
    my $str = shift;

    # 2.2.1 Check the input string for disallowed names
    unless (_include_disallowed_names($str)) {
        Carp::croak('String includes no internationalized characters');
    }

    # 2.2.2 Compress the pre-converted string
    my $compressed = _compress($str);

    # 2.2.3 Check the length of the compressed string
    if (length($compressed) > 36) {
        Carp::croak('String too long');
    }

    # 2.2.4 Encode the compressed string with Base32
    my $encoded = encode_base32($compressed);

    # 2.2.5 Prepend "bq--" to the encoded string and finish
    return $_prefix_tag . $encoded;
}

sub from_race($) {
    my $str = lc(shift);

    # 2.3.1 Strip the "bq--"
    $str =~ s/^$_prefix_tag// or Carp::croak("String not begin with $_prefix_tag");

    # 2.3.2 Decode the stripped string with Base32
    my $decoded = decode_base32($str);

    # 2.3.3 Decompress the decoded string
    my $decompressed = _decompress($decoded);

    # 2.3.4 Check the internationalized string for disallowed names
    unless (_include_disallowed_names($decompressed)) {
        Carp::croak('Decoded string includes no internationalized characters');
    }

    return $decompressed;
}


sub _compress($) {
    my $str = shift;

    my @unique_upper_octet = _make_uniq_upper_octet($str);
    if (@unique_upper_octet > 2 ||
	 (@unique_upper_octet == 2 &&
	  ! grep { $_ eq "\x00" } @unique_upper_octet)) {
	# from more than 2 rows
	# or from 2 rows neither of with is 0
	return "\xD8" . $str;
    }

    my $u1 = @unique_upper_octet == 1
	? $unique_upper_octet[0] : (grep { $_ ne "\x00" } @unique_upper_octet)[0];
    if ($u1 =~ /^[\xd8-\xdc]{1}$/) {
        Carp::croak(COMPRESS_EXCEPTION);
    }

    my $res = $u1;

    while ($str =~ m/(.)(.)/gs) {
	my ($u2, $n1) = ($1, $2);
	if ($u2 eq "\x00" and $n1 eq "\x99") {
	    Carp::croak(COMPRESS_EXCEPTION);
	} elsif ($u2 eq $u1 and $n1 ne "\xff") {
	    $res .= $n1;
	} elsif ($u2 eq $u1 and $n1 eq "\xff") {
	    $res .= "\xff\x99";
	} else {
	    $res .= "\xff$n1";
	}
    }

    return $res;
}


sub _decompress($) {
    my $str = shift;

    # 1)
    my ($u1, $rest) = (substr($str,0,1), substr($str,1));
    if (length($str) == 1) {
        Carp::croak(DECOMPRESS_EXCEPTION);
    }

    if ($u1 eq "\xd8") {
	# 8)
	my $lcheck = $rest;
	if (length($lcheck) % 2) {
	    Carp::croak(DECOMPRESS_EXCEPTION);
	}
	# 9)
	my @unique_upper_octet = _make_uniq_upper_octet($lcheck);
	if (@unique_upper_octet == 1 ||
	    (@unique_upper_octet == 2 &&
	     grep { $_ eq "\x00" } @unique_upper_octet)) {
	    Carp::croak(DECOMPRESS_EXCEPTION);
	}
	# 10)
	return $lcheck;
    } 

    my $buffer = '';
    my $pos = 0;
    # 2)
    while (1) {
	if ($pos == length($rest)) {
	    # 11)
	    if (length($buffer) % 2) {
	        Carp::croak(DECOMPRESS_EXCEPTION);
	    }
	    return $buffer;
	}
	
	my $n1 = substr($rest, $pos, 1);
	if ($n1 eq "\xff") {
	    # 5)
	    if ($pos == length($rest)-1) {
	      Carp::croak(DECOMPRESS_EXCEPTION);
	    }
	    # 6)
	    $pos++;
	    $n1 = substr($rest, $pos, 1);
	    if ($n1 eq "\x99") {
		$buffer .= $u1 . "\xff";
		next;
	    }
	    # 7)
	    $buffer .= "\x00" . $n1;
	    next;
	} elsif ($u1 eq "\x00" and $n1 eq "\x99") {
	    # 3)
	    Carp::croak(DECOMPRESS_EXCEPTION);
	}
	# 4)
	$buffer .= $u1 . $n1;
	next;
    } continue { $pos++; }
}


sub _make_uniq_upper_octet($) {
    my $str = shift;

    my %seen;
    while ($str =~ m/(.)./gs) {
	$seen{$1}++;
    }
    return keys %seen;
}

sub _include_disallowed_names($) {
    # RFC 1035: letter, digit, hyphen
    return $_[0] !~ /^(?:\x00[\x30-\x39\x41-\x5a\x61-\x7a\x2d])*$/;
}


1;
__END__

=head1 NAME

Convert::RACE - Conversion between Unicode and RACE

=head1 SYNOPSIS

  use Convert::RACE;

  $domain = to_race($utf16str);
  $utf16str = from_race($domain);

=head1 DESCRIPTION

This module provides functions to convert between RACE (Row-based
ASCII-Compatible Encoding) and Unicode Encodings.

RACE converts strings with internationalized characters into strings
of US-ASCII that are acceptable as host name parts in current DNS host
naming usage.

See http://www.ietf.org/internet-drafts/draft-ietf-idn-race-03.txt for
more details.

=head1 FUNCTION

Following functions are provided; they are all in B<@EXPORT> array. 
See L<Exporter> for details.

=over 4

=item to_race($utf16)

to_race() takes UTF-16 encoding and returns RACE-encoded strings such
as 'bq--aewrcsy'.

This function throws an exception such as 'String includes no
internationalized characters', 'String too long' and 'Invalid encoding
to compress'. Exceptions are thrown with Carp::croak(), so you can
cath 'em with eval {};

=item from_race($domain_name)

from_race() takes 'bq--' prefixed string and returns original UTF-16
string.

This function throws an exception such as 'String not begin with
bq--', 'Decoded string includes no internationalized characters' and '
Invalid format to decompress'. Exceptions are thrown with
Carp::croak(), so you can cath 'em with eval {};

=back

See L<Unicode::String>, L<Unicode::Map8>, L<Jcode> for Unicode
conversions.

=head1 CLASS METHOD

Following class methods are provided to change the behaviour of
Convert::RACE.

=over 4

=item prefix_tag()

Set and get the domain prefix tag. By default, 'bq--'.

=back

=head1 EXAMPLES

  use Jcode;
  use Unicode::String 'latin1';
  use Convert::RACE 'to_race';

  # EUC-japanese here
  $name = to_race(Jcode->new('ÆüËÜ¸ì','euc')->ucs2);
  
  # or, Latin here
  $name = to_race(latin1($latin_string)->utf16);

  # in doubt of exception
  eval { $name = to_race($utf); };
  if ($@) { 
      warn "Can't encode to RACE: $@";
  }

  # change the prefix
  Convert::RACE->prefix_tag('xx--');


=head1 BIG FAT CAVEAT

=over 4

=item *

This module does B<NOT> implement Nameprep phase. See mDNkit
(http://www.nic.ad.jp/jp/research/idn/mdnkit/download/) for complete
implementations.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>, with much help from Eugen
SAVIN <seugen@serifu.com>, Philip Newton <pne@cpan.org>, Michael J
Schout <mschout@gkg.net>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

There comes B<NO WARRANTY> with this module.

=head1 SEE ALSO

http://www.i-d-n.net/, http://www.ietf.org/internet-drafts/draft-ietf-idn-race-03.txt, RFC 1035, L<Unicode::String>, L<Jcode>, L<Convert::Base32>.

=cut
