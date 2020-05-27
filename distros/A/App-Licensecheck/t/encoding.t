use strictures;

use Test2::V0;

use Test::Command::Simple;

use Encode::Locale;
use Encode qw(decode encode);
use Path::Tiny 0.053;

plan 13;

my $CMD = $ENV{'LICENSECHECK'} || 'bin/licensecheck';

# ensure local script is executable
path($CMD)->chmod('a+x') if ( $CMD eq 'bin/licensecheck' );

my $data1 = encode(
	'iso-8859-1',
	"t/encoding/copr-utf8.h\tGNU General Public License v2.0 or later\t2004-2015 Oliva 'f00' Oberto / 2001-2010 Paul 'bar' Stevénsön\n"
);
my $data2 = encode(
	'iso-8859-1',
	"t/encoding/copr-iso8859.h\tGNU General Public License, Version 2 [obsolete FSF postal address (Temple Place)]\t2011 Heinrich Müller <henmull\@src.gnome.org>\n"
);
my $data3 = encode(
	'euc_jp',
	"t/encoding/README.gs550j\tUNKNOWN\t1999 大森紀人 (ohmori\@p.chiba-u.ac.jp) / 1999 Norihito Ohmori. / 1996-1999 Daisuke SUZUKI.\n"
);

subtest 'encoding; UTF-8' => sub {
	my $data = decode( 'iso-8859-1', $data1 );    # TODO: why not utf8?
	run_ok $CMD, qw(-m --copyright --encoding utf8 t/encoding/copr-utf8.h);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; UTF-8 misparsed raw' => sub {
	my $data = decode( 'iso-8859-1', $data1 );
	utf8::encode($data);                          # TODO: why?
	run_ok $CMD, qw(-m --copyright t/encoding/copr-utf8.h);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; UTF-8 misparsed by guessing' => sub {
	my $data = decode( 'iso-8859-1', $data1 );
	utf8::encode($data);                          # TODO: why?
	run_ok $CMD, qw(-m --copyright --encoding Guess t/encoding/copr-utf8.h);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; UTF-8 misparsed as ISO 8859-1' => sub {
	my $data = decode( 'iso-8859-1', $data1 );
	utf8::encode($data);                          # TODO: why?
	run_ok $CMD,
		qw(-m --copyright --encoding iso-8859-1 t/encoding/copr-utf8.h);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; ISO 8859-1' => sub {
	my $data = decode( 'iso-8859-1', $data2 );
	run_ok $CMD,
		qw(-m --copyright --encoding iso-8859-1 t/encoding/copr-iso8859.h);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; ISO 8859-1 parsed raw' => sub {
	my $data = decode( 'iso-8859-1', $data2 );
	run_ok $CMD, qw(-m --copyright t/encoding/copr-iso8859.h);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; ISO 8859-1 parsed by guessing' => sub {
	my $data = decode( 'iso-8859-1', $data2 );
	run_ok $CMD,
		qw(-m --copyright --encoding Guess t/encoding/copr-iso8859.h);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; fails misparsing ISO 8859-1 as UTF-8' => sub {
	my $data = decode( 'iso-8859-1', $data2 );    # TODO: why not utf8?
	run_ok $CMD,
		qw(-m --copyright --encoding utf8 t/encoding/copr-iso8859.h);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; EUC' => sub {
	my $data = decode( 'euc_jp', $data3 );
	run_ok $CMD,
		qw(-m --copyright --encoding euc-jp t/encoding/README.gs550j);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; EUC misparsed raw' => sub {
	my $data = decode( 'iso-8859-1', $data3 );
	run_ok $CMD, qw(-m --copyright t/encoding/README.gs550j);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	like stderr, qr{|utf8 .* does not map to Unicode at};
};
subtest 'encoding; EUC misparsed by Guess' => sub {
	my $data = decode( 'iso-8859-1', $data3 );
	run_ok $CMD, qw(-m --copyright --encoding Guess t/encoding/README.gs550j);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; EUC parsed as ISO 8859-1' => sub {
	my $data = decode( 'iso-8859-1', $data3 );
	run_ok $CMD,
		qw(-m --copyright --encoding iso-8859-1 t/encoding/README.gs550j);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};
subtest 'encoding; fails misparsing EUC as UTF-8' => sub {
	my $data = decode( 'iso-8859-1', $data3 );    # TODO: why not utf8?
	run_ok $CMD,
		qw(-m --copyright --encoding utf8 t/encoding/README.gs550j);
	is stdout, encode( 'console_out', $data ),
		'Testing stdout';
	is stderr, '', 'No stderr';
};

done_testing;
