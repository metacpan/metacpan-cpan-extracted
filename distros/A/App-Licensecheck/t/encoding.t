use strictures 2;

use Test::More tests => 13;
use Test::Script 1.09;

sub licensecheck
{
	my ( $desc, $args, $file, $stdout, $stderr, $exit ) = @_;
	my @args = @{$args};
	my $path = "t/encoding/$file";
	my @cmd  = ( 'bin/licensecheck', @args, $path );
	my $expected
		= $stdout
		? scalar @args
			? "$path\t$stdout"
			: "$path: $stdout\n"
		: '';

	subtest "$desc; $path" => sub {
		script_runs( [@cmd], { exit => $exit || 0 }, join ' ', @cmd );
		ref $stdout eq 'Regexp'
			? script_stdout_like($expected)
			: script_stdout_is($expected);
		ref $stderr eq 'Regexp'
			? script_stderr_like($stderr)
			: script_stderr_is( $stderr || '' );
	};
}

licensecheck 'encoding; UTF-8',
	[qw(-m --copyright --encoding utf8)], 'copr-utf8.h',
	qr{GPL \(v2 or later\)	2004-2015 Oliva 'f00' Oberto / 2001-2010 Paul 'bar' Stevénsön};
licensecheck 'encoding; UTF-8 misparsed raw',
	[qw(-m --copyright)], 'copr-utf8.h',
	qr{GPL \(v2 or later\)	2004-2015 Oliva 'f00' Oberto / 2001-2010 Paul 'bar' StevÃ©nsÃ¶n};
licensecheck 'encoding; UTF-8 misparsed by guessing',
	[qw(-m --copyright --encoding Guess)], 'copr-utf8.h',
	qr{GPL \(v2 or later\)	2004-2015 Oliva 'f00' Oberto / 2001-2010 Paul 'bar' StevÃ©nsÃ¶n};
licensecheck 'encoding; UTF-8 misparsed as ISO 8859-1',
	[qw(-m --copyright --encoding iso-8859-1)], 'copr-utf8.h',
	qr{GPL \(v2 or later\)	2004-2015 Oliva 'f00' Oberto / 2001-2010 Paul 'bar' StevÃ©nsÃ¶n};
licensecheck 'encoding; ISO 8859-1',
	[qw(-m --copyright --encoding iso-8859-1)], 'copr-iso8859.h',
	qr{GPL \(v2\) \(with incorrect FSF address\)	2011 Heinrich Müller <henmull\@src.gnome.org>};
licensecheck 'encoding; ISO 8859-1 parsed raw',
	[qw(-m --copyright)], 'copr-iso8859.h',
	qr{GPL \(v2\) \(with incorrect FSF address\)	2011 Heinrich Müller <henmull\@src.gnome.org>};
licensecheck 'encoding; ISO 8859-1 parsed by guessing',
	[qw(-m --copyright --encoding Guess)], 'copr-iso8859.h',
	qr{GPL \(v2\) \(with incorrect FSF address\)	2011 Heinrich Müller <henmull\@src.gnome.org>};
licensecheck 'encoding; fails misparsing ISO 8859-1 as UTF-8',
	[qw(-m --copyright --encoding utf8)], 'copr-iso8859.h',
	'',
	qr{does not map to Unicode at},
	255;

licensecheck 'encoding; EUC',
	[qw(-m --copyright --encoding euc-jp)], 'README.gs550j',
	qr{UNKNOWN	1999 大森紀人 \(ohmori\@p.chiba-u.ac.jp\) / 1999 Norihito Ohmori. / 1996-1999 Daisuke SUZUKI.};
licensecheck 'encoding; EUC misparsed raw',
	[qw(-m --copyright)], 'README.gs550j',
	qr{UNKNOWN	1999 Âç¿¹µª¿Í \(ohmori\@p.chiba-u.ac.jp\) / 1999 Norihito Ohmori. / 1996-1999 Daisuke SUZUKI.},
	qr{|utf8 .* does not map to Unicode at};
licensecheck 'encoding; EUC misparsed by Guess',
	[qw(-m --copyright --encoding Guess)], 'README.gs550j',
	qr{UNKNOWN	1999 Âç¿¹µª¿Í \(ohmori\@p.chiba-u.ac.jp\) / 1999 Norihito Ohmori. / 1996-1999 Daisuke SUZUKI.};
licensecheck 'encoding; EUC parsed as ISO 8859-1',
	[qw(-m --copyright --encoding iso-8859-1)], 'README.gs550j',
	qr{UNKNOWN	1999 Âç¿¹µª¿Í \(ohmori\@p.chiba-u.ac.jp\) / 1999 Norihito Ohmori. / 1996-1999 Daisuke SUZUKI.};
licensecheck 'encoding; fails misparsing EUC as UTF-8',
	[qw(-m --copyright --encoding utf8)], 'README.gs550j',
	'',
	qr{does not map to Unicode at},
	255;
