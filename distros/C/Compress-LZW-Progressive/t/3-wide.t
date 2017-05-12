#!/usr/bin/perl

use strict;
use warnings;
use Test::More qw(no_plan);

BEGIN {
	use_ok('Compress::LZW::Progressive');
}

use Compress::LZW::Progressive;

my $codec = Compress::LZW::Progressive->new( bits => 12, debug => 0 );

isa_ok($codec, 'Compress::LZW::Progressive');

SKIP: {
	## Convert an encoded string into unicode

	eval {
		require MIME::Words;
		require Encode;
		require Unicode::Transform;
	};
	if ($@) {
		print STDERR "Requires MIME::Words, Encode and Unicode::Transform\n";
		skip "Wide string with nulls compress/decompress", 1;
	}

	my $str = "=?ISO-8859-1?B?VGhlIFJlc291cmNlIFs1LzMwLzIwMDddOiAgWW91ciBCaWdnZXN0IEFzc2V0l0N1c3RvbWVyIFN1Y2Nlc3MgU3RvcmllcyEA?=";

	{
		my $new_str;
		foreach my $decode_ref (MIME::Words::decode_mimewords($str)) {
			if (int @$decode_ref == 2) {
				# decoding iso-2022-jp in test cases yielded '\x8a\x99...' instead of utf8 chars
				$decode_ref->[1] = 'shiftjis' if $decode_ref->[1] =~ /^iso-2022-jp/;
				eval {
					Encode::from_to($decode_ref->[0], $decode_ref->[1], 'utf8');
				};
			}
			$new_str .= $decode_ref->[0];
		}
		$str = $new_str;

		# Decode utf8 code pairs to wide unicode
		my $unicode;

		# May throw exception 'Wide character in subroutine entry'
		eval {
			$unicode = utf8_to_unicode($str);
		};
		if ($@) {
			$str = $@;
		}
		else {
			# Convert wide chars into XML entities
			$unicode =~ s/(.)/ord($1) > 255 ? "&#" . ord($1) . ";" : $1/eg;

			$str = $unicode;
		}

		# Finally, XML 1.0 doesn't allow any bare or escaped control codes
		$str =~ s/(.)/ord($1) > 0 && ord($1) < 32 ? '' : $1/eg;
	}

	## Now pass this unicode string to the compressor

	my $lzw = $codec->compress($str);
	my $plain = $codec->decompress($lzw);
	$codec->reset;

	{
		use bytes;
=cut
		my @plain = split //, $plain;
		my @str = split //, $str;

		print "last str: ".ord($str[ $#str ])."\n";

		printf "Plain: (%d, %d) %s\n", length($plain), int(@plain), $plain;
		printf "  str: (%d, %d) %s\n", length($str), int(@str), $str;
=cut

		ok($plain eq $str, "Wide string with nulls compress/decompress");
	}
};

## Test nulls

my $str = 'Test nulls: ';
$str .= chr(0) foreach 1..10;
$str .= ': done testing';

my $lzw = $codec->compress($str);
my $plain = $codec->decompress($lzw);
$codec->reset;

ok($plain eq $str, "String with nulls compress/decompress");
