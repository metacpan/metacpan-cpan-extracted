use Test2::V0 -no_pragmas => 1;
use Test2::Tools::Command;

use warnings;
use strict;

use Encode::Locale;
use Encode 2.12 qw(decode encode);
use Path::Tiny 0.053;

if ( $Encode::Locale::ENCODING_LOCALE ne 'UTF-8' ) {
	skip_all
		"locale encoding is $Encode::Locale::ENCODING_LOCALE - we need UTF-8";
}

plan 13;

diag 'locale encoding: ', $Encode::Locale::ENCODING_LOCALE;

local @Test2::Tools::Command::command = ( $^X, 'bin/licensecheck' );
if ( $ENV{'LICENSECHECK'} ) {
	@Test2::Tools::Command::command = ( $ENV{'LICENSECHECK'} );
}
elsif ( path('blib')->exists ) {
	@Test2::Tools::Command::command = ('blib/script/licensecheck');
}
push @Test2::Tools::Command::command, qw(--machine --debug --copyright);

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
	command {
		args   => [qw(--encoding utf8 t/encoding/copr-utf8.h)],
		stdout => $basic,
		stderr => qr/ as utf8\nheader end matches file size\ncollected/,
	};
};
subtest 'Latin-1 in UTF-8 parsed by default returns mojibake' => sub {
	command {
		args   => [qw(t/encoding/copr-utf8.h)],
		stdout => qr//,
		stderr => qr/ as raw bytes\nheader end matches file size\ncollected/,
	};
	my $todo = todo 'String::Copyright documented to accept only strings';
	command {
		args   => [qw(t/encoding/copr-utf8.h)],
		stdout => $basic_utf8_as_latin1,
		stderr => qr/ as raw bytes\nheader end matches file size\ncollected/,
	};
	$todo = undef;
};
subtest 'Latin-1 in UTF-8 parsed by guessing returns chars' => sub {
	command {
		args   => [qw(--encoding Guess t/encoding/copr-utf8.h)],
		stdout => qr//,
		stderr => qr/ as raw bytes\nheader end matches file size\ncollected/,
	};
	my $todo = todo 'String::Copyright documented to accept only strings';
	command {
		args   => [qw(--encoding Guess t/encoding/copr-utf8.h)],
		stdout => $basic_utf8_as_latin1,
		stderr => qr/ as raw bytes\nheader end matches file size\ncollected/,
	};
	$todo = undef;
};
subtest 'Latin-1 in UTF-8 parsed as ISO 8859-1 returns mojibake' => sub {
	command {
		args   => [qw(--encoding iso-8859-1 t/encoding/copr-utf8.h)],
		stdout => $basic_utf8_as_latin1,
		stderr => qr/ as iso-8859-1\nheader end matches file size\ncollected/,
	};
};
subtest 'Latin-1 in ISO 8859-1 parsed as ISO 8859-1 returns chars' => sub {
	command {
		args   => [qw(--encoding iso-8859-1 t/encoding/copr-iso8859.h)],
		stdout => $extended,
		stderr => qr/ as iso-8859-1\nheader end matches file size\ncollected/,
	};
};
subtest 'Latin-1 in ISO 8859-1 parsed by default returns chars' => sub {
	command {
		args   => [qw(t/encoding/copr-iso8859.h)],
		stdout => qr//,
		stderr => qr/ as raw bytes\nheader end matches file size\ncollected/,
	};
	my $todo = todo 'String::Copyright documented to accept only strings';
	command {
		args   => [qw(t/encoding/copr-iso8859.h)],
		stdout => $extended,
		stderr => qr/ as raw bytes\nheader end matches file size\ncollected/,
	};
	$todo = undef;
};
subtest 'Latin-1 in ISO 8859-1 parsed by guessing returns chars' => sub {
	command {
		args   => [qw(--encoding Guess t/encoding/copr-iso8859.h)],
		stdout => qr//,
		stderr => qr/ as raw bytes\nheader end matches file size\ncollected/,
	};
	my $todo = todo 'String::Copyright documented to accept only strings';
	command {
		args   => [qw(--encoding Guess t/encoding/copr-iso8859.h)],
		stdout => $extended,
		stderr => qr/ as raw bytes\nheader end matches file size\ncollected/,
	};
	$todo = undef;
};
subtest 'Latin-1 in ISO 8859-1 parsed as UTF-8 returns mojibake and warns' =>
	sub {
	command {
		args   => [qw(--encoding utf8 t/encoding/copr-iso8859.h)],
		stdout => $extended,
		stderr => qr/ as utf8\nfailed decoding/,
	};
	};
subtest 'CJK in EUC-JP parsed as EUC-JP returns chars' => sub {
	command {
		args   => [qw(--encoding euc-jp t/encoding/README.gs550j)],
		stdout => $japanese,
		stderr => qr/ as euc-jp\nheader end matches file size\nresolved/,
	};
};
subtest 'CJK in EUC-JP parsed by default returns mojibake and warns' => sub {
	command {
		args   => [qw(t/encoding/README.gs550j)],
		stdout => qr//,
		stderr => qr/ as raw bytes\nheader end matches file size\nresolved/,
	};
	my $todo = todo 'String::Copyright documented to accept only strings';
	command {
		args   => [qw(t/encoding/README.gs550j)],
		stdout => $japanese_ujis_as_latin1,
		stderr => qr/ as raw bytes\nheader end matches file size\nresolved/,
	};
	$todo = undef;
};
subtest 'CJK in EUC-JP parsed by guessing returns mojibake' => sub {
	command {
		args   => [qw(--encoding Guess t/encoding/README.gs550j)],
		stdout => qr//,
		stderr => qr/ as raw bytes\nheader end matches file size\nresolved/,
	};
	my $todo = todo 'String::Copyright documented to accept only strings';
	command {
		args   => [qw(--encoding Guess t/encoding/README.gs550j)],
		stdout => $japanese_ujis_as_latin1,
		stderr => qr/ as raw bytes\nheader end matches file size\nresolved/,
	};
	$todo = undef;
};
subtest 'CJK in EUC-JP parsed as ISO 8859-1 returns mojibake' => sub {
	command {
		args   => [qw(--encoding iso-8859-1 t/encoding/README.gs550j)],
		stdout => $japanese_ujis_as_latin1,
		stderr => qr/ as iso-8859-1\nheader end matches file size\nresolved/,
	};
};
subtest 'CJK in EUC-JP parsed as UTF-8 returns mojibake and warns' => sub {
	command {
		args   => [qw(--encoding utf8 t/encoding/README.gs550j)],
		stdout => $japanese_ujis_raw,
		stderr => qr/ as utf8\nfailed decoding/,
	};
};

done_testing;
