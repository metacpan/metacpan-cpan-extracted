#!/usr/bin/perl
# $Id: 00-util.t 284 2006-12-01 07:51:49Z chronos $

use Test::More tests => 101;
use strict;
use warnings;

BEGIN {
	use_ok 'BBCode::Util';
	BBCode::Util->import(':ALL');
}

foreach(qw(Foo=Foo.pm Foo::Bar=Foo/Bar.pm)) {
	my($pkg,$file) = split /=/;
	is(pkgFilename($pkg), $file, "pkgFilename sanity check ($pkg)");
}

foreach(
	[ q(),		q(''),			q(""),			q(),		q()		],
	[ q(ab),	q('ab'),		q("ab"),		q(ab),		q(ab)	],
	[ q(a\\b),	q('a\\\\b'),	q("a\\\\b"),	q(a\\\\b),	undef	],
	[ q(a'b),	q('a\\'b'),		q("a'b"),		q(a\\'b),	undef	],
	[ q(a"b),	q('a"b'),		q("a\\"b"),		q(a\\"b),	undef	],
) {
	my($orig,$q,$qq,$bs,$raw) = @$_;
	is(quoteQ($orig),	$q,		"quoteQ sanity check ($orig)");
	is(quoteQQ($orig),	$qq,	"quoteQQ sanity check ($orig)");
	is(quoteBS($orig),	$bs,	"quoteBS sanity check ($orig)");
	is(quoteRaw($orig),	$raw,	"quoteRaw sanity check ($orig)");
}

foreach(
	[ '1',		1 ],
	[ 'true',	1 ],
	[ 'yes',	1 ],
	[ 'on',		1 ],
	[ '0',		0 ],
	[ 'false',	0 ],
	[ 'no',		0 ],
	[ 'off',	0 ],
) {
	my($str,$val) = @$_;
	is(parseBool($str), $val, "parseBool sanity check ($str)");
}

foreach(
	[ '0'		=>    0 ],
	[ '1'		=>    1 ],
	[ '42'		=>   42 ],
	[ '-1'		=>   -1 ],
	[ '-42'		=>  -42 ],
	[ '1_000'	=> 1000 ],
	[ '1,000'	=> 1000 ],
	[ ' 1 000 '	=> 1000 ],
	[ '0x'		=> undef ],
) {
	my($str,$val) = @$_;
	is(parseInt($str), $val, "parseInt sanity check ($str)");
}

foreach(
	[ '0'		=>    0.00000	],
	[ '+'		=>    0.00000	],
	[ '-'		=>    0.00000	],
	[ '.'		=>    0.00000	],
	[ '+42'		=>   42.00000	],
	[ '-23'		=>  -23.00000	],
	[ '1.'		=>    1.00000	],
	[ '1e3'		=> 1000.00000	],
	[ '.25'		=>    0.25000	],
	[ '25e-2'	=>    0.25000	],
	[ '.42e+2'	=>   42.00000	],
	[ '4e.5'	=>   12.64911	],
) {
	my($str,$val) = @$_;
	my $approx_num = sprintf "%.5f", parseNum($str);
	my $approx_val = sprintf "%.5f", $val;
	is($approx_num, $approx_val, "parseNum sanity check ($str)");
}

foreach (
	[ '&amp;'		=> 'amp' ],
	[ '&lt;'		=> 'lt' ],
	[ '&gt;'		=> 'gt' ],
	[ '&quot;'		=> 'quot' ],
	[ '&copy;'		=> 'copy' ],
	[ '&trade;'		=> 'trade' ],
	[ '&euro;'		=> 'euro' ],
	[ '&foo;'		=> undef ],
	[ '&#8482;'		=> '#x2122' ],
	[ '&#x2122;'	=> '#x2122' ],
	[ '&#o20442;'	=> '#x2122' ],
	[ '&#b0010000100100010;' => '#x2122' ],
	[ '0x2122'		=> '#x2122' ],
	[ 'U+2122'		=> '#x2122' ],
) {
	my($str,$val) = @$_;
	is(parseEntity($str), $val, "parseEntity sanity check ($str)");
}

foreach(
	[ 'xx-large'	=> 'xx-large' ],
	[ 'x-small'		=>  'x-small' ],
	[ 'medium'		=>   'medium' ],
	[ 'x-medium'	=>     undef  ],

	[ 'larger'		=>  'larger' ],
	[ 'smaller'		=> 'smaller' ],

	[ '12pt'		=>   '12pt' ],
	[ '1 pc'		=>    '1pc' ],
	[ '0.5 in'		=>  '0.5in' ],
	[ '0.7 cm'		=>  '0.7cm' ],
	[ '4.5 mm'		=>  '4.5mm' ],
	[ '15 px'		=>   '15px' ],
	[ '4 ex'		=>    '4ex' ],
	[ '2 em'		=>    '2em' ],
	[ '6pt'			=>    '8pt' ],
	[ '75pt'		=>   '72pt' ],
	[ '1.5in'		=>    '1in' ],
	[ '100cm'		=> '2.54cm' ],

	[ '100%'		=>    '100%' ],
	[ '250%'		=>    '250%' ],
	[  '75%'		=>     '75%' ],
	[  '50%'		=> '66.667%' ],
	[ '800%'		=>    '600%' ],

	[ '0'			=> 'xx-small' ],
	[ '1'			=>  'x-small' ],
	[ '2'			=>    'small' ],
	[ '3'			=>   'medium' ],
	[ '4'			=>    'large' ],
	[ '5'			=>  'x-large' ],
	[ '6'			=> 'xx-large' ],
	[ '7'			=>     '300%' ],

	[ '+1'			=>     '125%' ],
	[ '+2'			=>  '156.25%' ],
	[ '-1'			=>      '85%' ],
	[ '-2'			=>   '72.25%' ],
) {
	my($str,$val) = @$_;
	is(parseFontSize($str), $val, "parseFontSize sanity check ($str)");
}

# vim:set ft=perl:
