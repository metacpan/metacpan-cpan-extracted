use Test2::V0 -no_pragmas => 1;

use warnings;
use strict;

use Test::Command::Simple;

use Encode::Locale;
use Encode 2.12 qw(decode encode);
use Path::Tiny 0.053;

if ( $Encode::Locale::ENCODING_LOCALE ne 'UTF-8' ) {
	skip_all
		"locale encoding is $Encode::Locale::ENCODING_LOCALE - we need UTF-8";
}

plan 13;

diag 'locale encoding: ', $Encode::Locale::ENCODING_LOCALE;

my @CMD = ( $^X, 'bin/licensecheck' );
if ( $ENV{'LICENSECHECK'} ) {
	@CMD = ( $ENV{'LICENSECHECK'} );
}
elsif ( path('blib')->exists ) {
	@CMD = ('blib/script/licensecheck');
}
diag "executable: @CMD";

push @CMD, qw(--machine --debug --copyright);

my $basic
	= "t/encoding/copr-utf8.h\tGNU General Public License v2.0 or later\t2004-2015 Oliva 'f00' Oberto / 2001-2010 Paul 'bar' Stevénsön\n";
my $basic_utf8           = encode( 'utf8', $basic );
my $basic_utf8_as_latin1 = decode( 'iso-8859-1', encode( 'utf8', $basic ) );

my $extended
	= "t/encoding/copr-iso8859.h\tGNU General Public License, Version 2 [obsolete FSF postal address (Temple Place)]\t2011 Heinrich Müller <henmull\@src.gnome.org>\n";
my $extended_latin1 = encode( 'iso-8859-1', $extended );

my $japanese
	= "t/encoding/README.gs550j\tUNKNOWN\t1999 大森紀人 (ohmori\@p.chiba-u.ac.jp) / 1999 Norihito Ohmori. / 1996-1999 Daisuke SUZUKI.\n";

# TODO: generate japanese mojibake
my $japanese_ujis_as_latin1
	= "t/encoding/README.gs550j\tUNKNOWN\t1999 Âç¿¹µª¿Í (ohmori\@p.chiba-u.ac.jp) / 1999 Norihito Ohmori. / 1996-1999 Daisuke SUZUKI.\n";
my $japanese_ujis_raw = $japanese_ujis_as_latin1;
utf8::upgrade($japanese_ujis_raw);

subtest 'Latin-1 in UTF-8 parsed as UTF-8 returns chars' => sub {
	run_ok @CMD, qw(--encoding utf8 t/encoding/copr-utf8.h);
	is stdout,   $basic;
	like stderr, qr/ as utf8\nheader end matches file size\ncollected/;
};
subtest 'Latin-1 in UTF-8 parsed by default returns mojibake' => sub {
	run_ok @CMD, qw(t/encoding/copr-utf8.h);
	my $todo = todo 'String::Copyright documented to accept only strings';
	is stdout, $basic_utf8_as_latin1;
	$todo = undef;
	like stderr, qr/ as raw bytes\nheader end matches file size\ncollected/;
};
subtest 'Latin-1 in UTF-8 parsed by guessing returns chars' => sub {
	run_ok @CMD, qw(--encoding Guess t/encoding/copr-utf8.h);
	my $todo = todo 'String::Copyright documented to accept only strings';
	is stdout, $basic_utf8_as_latin1;
	$todo = undef;
	like stderr, qr/ as raw bytes\nheader end matches file size\ncollected/;
};
subtest 'Latin-1 in UTF-8 parsed as ISO 8859-1 returns mojibake' => sub {
	run_ok @CMD, qw(--encoding iso-8859-1 t/encoding/copr-utf8.h);
	is stdout,   $basic_utf8_as_latin1;
	like stderr, qr/ as iso-8859-1\nheader end matches file size\ncollected/;
};
subtest 'Latin-1 in ISO 8859-1 parsed as ISO 8859-1 returns chars' => sub {
	run_ok @CMD, qw(--encoding iso-8859-1 t/encoding/copr-iso8859.h);
	is stdout,   $extended;
	like stderr, qr/ as iso-8859-1\nheader end matches file size\ncollected/;
};
subtest 'Latin-1 in ISO 8859-1 parsed by default returns chars' => sub {
	run_ok @CMD, qw(t/encoding/copr-iso8859.h);
	my $todo = todo 'String::Copyright documented to accept only strings';
	is stdout, $extended;
	$todo = undef;
	like stderr, qr/ as raw bytes\nheader end matches file size\ncollected/;
};
subtest 'Latin-1 in ISO 8859-1 parsed by guessing returns chars' => sub {
	run_ok @CMD, qw(--encoding Guess t/encoding/copr-iso8859.h);
	my $todo = todo 'String::Copyright documented to accept only strings';
	is stdout, $extended;
	$todo = undef;
	like stderr, qr/ as raw bytes\nheader end matches file size\ncollected/;
};
subtest 'Latin-1 in ISO 8859-1 parsed as UTF-8 returns mojibake and warns' =>
	sub {
	run_ok @CMD, qw(--encoding utf8 t/encoding/copr-iso8859.h);
	is stdout,   $extended;
	like stderr, qr/ as utf8\nfailed decoding/;
	};
subtest 'CJK in EUC-JP parsed as EUC-JP returns chars' => sub {
	run_ok @CMD, qw(--encoding euc-jp t/encoding/README.gs550j);
	is stdout,   $japanese;
	like stderr, qr/ as euc-jp\nheader end matches file size\nresolved/;
};
subtest 'CJK in EUC-JP parsed by default returns mojibake and warns' => sub {
	run_ok @CMD, qw(t/encoding/README.gs550j);
	my $todo = todo 'String::Copyright documented to accept only strings';
	is stdout, $japanese_ujis_as_latin1;
	$todo = undef;
	like stderr, qr/ as raw bytes\nheader end matches file size\nresolved/;
};
subtest 'CJK in EUC-JP parsed by guessing returns mojibake' => sub {
	run_ok @CMD, qw(--encoding Guess t/encoding/README.gs550j);
	my $todo = todo 'String::Copyright documented to accept only strings';
	is stdout, $japanese_ujis_as_latin1;
	$todo = undef;
	like stderr, qr/ as raw bytes\nheader end matches file size\nresolved/;
};
subtest 'CJK in EUC-JP parsed as ISO 8859-1 returns mojibake' => sub {
	run_ok @CMD, qw(--encoding iso-8859-1 t/encoding/README.gs550j);
	is stdout,   $japanese_ujis_as_latin1;
	like stderr, qr/ as iso-8859-1\nheader end matches file size\nresolved/;
};
subtest 'CJK in EUC-JP parsed as UTF-8 returns mojibake and warns' => sub {
	run_ok @CMD, qw(--encoding utf8 t/encoding/README.gs550j);
	is stdout,   $japanese_ujis_raw;
	like stderr, qr/ as utf8\nfailed decoding/;

#path('/tmp/_foo_')->spew(stdout);
};

done_testing;
