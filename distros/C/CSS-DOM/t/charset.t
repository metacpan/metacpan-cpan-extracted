#!/usr/bin/perl -T

use strict; use warnings; no warnings qw 'utf8 parenthesis';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use utf8;

use CSS::DOM;


use tests 4; # options

like CSS::DOM::parse qq|\@charset "utf-8"; {font:'\xc3\xb0'}|
	=>->cssRules->[1]->style->font,
	qr/\xc3\xb0/, 'no decode/encoding_hint param assumes unicode';
like CSS::DOM::parse "{font:'\xc3\xb0'}",
	decode => 1
  =>->cssRules->[0]->cssText, qr/\xf0/,
	'decode => 1 assumes utf-8 in the absence of encoding info';
like CSS::DOM::parse "{font:'\xc3\xb0'}",
	encoding_hint => 'iso-8859-7'
  =>->cssRules->[0]->cssText, qr/\x{393}\260/,
	'encoding_hint implies decode => 1';
like CSS::DOM::parse "{font:'\xc3\xb0'}",
	decode => 1, encoding_hint => 'iso-8859-7'
  =>->cssRules->[0]->cssText,qr/\x{393}\260/,
	'decode => 1 uses encoding_hint in the absence of bom or @charset';


use tests 18; # sniffing
for(
#	['test name',
#	  qq[stylesheet],
#	  rule_number_to_test => qr/.../],

	['utf-8 bom and explicit charset',
	  qq[\xef\xbb\xbf\@charset "utf-8"; {font:'\xc3\xb0'}],
	  1 => qr/\xf0/],

	['utf-8 bomb',
	  qq[\xef\xbb\xbf {font:'\xc3\xb0'}],
	  0 => qr/\xf0/],

	['utf-16be bomb + @charset',
	  qq[\xfe\xff\0\@\0c\0h\0a\0r\0s\0e\0t\0 \0"\0u\0t\0f\0-\0001]
	 .qq[\0006\0"\0;\0 \0{\0f\0o\0n\0t\0:\0'\xab\xcd\0'\0}],
	  1 => qr/\x{abcd}/],

	['apparent utf-16be with @charset',
	  qq[\0\@\0c\0h\0a\0r\0s\0e\0t\0 \0"\0u\0t\0f\0-\0001\0006\0"]
	 .qq[\0;\0 \0{\0f\0o\0n\0t\0:\0'\xab\xcd\0'\0}],
	  1 => qr/\x{abcd}/],

	['utf-16le bomb + @charset',
	  qq[\xff\xfe\@\0c\0h\0a\0r\0s\0e\0t\0 \0"\0u\0t\0f\0-\0001]
	 .qq[\0006\0"\0;\0 \0{\0f\0o\0n\0t\0:\0'\0\xab\xcd'\0}\0],
	  1 => qr/\x{cdab}/],

	['apparent utf-16le with @charset',
	  qq[\@\0c\0h\0a\0r\0s\0e\0t\0 \0"\0u\0t\0f\0-\0001\0006\0"\0]
	 .qq[;\0 \0{\0f\0o\0n\0t\0:\0'\0\xab\xcd'\0}\0],
	  1 => qr/\x{cdab}/],

	['utf-32be bomb + @charset',
	  qq[\0\0\xfe\xff\0\0\0\@\0\0\0c\0\0\0h\0\0\0a\0\0\0r\0\0\0s]
	 .qq[\0\0\0e\0\0\0t\0\0\0 \0\0\0"\0\0\0u\0\0\0t\0\0\0f\0\0\0-]
	 .qq[\0\0\0003\0\0\0002\0\0\0"]
	 .qq[\0\0\0;\0\0\0 \0\0\0{\0\0\0f\0\0\0o\0\0\0n\0\0\0t\0\0\0:]
	 .qq[\0\0\0'\0\x10\xab\xcd\0\0\0'\0\0\0}],
	  1 => qr/\x{10abcd}/],

	['apparent utf-32be with @charset',
	  qq[\0\0\0\@\0\0\0c\0\0\0h\0\0\0a\0\0\0r\0\0\0s]
	 .qq[\0\0\0e\0\0\0t\0\0\0 \0\0\0"\0\0\0u\0\0\0t\0\0\0f\0\0\0-]
	 .qq[\0\0\0003\0\0\0002\0\0\0"]
	 .qq[\0\0\0;\0\0\0 \0\0\0{\0\0\0f\0\0\0o\0\0\0n\0\0\0t\0\0\0:]
	 .qq[\0\0\0'\0\x10\xab\xcd\0\0\0'\0\0\0}],
	  1 => qr/\x{10abcd}/],

	['utf-32le bomb + @charset',
	  qq[\xff\xfe\0\0\@\0\0\0c\0\0\0h\0\0\0a\0\0\0r\0\0\0s]
	 .qq[\0\0\0e\0\0\0t\0\0\0 \0\0\0"\0\0\0u\0\0\0t\0\0\0f\0\0\0-]
	 .qq[\0\0\0003\0\0\0002\0\0\0"]
	 .qq[\0\0\0;\0\0\0 \0\0\0{\0\0\0f\0\0\0o\0\0\0n\0\0\0t\0\0\0:]
	 .qq[\0\0\0'\0\0\0\x10\xab\x0d\0'\0\0\0}\0\0\0],
	  1 => qr/\x{dab10}/],

	['apparent utf-32le with @charset',
	  qq[\@\0\0\0c\0\0\0h\0\0\0a\0\0\0r\0\0\0s]
	 .qq[\0\0\0e\0\0\0t\0\0\0 \0\0\0"\0\0\0u\0\0\0t\0\0\0f\0\0\0-]
	 .qq[\0\0\0003\0\0\0002\0\0\0"]
	 .qq[\0\0\0;\0\0\0 \0\0\0{\0\0\0f\0\0\0o\0\0\0n\0\0\0t\0\0\0:]
	 .qq[\0\0\0'\0\0\0\x10\xab\x0d\0'\0\0\0}\0\0\0],
	  1 => qr/\x{dab10}/],

	['utf-32be bom',
	  qq[\0\0\xfe\xff\0\0\0{\0\0\0f\0\0\0o\0\0\0n\0\0\0t\0\0\0:]
	 .qq[\0\0\0'\0\x10\xab\xcd\0\0\0'\0\0\0}],
	  0 => qr/\x{10abcd}/],

	['utf-32le bom',
	  qq[\xff\xfe\0\0{\0\0\0f\0\0\0o\0\0\0n\0\0\0t\0\0\0:]
	 .qq[\0\0\0'\0\0\0\x10\xab\x0d\0'\0\0\0}\0\0\0],
	  0 => qr/\x{dab10}/],

	['utf-16be bom',
	  qq[\xfe\xff\0{\0f\0o\0n\0t\0:\0'\xab\xcd\0'\0}],
	  0 => qr/\x{abcd}/],

	['utf-16le bom',
	  qq[\xff\xfe{\0f\0o\0n\0t\0:\0'\0\xab\xcd'\0}\0],
	  0 => qr/\x{cdab}/],

	['ebcdic @charset "cp37";',
	  qq[\x7c\x83\x88\x81\x99\xa2\x85\xa3\x40\x7f\x83\x97\xf3\xf7\x7f]
	 .qq[\x5e\x40\xc0\x83\x96\x95\xa3\x85\x95\xa3\x7a\x40\x7f\x95\x81]
	 .qq[\x57\xa5\x85\xa3\x51\x7f\xd0],
	  1 => qr/naïveté/],

	['ebcdic @charset "cp875";',
	  qq[\x7c\x83\x88\x81\x99\xa2\x85\xa3\x40\x7f\x83\x97\xf8\xf7\xf5]
	 .qq[\x7f\x5e\x40\xc0\x83\x96\x95\xa3\x85\x95\xa3\x7a\x40\x7f\x65]
	 .qq[\xae\xbc\xaf\xb6\xaf\xbb\xac\x9f\xac\xba\x7d\xd0],
	  1 => qr/Χρυσόστομος/],

	['IBM1026',
	  qq[\xae\x83\x88\x81\x99\xa2\x85\xa3\x40\xfc\x83\x97\xf1\xf0\xf2]
	 .qq[\xf6\xfc\x5e\x40\x48\x83\x96\x95\xa3\x85\x95\xa3\x7a\x40\xfc]
	 .qq[\x95\x81\x57\xa5\x85\xa3\x51\xfc\x8c],
	  1 => qr/naïveté/],

	['GSM 0338',
	  qq[\0charset "gsm0338"; \e(content: "saut\5"\e)],
	  1 => qr/sauté/],
){
	my $ss = CSS::DOM::parse $$_[1], decode => 1;
#use Data::Dumper; ++$Data::Dumper::Useqq;
#	diag Dumper $@ if $@;
	diag $@ if $@;
	like $ss->cssRules->[$$_[2]]->cssText, $$_[3],
		$$_[0];# or diag Dumper $ss->cssRules->[$$_[2]]->cssText;
}


# ~~~ We need tests for sniffing failures, e.g.:
#     (in ASCII) @charset "utf-16";


use tests 1; # url_fetcher
{
	(my $ss = new CSS::DOM url_fetcher => 
		sub {return "a { foo: \xc3\xb0}", decode => 1 }
	 )->insertRule('@Import "foo.css"',0);
	
	like $ss->cssRules->[0]->styleSheet->cssRules->[0]->cssText,
		qr/\xf0/, 'url_fetcher';
}
