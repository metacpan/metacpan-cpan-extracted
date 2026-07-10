#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Algorithm::ToNumberMunger;
my $M = 'Algorithm::ToNumberMunger';

# ---- registry -------------------------------------------------------------
ok( $M->has_munger('enum'),  'enum is a known munger' );
ok( !$M->has_munger('nope'), 'unknown munger is not known' );
is_deeply(
	[ $M->known_mungers ],
	[
		qw(aad_client_app_enum aad_signin_error_enum amavis_category_enum
			app_proto_enum aws_event_type_enum aws_principal_type_enum bit bool
			bucket chain char cidr clamav_result_enum clamp combine
			conditional_access_result_enum count datetime dhcp_msgtype_enum
			dict_enum dkim_result_enum dmarc_result_enum dns_qtype_enum
			dns_rcode_enum entropy enum eps flow_reason_enum flow_state_enum
			frozen_freq_map ftp_enum gemini_enum hash http_enum http_method_enum
			http_version_enum ip_class ip_proto_enum kerberos_etype_enum length
			log match mgcp_enum ngram nntp_enum num postfix_status_enum quantile
			ratio risk_level_enum risk_state_enum rspamd_action_enum rtsp_enum
			run sasl_mech_enum sasl_mech_iana_enum scale sip_enum sip_method_enum
			smtp_enum spamassassin_autolearn_enum spf_result_enum
			ssh_auth_method_enum suricata_action_enum syslog_facility_enum
			syslog_severity_enum systemd_result_enum tcp_state_enum
			tls_version_enum vpc_flow_log_status_enum
			windows_impersonation_level_enum windows_integrity_level_enum
			windows_logon_status_enum zscore)
	],
	'known_mungers is the full sorted set',
);

# ---- enum -----------------------------------------------------------------
{
	my $c = $M->build( { munger => 'enum', map => { GET => 0, POST => 1 } } );
	is( $c->('GET'),  0, 'enum maps GET' );
	is( $c->('POST'), 1, 'enum maps POST' );
	eval { $c->('HEAD') };
	like( $@, qr/no mapping for 'HEAD'/, 'enum croaks on unmapped without default' );

	my $d = $M->build( { munger => 'enum', map => { GET => 0 }, default => -1 } );
	is( $d->('WAT'), -1, 'enum default for unmapped' );
	is( $d->(undef), -1, 'enum default for undef' );
}

# ---- http_enum ------------------------------------------------------------
{
	my $c = $M->build( { munger => 'http_enum' } );
	is( $c->(100),   1, 'http_enum 1xx -> 1' );
	is( $c->(200),   2, 'http_enum 2xx -> 2' );
	is( $c->(301),   3, 'http_enum 3xx -> 3' );
	is( $c->(404),   4, 'http_enum 4xx -> 4' );
	is( $c->(503),   5, 'http_enum 5xx -> 5' );
	is( $c->('200'), 2, 'http_enum accepts a numeric string' );
	is( $c->(700),   7, 'http_enum lax lets out-of-range through' );
	eval { $c->('nope') };
	like( $@, qr/not a numeric status code/, 'http_enum croaks on non-numeric' );

	my $s = $M->build( { munger => 'http_enum', strict => 1 } );
	is( $s->(404), 4, 'http_enum strict passes an in-range code' );
	is( $s->(100), 1, 'http_enum strict passes the low boundary' );
	is( $s->(599), 5, 'http_enum strict passes the high boundary' );
	eval { $s->(700) };
	like( $@, qr/out of range/, 'http_enum strict rejects a high code' );
	eval { $s->(99) };
	like( $@, qr/out of range/, 'http_enum strict rejects a low code' );
}

# ---- smtp_enum ------------------------------------------------------------
{
	my $c = $M->build( { munger => 'smtp_enum' } );
	is( $c->(220), 2, 'smtp_enum 2yz -> 2' );
	is( $c->(354), 3, 'smtp_enum 3yz -> 3' );
	is( $c->(450), 4, 'smtp_enum 4yz -> 4' );
	is( $c->(550), 5, 'smtp_enum 5yz -> 5' );
	is( $c->(700), 7, 'smtp_enum lax lets out-of-range through' );
	eval { $c->('nope') };
	like( $@, qr/smtp_enum munger.*not a numeric status code/, 'smtp_enum croaks on non-numeric' );

	my $s = $M->build( { munger => 'smtp_enum', strict => 1 } );
	is( $s->(200), 2, 'smtp_enum strict passes the low boundary' );
	is( $s->(599), 5, 'smtp_enum strict passes the high boundary' );
	eval { $s->(150) };
	like( $@, qr/out of range \(200-599\)/, 'smtp_enum strict rejects 1xx (unused in SMTP)' );
	eval { $s->(700) };
	like( $@, qr/out of range \(200-599\)/, 'smtp_enum strict rejects a high code' );
}

# ---- sip_enum -------------------------------------------------------------
{
	my $c = $M->build( { munger => 'sip_enum' } );
	is( $c->(100), 1, 'sip_enum 1xx -> 1' );
	is( $c->(200), 2, 'sip_enum 2xx -> 2' );
	is( $c->(302), 3, 'sip_enum 3xx -> 3' );
	is( $c->(404), 4, 'sip_enum 4xx -> 4' );
	is( $c->(503), 5, 'sip_enum 5xx -> 5' );
	is( $c->(603), 6, 'sip_enum 6xx -> 6 (global failure)' );

	my $s = $M->build( { munger => 'sip_enum', strict => 1 } );
	is( $s->(699), 6, 'sip_enum strict passes the 6xx high boundary' );
	eval { $s->(700) };
	like( $@, qr/out of range \(100-699\)/, 'sip_enum strict rejects >= 700' );
	eval { $s->(99) };
	like( $@, qr/out of range \(100-699\)/, 'sip_enum strict rejects < 100' );
}

# ---- frozen_freq_map -------------------------------------------------------------
{
	# defaults: neg_log_prob, smoothing 1, unseen 'rare'. counts a:3 b:1,
	# total 4, V 2 => denom = 4 + 1*(2+1) = 7.
	my $r = $M->build( { munger => 'frozen_freq_map', counts => { a => 3, b => 1 } } );
	ok( $r->('b') > $r->('a'),                   'frozen_freq_map: rarer value is more surprising' );
	ok( $r->('zzz') > $r->('b'),                 'frozen_freq_map: unseen is the most surprising' );
	ok( abs( $r->('zzz') - log(7) ) < 1e-9,      'frozen_freq_map unseen surprisal = -ln(1/7)' );
	ok( abs( $r->('a') - -log( 4 / 7 ) ) < 1e-9, 'frozen_freq_map seen surprisal value' );

	my $cnt = $M->build( { munger => 'frozen_freq_map', counts => { a => 3, b => 1 }, mode => 'count' } );
	is( $cnt->('a'),   3, 'frozen_freq_map count mode' );
	is( $cnt->('zzz'), 0, 'frozen_freq_map count mode: unseen -> 0' );

	# raw probability (no smoothing): a:3 b:1 total 4 => p(a)=0.75.
	my $freq = $M->build(
		{
			munger    => 'frozen_freq_map',
			counts    => { a => 3, b => 1 },
			mode      => 'freq',
			smoothing => 0,
		}
	);
	ok( abs( $freq->('a') - 0.75 ) < 1e-9, 'frozen_freq_map raw freq, no smoothing' );
	is( $freq->('zzz'), 0, 'frozen_freq_map freq: unseen with no smoothing -> 0' );

	my $num = $M->build(
		{
			munger => 'frozen_freq_map',
			counts => { a => 3 },
			unseen => -1,
			mode   => 'count',
		}
	);
	is( $num->('zzz'), -1, 'frozen_freq_map numeric unseen default' );

	# explicit total (pruned tail) larger than the sum is honored.
	my $pruned = $M->build( { munger => 'frozen_freq_map', counts => { a => 3 }, total => 100 } );
	ok( $pruned->('zzz') > $pruned->('a'), 'frozen_freq_map with pruned tail still ranks unseen rarest' );

	# validation
	eval { $M->build( { munger => 'frozen_freq_map', counts => {} } ) };
	like( $@, qr/non-empty 'counts'/, 'frozen_freq_map rejects empty counts' );
	eval { $M->build( { munger => 'frozen_freq_map', counts => { a => 3 }, total => 1 } ) };
	like( $@, qr/must be >= sum/, 'frozen_freq_map rejects total < sum' );
	eval { $M->build( { munger => 'frozen_freq_map', counts => { a => 3 }, mode => 'bogus' } ) };
	like( $@, qr/unknown mode 'bogus'/, 'frozen_freq_map rejects bad mode' );
	eval { $M->build( { munger => 'frozen_freq_map', counts => { a => 3 }, smoothing => 0 } ); };
	like( $@, qr/needs smoothing > 0/, 'frozen_freq_map neg_log_prob + rare + no smoothing croaks' );

	# size guard warns
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, "@_" };
	local $Algorithm::ToNumberMunger::FROZEN_FREQ_MAP_WARN_KEYS = 1;
	$M->build( { munger => 'frozen_freq_map', counts => { a => 1, b => 2 }, mode => 'count' } );
	ok( ( grep { /bloats info\.json/ } @warn ), 'frozen_freq_map warns on oversized table' );
}

# ---- bool -----------------------------------------------------------------
{
	my $c = $M->build( { munger => 'bool' } );
	is( $c->('anything'), 1, 'bool truthy' );
	is( $c->(0),          0, 'bool falsey' );

	my $t = $M->build( { munger => 'bool', true => [qw(yes Y 1)] } );
	is( $t->('yes'), 1, 'bool true-list hit' );
	is( $t->('no'),  0, 'bool true-list miss' );
	is( $t->(undef), 0, 'bool true-list undef' );
}

# ---- length ---------------------------------------------------------------
{
	my $c = $M->build( { munger => 'length' } );
	is( $c->('abcd'), 4, 'length counts characters' );
	is( $c->(''),     0, 'length of empty string' );
	is( $c->(undef),  0, 'length of undef is 0' );
	is( $c->(12345),  5, 'length stringifies numbers' );
	# character length, not byte length: "cafe" with a combined e-acute is 4.
	is( $c->("caf\x{e9}"), 4, 'length is characters, not UTF-8 bytes' );
}

# ---- entropy --------------------------------------------------------------
{
	my $c = $M->build( { munger => 'entropy' } );
	is( $c->(''),     0, 'entropy of empty string is 0' );
	is( $c->('aaaa'), 0, 'entropy of a single repeated symbol is 0' );
	ok( abs( $c->('ab') - 1 ) < 1e-9,   'entropy of two equiprobable symbols is 1 bit' );
	ok( abs( $c->('abcd') - 2 ) < 1e-9, 'entropy of four equiprobable symbols is 2 bits' );
	# high-entropy DGA-ish name scores well above a real word.
	ok( $c->('x7f3q9zk2v') > $c->('google'), 'random string out-scores a word' );

	# XS and PP must agree (whichever built). can() grabs the coderef by name
	# without needing symbolic references.
	my $ns = 'Algorithm::ToNumberMunger';
	my $pp = $ns->can('_entropy_pp');
	for my $s ( '', 'a', 'ab', 'hello world', 'x7f3q9zk2v', "sn\x{f8}wman" ) {
		ok( abs( $c->($s) - $pp->($s) ) < 1e-12, "entropy XS==PP for '$s'" );
	}
}

# ---- ngram ------------------------------------------------------------------
{
	# tiny bigram table: 'ab' common, 'ba' rare. sum 11, V 2, smoothing 1
	# => denom = 11 + 1*3 = 14. si(ab) = -ln(11/14), si(ba) = -ln(2/14),
	# unseen = -ln(1/14).
	my $c = $M->build( { munger => 'ngram', counts => { ab => 10, ba => 1 } } );
	ok( abs( $c->('ab') - -log( 11 / 14 ) ) < 1e-9, 'ngram: single common gram scores its surprisal' );
	ok( abs( $c->('zz') - -log( 1 / 14 ) ) < 1e-9,  'ngram: unseen gram gets the unseen-bucket surprisal' );
	ok( $c->('zzzz') > $c->('abab'),                'ngram: gibberish out-scores common grams' );
	# 'aba' = grams ab, ba -> mean of the two surprisals.
	ok( abs( $c->('aba') - ( -log( 11 / 14 ) + -log( 2 / 14 ) ) / 2 ) < 1e-9, 'ngram: mean over the string\'s grams' );
	is( $c->('a'),   0,          'ngram: string shorter than n scores 0' );
	is( $c->(''),    0,          'ngram: empty string scores 0' );
	is( $c->(undef), 0,          'ngram: undef scores 0' );
	is( $c->('AB'),  $c->('ab'), 'ngram: fold_case lowercases by default' );

	my $nofold = $M->build( { munger => 'ngram', counts => { ab => 10, ba => 1 }, fold_case => 0 } );
	ok( $nofold->('AB') > $nofold->('ab'), 'ngram: fold_case => 0 keeps case distinct' );

	# validation
	eval { $M->build( { munger => 'ngram', counts => {} } ) };
	like( $@, qr/non-empty 'counts'/, 'ngram rejects empty counts' );
	eval { $M->build( { munger => 'ngram', counts => { ab => 1, xyz => 2 } } ) };
	like( $@, qr/same length/, 'ngram rejects mixed-length grams' );
	eval { $M->build( { munger => 'ngram', counts => { ab => 'x' } } ) };
	like( $@, qr/not a non-negative number/, 'ngram rejects non-numeric counts' );
	eval { $M->build( { munger => 'ngram', counts => { ab => 1 }, smoothing => 0 } ) };
	like( $@, qr/'smoothing' must be a number > 0/, 'ngram rejects zero smoothing' );
	eval { $M->build( { munger => 'ngram', counts => { ab => 5 }, total => 1 } ) };
	like( $@, qr/must be >= sum/, 'ngram rejects total < sum' );
}

# ---- char -----------------------------------------------------------------
{
	my $cnt = $M->build( { munger => 'char', class => 'non_ascii' } );
	is( $cnt->('abc'),            0, 'char non_ascii count on ASCII' );
	is( $cnt->("a\x{e9}b\x{ff}"), 2, 'char non_ascii counts codepoints > 127' );

	my $ratio = $M->build( { munger => 'char', class => 'non_alnum', mode => 'ratio' } );
	is( $ratio->('abcd'), 0,   'char non_alnum ratio, all alnum' );
	is( $ratio->('ab..'), 0.5, 'char non_alnum ratio, half punct' );
	is( $ratio->(''),     0,   'char ratio of empty string is 0' );

	my $dig = $M->build( { munger => 'char', class => 'digit' } );
	is( $dig->('a1b2c3'), 3, 'char digit count' );

	# space and punct ride the regex (not tr///) so their \s / [[:punct:]]
	# semantics are preserved -- cover that path.
	my $sp = $M->build( { munger => 'char', class => 'space' } );
	is( $sp->("a b\tc\nd"), 3, 'char space counts blank, tab, newline' );
	my $pu = $M->build( { munger => 'char', class => 'punct' } );
	is( $pu->('a,b.c!'), 3, 'char punct count' );

	my $vo = $M->build( { munger => 'char', class => 'vowel' } );
	is( $vo->('Aeixy'), 3, 'char vowel count' );
	my $co = $M->build( { munger => 'char', class => 'consonant' } );
	is( $co->('Aeixy'), 2, 'char consonant count (y is a consonant)' );
	my $xd = $M->build( { munger => 'char', class => 'xdigit' } );
	is( $xd->('deadBEEFxyz9'), 9, 'char xdigit count' );

	eval { $M->build( { munger => 'char', class => 'bogus' } ) };
	like( $@, qr/unknown class 'bogus'/, 'char rejects unknown class' );
	eval { $M->build( { munger => 'char', class => 'digit', mode => 'nope' } ) };
	like( $@, qr/'mode' must be/, 'char rejects bad mode' );
}

# ---- run --------------------------------------------------------------------
{
	my $c = $M->build( { munger => 'run', class => 'consonant' } );
	is( $c->('kitchen'),  3, 'run: longest consonant run in a real word' );
	is( $c->('xkqvbrtn'), 8, 'run: a DGA-ish string is one long run' );
	is( $c->('aeiou'),    0, 'run: no consonants at all' );
	is( $c->(''),         0, 'run: empty string' );
	is( $c->(undef),      0, 'run: undef is 0' );

	my $d = $M->build( { munger => 'run', class => 'digit' } );
	is( $d->('ab1234cd56'), 4, 'run: longest digit run' );

	eval { $M->build( { munger => 'run' } ) };
	like( $@, qr/requires a 'class'/, 'run requires a class' );
	eval { $M->build( { munger => 'run', class => 'bogus' } ) };
	like( $@, qr/unknown class 'bogus'/, 'run rejects unknown class' );
}

# ---- count ----------------------------------------------------------------
{
	my $slashes = $M->build( { munger => 'count', of => '/' } );
	is( $slashes->('/a/b/c'), 3, 'count slashes (path depth)' );
	is( $slashes->('nopath'), 0, 'count with no matches' );

	my $labels = $M->build( { munger => 'count', of => '.', plus => 1 } );
	is( $labels->('a.b.evil.com'), 4, 'count dots + 1 (label_count)' );
	is( $labels->('localhost'),    1, 'count label_count of a single label' );

	# multi-char needles count non-overlapping occurrences (m//g semantics)
	my $aa = $M->build( { munger => 'count', of => 'aa' } );
	is( $aa->('aaaa'),  2, 'count is non-overlapping' );
	is( $aa->('aaaaa'), 2, 'count leftover tail does not match' );

	eval { $M->build( { munger => 'count' } ) };
	like( $@, qr/non-empty 'of'/, 'count requires of' );
}

# ---- match ------------------------------------------------------------------
{
	my $puny = $M->build( { munger => 'match', pattern => '^xn--' } );
	is( $puny->('xn--e1afmkfd.ru'), 1, 'match bool: punycode label matches' );
	is( $puny->('example.com'),     0, 'match bool: plain label does not' );
	is( $puny->(undef),             0, 'match bool: undef is 0' );

	my $esc = $M->build( { munger => 'match', pattern => '%[0-9A-Fa-f]{2}', mode => 'count' } );
	is( $esc->('/a%20b%2e%2Ec'), 3, 'match count: percent-escapes' );
	is( $esc->('/plain/path'),   0, 'match count: none' );

	my $ci = $M->build( { munger => 'match', pattern => 'select', ignore_case => 1 } );
	is( $ci->('SELECT * FROM'), 1, 'match ignore_case matches across case' );

	eval { $M->build( { munger => 'match' } ) };
	like( $@, qr/non-empty 'pattern'/, 'match requires a pattern' );
	eval { $M->build( { munger => 'match', pattern => '(unclosed' } ) };
	like( $@, qr/cannot compile pattern/, 'match croaks on a broken pattern at build time' );
	eval { $M->build( { munger => 'match', pattern => 'x', mode => 'nope' } ) };
	like( $@, qr/'mode' must be/, 'match rejects bad mode' );
}

# ---- bucket ---------------------------------------------------------------
{
	my $port = $M->build( { munger => 'bucket', bounds => [ 1024, 49152 ] } );
	is( $port->(80),    0, 'bucket well-known port' );
	is( $port->(1023),  0, 'bucket just below first bound' );
	is( $port->(1024),  1, 'bucket at first bound is registered' );
	is( $port->(8080),  1, 'bucket registered port' );
	is( $port->(49152), 2, 'bucket at second bound is ephemeral' );
	is( $port->(60000), 2, 'bucket ephemeral port' );

	eval { $M->build( { munger => 'bucket', bounds => [] } ) };
	like( $@, qr/non-empty 'bounds'/, 'bucket rejects empty bounds' );
	eval { $M->build( { munger => 'bucket', bounds => [ 5, 5 ] } ) };
	like( $@, qr/strictly ascending/, 'bucket rejects non-ascending bounds' );
}

# ---- quantile ---------------------------------------------------------------
{
	# bounds at min/p25/p50/p75/max of an imaginary training column.
	my $q = $M->build( { munger => 'quantile', bounds => [ 0, 10, 100, 1000, 10000 ] } );
	is( $q->(0),      0,     'quantile at the first bound is 0' );
	is( $q->(-5),     0,     'quantile clamps below' );
	is( $q->(10000),  1,     'quantile at the last bound is 1' );
	is( $q->(999999), 1,     'quantile clamps above' );
	is( $q->(10),     0.25,  'quantile at an interior bound' );
	is( $q->(100),    0.5,   'quantile at the median bound' );
	is( $q->(5),      0.125, 'quantile interpolates within a segment' );
	is( $q->(550),    0.625, 'quantile interpolates mid-segment' );

	eval { $q->('nope') };
	like( $@, qr/not numeric/, 'quantile croaks on non-numeric input' );
	eval { $M->build( { munger => 'quantile', bounds => [5] } ) };
	like( $@, qr/at least 2/, 'quantile needs two bounds' );
	eval { $M->build( { munger => 'quantile', bounds => [ 5, 5 ] } ) };
	like( $@, qr/strictly ascending/, 'quantile rejects non-ascending bounds' );
}

# ---- ftp_enum -------------------------------------------------------------
{
	my $c = $M->build( { munger => 'ftp_enum' } );
	is( $c->(220), 2, 'ftp_enum 2yz -> 2' );
	is( $c->(530), 5, 'ftp_enum 5yz -> 5' );
	my $s = $M->build( { munger => 'ftp_enum', strict => 1 } );
	eval { $s->(700) };
	like( $@, qr/out of range \(100-599\)/, 'ftp_enum strict rejects >= 700' );
}

# ---- rtsp_enum / nntp_enum / dict_enum (more %STATUS_PROTO rows) -----------
{
	for my $proto (qw(rtsp nntp dict)) {
		my $c = $M->build( { munger => "${proto}_enum" } );
		is( $c->(150), 1, "${proto}_enum 1xx -> 1" );
		is( $c->(200), 2, "${proto}_enum 2xx -> 2" );
		is( $c->(554), 5, "${proto}_enum 5xx -> 5" );
		my $s = $M->build( { munger => "${proto}_enum", strict => 1 } );
		is( $s->(100), 1, "${proto}_enum strict passes the low boundary" );
		is( $s->(599), 5, "${proto}_enum strict passes the high boundary" );
		eval { $s->(700) };
		like( $@, qr/${proto}_enum munger.*out of range \(100-599\)/, "${proto}_enum strict rejects >= 700" );
	} ## end for my $proto (qw(rtsp nntp dict))
}

# ---- gemini_enum (two-digit codes, divisor 10) ------------------------------
{
	my $c = $M->build( { munger => 'gemini_enum' } );
	is( $c->(20), 2, 'gemini_enum 20 -> 2 (success)' );
	is( $c->(31), 3, 'gemini_enum 31 -> 3 (redirect)' );
	is( $c->(51), 5, 'gemini_enum 51 -> 5 (not found)' );
	is( $c->(62), 6, 'gemini_enum 62 -> 6 (cert not valid)' );
	eval { $c->('nope') };
	like( $@, qr/not a numeric status code/, 'gemini_enum croaks on non-numeric' );

	my $s = $M->build( { munger => 'gemini_enum', strict => 1 } );
	is( $s->(10), 1, 'gemini_enum strict passes the low boundary' );
	is( $s->(69), 6, 'gemini_enum strict passes the high boundary' );
	eval { $s->(200) };
	like( $@, qr/out of range \(10-69\)/, 'gemini_enum strict rejects an HTTP-sized code' );
	eval { $s->(9) };
	like( $@, qr/out of range \(10-69\)/, 'gemini_enum strict rejects < 10' );
}

# ---- mgcp_enum (custom: 8xx is valid, 6xx/7xx are the hole) -----------------
{
	my $c = $M->build( { munger => 'mgcp_enum' } );
	is( $c->(100), 1, 'mgcp_enum 1xx -> 1 (provisional)' );
	is( $c->(200), 2, 'mgcp_enum 2xx -> 2 (success)' );
	is( $c->(401), 4, 'mgcp_enum 4xx -> 4 (transient error)' );
	is( $c->(510), 5, 'mgcp_enum 5xx -> 5 (permanent error)' );
	is( $c->(805), 8, 'mgcp_enum 8xx -> 8 (package-specific)' );
	is( $c->(700), 7, 'mgcp_enum lax lets 7xx through' );
	eval { $c->('nope') };
	like( $@, qr/mgcp_enum munger.*not a numeric status code/, 'mgcp_enum croaks on non-numeric' );

	my $s = $M->build( { munger => 'mgcp_enum', strict => 1 } );
	is( $s->(100), 1, 'mgcp_enum strict passes the low boundary' );
	is( $s->(599), 5, 'mgcp_enum strict passes 599' );
	is( $s->(800), 8, 'mgcp_enum strict passes 800 (8xx is real)' );
	is( $s->(899), 8, 'mgcp_enum strict passes 899' );
	eval { $s->(650) };
	like( $@, qr/out of range \(100-599 or 800-899\)/, 'mgcp_enum strict rejects 6xx (the hole)' );
	eval { $s->(700) };
	like( $@, qr/out of range \(100-599 or 800-899\)/, 'mgcp_enum strict rejects 7xx (the hole)' );
	eval { $s->(900) };
	like( $@, qr/out of range/, 'mgcp_enum strict rejects >= 900' );
	eval { $s->(99) };
	like( $@, qr/out of range/, 'mgcp_enum strict rejects < 100' );
}

# ---- named-map enums --------------------------------------------------------
{
	my $rcode = $M->build( { munger => 'dns_rcode_enum' } );
	is( $rcode->('NXDOMAIN'),  3,  'dns_rcode_enum maps NXDOMAIN' );
	is( $rcode->('noerror'),   0,  'dns_rcode_enum is case-insensitive' );
	is( $rcode->('BADCOOKIE'), 23, 'dns_rcode_enum knows extended rcodes' );
	is( $rcode->(3),           3,  'dns_rcode_enum passes numeric input through' );
	eval { $rcode->('WAT') };
	like( $@, qr/dns_rcode_enum munger.*no mapping for 'WAT'/, 'dns_rcode_enum croaks on unmapped without default' );
	my $rd = $M->build( { munger => 'dns_rcode_enum', default => -1 } );
	is( $rd->('WAT'), -1, 'dns_rcode_enum default for unmapped' );
	is( $rd->(undef), -1, 'dns_rcode_enum default for undef' );

	my $qtype = $M->build( { munger => 'dns_qtype_enum' } );
	is( $qtype->('A'),     1,   'dns_qtype_enum maps A' );
	is( $qtype->('aaaa'),  28,  'dns_qtype_enum maps aaaa (case-insensitive)' );
	is( $qtype->('TXT'),   16,  'dns_qtype_enum maps TXT' );
	is( $qtype->('NULL'),  10,  'dns_qtype_enum maps NULL' );
	is( $qtype->('ANY'),   255, 'dns_qtype_enum maps ANY' );
	is( $qtype->('*'),     255, 'dns_qtype_enum maps * as ANY' );
	is( $qtype->('HTTPS'), 65,  'dns_qtype_enum maps HTTPS' );
	is( $qtype->(28),      28,  'dns_qtype_enum passes numeric input through' );

	my $sev = $M->build( { munger => 'syslog_severity_enum' } );
	is( $sev->('emerg'), 0, 'syslog_severity_enum emerg' );
	is( $sev->('panic'), 0, 'syslog_severity_enum panic alias' );
	is( $sev->('ERROR'), 3, 'syslog_severity_enum error alias, case-insensitive' );
	is( $sev->('warn'),  4, 'syslog_severity_enum warn alias' );
	is( $sev->('debug'), 7, 'syslog_severity_enum debug' );
	is( $sev->(6),       6, 'syslog_severity_enum passes numeric input through' );

	my $fac = $M->build( { munger => 'syslog_facility_enum' } );
	is( $fac->('kern'),     0,  'syslog_facility_enum kern' );
	is( $fac->('security'), 4,  'syslog_facility_enum security alias for auth' );
	is( $fac->('authpriv'), 10, 'syslog_facility_enum authpriv' );
	is( $fac->('local0'),   16, 'syslog_facility_enum local0' );
	is( $fac->('LOCAL7'),   23, 'syslog_facility_enum local7, case-insensitive' );

	my $proto = $M->build( { munger => 'ip_proto_enum' } );
	is( $proto->('tcp'),       6,   'ip_proto_enum tcp' );
	is( $proto->('UDP'),       17,  'ip_proto_enum UDP, case-insensitive' );
	is( $proto->('icmp'),      1,   'ip_proto_enum icmp' );
	is( $proto->('ipv6-icmp'), 58,  'ip_proto_enum ipv6-icmp alias' );
	is( $proto->('sctp'),      132, 'ip_proto_enum sctp' );
	is( $proto->(47),          47,  'ip_proto_enum passes numeric input through' );

	my $tls = $M->build( { munger => 'tls_version_enum' } );
	is( $tls->('SSLv3'),   1, 'tls_version_enum SSLv3' );
	is( $tls->('TLSv1'),   2, 'tls_version_enum TLSv1' );
	is( $tls->('TLSv1.2'), 4, 'tls_version_enum TLSv1.2' );
	is( $tls->('tls1.3'),  5, 'tls_version_enum tls1.3 spelling variant' );
	ok( $tls->('TLSv1.2') < $tls->('TLSv1.3'), 'tls_version_enum ordinals are monotone' );
	eval { $tls->('1.2') };
	like(
		$@,
		qr/no mapping for '1\.2'/,
		'tls_version_enum does NOT pass numbers through (ordinals are not a wire encoding)'
	);

	my $meth = $M->build( { munger => 'http_method_enum' } );
	is( $meth->('GET'),   0, 'http_method_enum GET' );
	is( $meth->('post'),  2, 'http_method_enum post, case-insensitive' );
	is( $meth->('PATCH'), 8, 'http_method_enum PATCH' );
	eval { $meth->('PROPFIND') };
	like( $@, qr/no mapping for 'PROPFIND'/, 'http_method_enum croaks on an unlisted method' );
	my $methd = $M->build( { munger => 'http_method_enum', default => -1 } );
	is( $methd->('PROPFIND'), -1, 'http_method_enum default catches an unlisted method' );

	my $sipm = $M->build( { munger => 'sip_method_enum' } );
	is( $sipm->('INVITE'),   0,  'sip_method_enum INVITE' );
	is( $sipm->('REGISTER'), 4,  'sip_method_enum REGISTER' );
	is( $sipm->('update'),   13, 'sip_method_enum update, case-insensitive' );

	my $dhcp = $M->build( { munger => 'dhcp_msgtype_enum' } );
	is( $dhcp->('DISCOVER'),     1, 'dhcp_msgtype_enum DISCOVER' );
	is( $dhcp->('DHCPDISCOVER'), 1, 'dhcp_msgtype_enum DHCP-prefixed form' );
	is( $dhcp->('nak'),          6, 'dhcp_msgtype_enum nak, case-insensitive' );
	is( $dhcp->(8),              8, 'dhcp_msgtype_enum passes numeric input through' );

	eval { $M->build( { munger => 'dns_rcode_enum', default => 'nope' } ) };
	like( $@, qr/'default' must be numeric/, 'named-map enum validates default at build time' );
}

# ---- scale ----------------------------------------------------------------
{
	my $c = $M->build( { munger => 'scale', min => 0, max => 10 } );
	is( $c->(5),  0.5, 'scale midpoint' );
	is( $c->(15), 1.5, 'scale unclamped overshoot' );

	my $cl = $M->build( { munger => 'scale', min => 0, max => 10, clamp => 1 } );
	is( $cl->(15), 1, 'scale clamps high' );
	is( $cl->(-5), 0, 'scale clamps low' );

	eval { $M->build( { munger => 'scale', min => 3, max => 3 } ) };
	like( $@, qr/must differ/, 'scale rejects zero range' );
}

# ---- zscore ---------------------------------------------------------------
{
	my $c = $M->build( { munger => 'zscore', mean => 10, std => 2 } );
	is( $c->(12),  1, 'zscore +1 sd' );
	is( $c->(6),  -2, 'zscore -2 sd' );
	eval { $M->build( { munger => 'zscore', mean => 0, std => 0 } ) };
	like( $@, qr/non-zero/, 'zscore rejects zero std' );
}

# ---- log ------------------------------------------------------------------
{
	my $ln = $M->build( { munger => 'log' } );
	is( $ln->(1), 0, 'ln(1) == 0' );

	my $l1p = $M->build( { munger => 'log', offset => 1 } );
	is( $l1p->(0), 0, 'log offset lets 0 through' );

	my $l10 = $M->build( { munger => 'log', base => 10, offset => 0 } );
	ok( abs( $l10->(1000) - 3 ) < 1e-9, 'log base 10 of 1000 == 3' );

	eval { $ln->(0) };
	like( $@, qr/must be > 0/, 'log croaks on non-positive' );
}

# ---- clamp ----------------------------------------------------------------
{
	my $c = $M->build( { munger => 'clamp', min => 0, max => 100 } );
	is( $c->(-5),  0,   'clamp low' );
	is( $c->(250), 100, 'clamp high' );
	is( $c->(50),  50,  'clamp passthrough' );

	my $lo = $M->build( { munger => 'clamp', min => 0 } );
	is( $lo->(-1),  0,   'clamp one-sided min' );
	is( $lo->(999), 999, 'clamp one-sided leaves high alone' );

	eval { $M->build( { munger => 'clamp' } ) };
	like( $@, qr/at least one/, 'clamp needs a bound' );
}

# ---- num --------------------------------------------------------------------
{
	my $hex = $M->build( { munger => 'num', base => 16 } );
	is( $hex->('0x1a'),  26,  'num base 16 with 0x prefix' );
	is( $hex->('1A'),    26,  'num base 16 bare, case-insensitive' );
	is( $hex->('-ff'),  -255, 'num base 16 negative' );
	is( $hex->('0'),     0,   'num base 16 zero' );
	eval { $hex->('0x') };
	like( $@, qr/not a base-16 number/, 'num rejects a bare prefix' );
	eval { $hex->('xyz') };
	like( $@, qr/not a base-16 number/, 'num rejects out-of-base digits' );

	my $bin = $M->build( { munger => 'num', base => 2 } );
	is( $bin->('0b1011'), 11, 'num base 2 with 0b prefix' );
	is( $bin->('1011'),   11, 'num base 2 bare' );

	my $oct = $M->build( { munger => 'num', base => 8 } );
	is( $oct->('0o755'), 493, 'num base 8 with 0o prefix' );
	is( $oct->('0755'),  493, 'num base 8: a classic leading zero is just a zero digit' );

	my $dec = $M->build( { munger => 'num' } );
	is( $dec->('42'),   42,   'num base 10 numifies' );
	is( $dec->('6.02'), 6.02, 'num base 10 passes decimals' );
	eval { $dec->('4kb') };
	like( $@, qr/not numeric/, 'num base 10 rejects garbage' );

	eval { $M->build( { munger => 'num', base => 37 } ) };
	like( $@, qr/2 to 36/, 'num rejects base > 36' );
	eval { $M->build( { munger => 'num', base => 1 } ) };
	like( $@, qr/2 to 36/, 'num rejects base < 2' );
}

# ---- bit --------------------------------------------------------------------
{
	# TCP flags: FIN 0x01, SYN 0x02, RST 0x04, PSH 0x08, ACK 0x10.
	my $synack = $M->build( { munger => 'bit', mask => '0x12' } );
	is( $synack->('0x12'), 1, 'bit any: SYN|ACK set (hex input)' );
	is( $synack->(2),      1, 'bit any: SYN alone still hits' );
	is( $synack->(4),      0, 'bit any: RST alone misses' );

	my $syn = $M->build( { munger => 'bit', mask => '0x02', mode => 'all' } );
	is( $syn->(18), 1, 'bit all: SYN set in SYN|ACK' );
	is( $syn->(16), 0, 'bit all: bare ACK has no SYN' );
	my $both = $M->build( { munger => 'bit', mask => '0x12', mode => 'all' } );
	is( $both->(18), 1, 'bit all: both bits present' );
	is( $both->(2),  0, 'bit all: one of two is not all' );

	my $pop = $M->build( { munger => 'bit', mode => 'popcount' } );
	is( $pop->(0),      0, 'bit popcount of 0' );
	is( $pop->('0xff'), 8, 'bit popcount of 0xff' );
	is( $pop->(18),     2, 'bit popcount of SYN|ACK' );
	my $popm = $M->build( { munger => 'bit', mask => '0x07', mode => 'popcount' } );
	is( $popm->('0xff'), 3, 'bit popcount respects the mask' );

	my $nib = $M->build( { munger => 'bit', mask => '0xf0', mode => 'value' } );
	is( $nib->('0xab'), 10, 'bit value: high nibble, shifted down' );
	is( $nib->(0),      0,  'bit value of 0' );

	eval { $synack->('nope') };
	like( $@, qr/not a non-negative integer/, 'bit rejects non-integer input' );
	eval { $synack->(-3) };
	like( $@, qr/not a non-negative integer/, 'bit rejects negative input' );
	eval { $M->build( { munger => 'bit' } ) };
	like( $@, qr/requires a 'mask'/, 'bit requires a mask outside popcount' );
	eval { $M->build( { munger => 'bit', mask => 0 } ) };
	like( $@, qr/must be non-zero/, 'bit rejects a zero mask' );
	eval { $M->build( { munger => 'bit', mask => 'zz' } ) };
	like( $@, qr/'mask' must be/, 'bit rejects a garbage mask' );
	eval { $M->build( { munger => 'bit', mask => 1, mode => 'nope' } ) };
	like( $@, qr/unknown mode 'nope'/, 'bit rejects bad mode' );

	# base => 16: read a bare-hex input, e.g. Suricata's tcp_flags "1b".
	my $hsyn = $M->build( { munger => 'bit', mask => '0x02', base => 16 } );
	is( $hsyn->('1b'),   1, 'bit base16: SYN set in bare-hex 1b' );
	is( $hsyn->('0x1b'), 1, 'bit base16 still accepts a 0x prefix' );
	is( $hsyn->('11'),   0, 'bit base16: "11" is hex 0x11 (no SYN), not decimal' );
	my $hpop = $M->build( { munger => 'bit', mode => 'popcount', base => 16 } );
	is( $hpop->('1b'), 4, 'bit base16 popcount of 0x1b' );
	eval { $hsyn->('zz') };
	like( $@, qr/not a non-negative integer \(hex\)/, 'bit base16 rejects non-hex, names the form' );
	eval { $M->build( { munger => 'bit', mask => 1, base => 2 } ) };
	like( $@, qr/'base' must be 10 or 16/, 'bit rejects an unsupported base' );
}

# ---- Suricata named enums ---------------------------------------------------
{
	my $ap = $M->build( { munger => 'app_proto_enum', default => -1 } );
	is( $ap->('http'),    2,  'app_proto http' );
	is( $ap->('TLS'),     $ap->('tls'), 'app_proto is case-insensitive' );
	is( $ap->('ssl'),     $ap->('tls'), 'app_proto ssl aliases tls' );
	is( $ap->('ikev2'),   $ap->('ike'), 'app_proto ikev2 aliases ike' );
	is( $ap->('unknown'), 0,  'app_proto keeps unknown as a class' );
	is( $ap->('failed'),  1,  'app_proto keeps failed as a class' );
	is( $ap->('wat'),     -1, 'app_proto default for unlisted' );
	eval { $M->build( { munger => 'app_proto_enum' } )->(6) };
	like( $@, qr/no mapping for '6'/, 'app_proto does not pass a number through' );

	my $ts = $M->build( { munger => 'tcp_state_enum' } );
	is( $ts->('none'),        0,  'tcp_state none' );
	is( $ts->('ESTABLISHED'), 3,  'tcp_state established (case-insensitive)' );
	is( $ts->('closed'),      10, 'tcp_state closed' );
	ok( $ts->('syn_sent') < $ts->('established'), 'tcp_state is ordinal along the lifecycle' );

	my $fs = $M->build( { munger => 'flow_state_enum' } );
	is( $fs->('new'),          0, 'flow_state new' );
	is( $fs->('local_bypass'), 4, 'flow_state local_bypass' );

	my $fr = $M->build( { munger => 'flow_reason_enum' } );
	is( $fr->('timeout'),  0, 'flow_reason timeout' );
	is( $fr->('shutdown'), 2, 'flow_reason shutdown' );

	my $ac = $M->build( { munger => 'suricata_action_enum' } );
	is( $ac->('allowed'), 0, 'suricata_action allowed' );
	is( $ac->('blocked'), 1, 'suricata_action blocked' );
	is( $ac->('drop'),    3, 'suricata_action drop (IPS)' );
}

# ---- Postfix / mail named enums ---------------------------------------------
{
	my $ps = $M->build( { munger => 'postfix_status_enum', default => -1 } );
	is( $ps->('sent'),          0,  'postfix_status sent' );
	is( $ps->('DEFERRED'),      1,  'postfix_status is case-insensitive' );
	is( $ps->('bounced'),       2,  'postfix_status bounced' );
	is( $ps->('undeliverable'), 5,  'postfix_status undeliverable (verify)' );
	is( $ps->('whatever'),      -1, 'postfix_status default for unlisted' );
	ok( $ps->('sent') < $ps->('bounced'), 'postfix_status ordered sent-before-bounced' );

	my $spf = $M->build( { munger => 'spf_result_enum' } );
	is( $spf->('pass'),      0, 'spf pass' );
	is( $spf->('softfail'),  3, 'spf softfail' );
	is( $spf->('permerror'), 6, 'spf permerror' );
	is( $spf->('error'),     $spf->('temperror'), 'spf error aliases temperror' );
	is( $spf->('unknown'),   $spf->('permerror'), 'spf unknown aliases permerror' );

	my $dkim = $M->build( { munger => 'dkim_result_enum' } );
	is( $dkim->('pass'),   0, 'dkim pass' );
	is( $dkim->('policy'), 3, 'dkim policy' );
	is( $dkim->('fail'),   4, 'dkim fail' );

	my $dmarc = $M->build( { munger => 'dmarc_result_enum', default => -1 } );
	is( $dmarc->('pass'),          0,  'dmarc pass' );
	is( $dmarc->('fail'),          2,  'dmarc fail' );
	is( $dmarc->('bestguesspass'), 5,  'dmarc opendmarc bestguesspass' );
	is( $dmarc->('quarantine'),    -1, 'dmarc result != disposition (quarantine unlisted)' );

	eval { $M->build( { munger => 'spf_result_enum' } )->(4) };
	like( $@, qr/no mapping for '4'/, 'mail result enums do not pass a number through' );
}

# ---- Apache / Dovecot named enums -------------------------------------------
{
	# The full mechanism set the two SASL mungers share.
	my @mechs = qw(
		anonymous plain login apop cram-md5 digest-md5 ntlm skey otp securid
		rpa kerberos_v4 srp scram-sha-1 scram-sha-1-plus scram-sha-256
		scram-sha-256-plus xoauth2 oauthbearer openid20 saml20 gssapi gs2-krb5
		gss-spnego external
	);
	is( scalar(@mechs), 25, 'fuller SASL registry has 25 mechanisms' );

	my $s = $M->build( { munger => 'sasl_mech_enum',      default => -1 } );
	my $i = $M->build( { munger => 'sasl_mech_iana_enum', default => -1 } );

	# Both mungers cover exactly the same set, distinctly numbered.
	my ( %seen_s, %seen_i, $dup_s, $dup_i );
	for my $m (@mechs) {
		$dup_s++ if $seen_s{ $s->($m) }++;
		$dup_i++ if $seen_i{ $i->($m) }++;
		isnt( $s->($m), -1, "sasl_mech knows '$m'" );
		isnt( $i->($m), -1, "sasl_mech_iana knows '$m'" );
	}
	ok( !$dup_s, 'sasl_mech numbers are distinct' );
	ok( !$dup_i, 'sasl_mech_iana numbers are distinct' );

	# strength order: anonymous/cleartext low, external highest.
	is( $s->('anonymous'), 0,  'sasl_mech anonymous is weakest' );
	ok( $s->('plain') < $s->('scram-sha-256'), 'sasl_mech: plain weaker than scram' );
	ok( $s->('scram-sha-256') < $s->('external'), 'sasl_mech: external strongest tier' );
	# iana order: alphabetical, so anonymous first, xoauth2 last.
	is( $i->('anonymous'), 0,  'sasl_mech_iana anonymous sorts first' );
	is( $i->('xoauth2'),   24, 'sasl_mech_iana xoauth2 sorts last' );

	is( $s->('CRAM-MD5'), $s->('cram-md5'), 'sasl_mech is case-insensitive' );
	is( $s->('wat'),      -1, 'sasl_mech default for unlisted' );
	eval { $M->build( { munger => 'sasl_mech_enum' } )->(2) };
	like( $@, qr/no mapping for '2'/, 'sasl_mech does not pass a number through' );

	# http_version: access-log, bare, and ALPN shorthands all land together.
	my $hv = $M->build( { munger => 'http_version_enum', default => -1 } );
	is( $hv->('HTTP/0.9'), 0, 'http_version HTTP/0.9' );
	is( $hv->('HTTP/1.1'), 2, 'http_version HTTP/1.1' );
	is( $hv->('1.1'),      2, 'http_version bare 1.1' );
	is( $hv->('h2'),       3, 'http_version ALPN h2' );
	is( $hv->('h2c'),      3, 'http_version cleartext h2c' );
	is( $hv->('2'),        3, 'http_version "2" is version 2.0, not the integer' );
	is( $hv->('HTTP/3'),   4, 'http_version HTTP/3 without .0' );
	is( $hv->('h3'),       4, 'http_version ALPN h3' );
	ok( $hv->('HTTP/1.0') < $hv->('HTTP/2.0'), 'http_version is ordinal' );
	is( $hv->('SPDY'),     -1, 'http_version default for unknown' );
}

# ---- SpamAssassin / rspamd / sshd / amavis / systemd / clamav enums ---------
{
	my $al = $M->build( { munger => 'spamassassin_autolearn_enum', default => -1 } );
	is( $al->('no'),          0,  'sa autolearn no' );
	is( $al->('HAM'),         1,  'sa autolearn is case-insensitive' );
	is( $al->('spam'),        2,  'sa autolearn spam' );
	is( $al->('unavailable'), 5,  'sa autolearn unavailable' );
	is( $al->('bogus'),       -1, 'sa autolearn default for unlisted' );

	my $ra = $M->build( { munger => 'rspamd_action_enum', default => -1 } );
	is( $ra->('no action'),       0, 'rspamd no action' );
	is( $ra->('no_action'),       0, 'rspamd no_action underscore alias' );
	is( $ra->('greylist'),        1, 'rspamd greylist' );
	is( $ra->('add header'),      2, 'rspamd add header' );
	is( $ra->('add_header'),      2, 'rspamd add_header underscore alias' );
	is( $ra->('rewrite subject'), 3, 'rspamd rewrite subject' );
	is( $ra->('soft reject'),     4, 'rspamd soft reject' );
	is( $ra->('reject'),          5, 'rspamd reject' );
	ok( $ra->('greylist') < $ra->('reject'), 'rspamd_action ordered by severity' );

	my $sm = $M->build( { munger => 'ssh_auth_method_enum', default => -1 } );
	is( $sm->('none'),                 0,  'ssh none' );
	is( $sm->('password'),             1,  'ssh password' );
	is( $sm->('keyboard-interactive'), 2,  'ssh keyboard-interactive' );
	is( $sm->('publickey'),            4,  'ssh publickey' );
	is( $sm->('gssapi'),  $sm->('gssapi-with-mic'), 'ssh gssapi aliases gssapi-with-mic' );
	ok( $sm->('password') < $sm->('publickey'), 'ssh_auth_method weakest-to-strongest' );
	is( $sm->('magic'),                -1, 'ssh_auth_method default for unlisted' );

	my $am = $M->build( { munger => 'amavis_category_enum', default => -1 } );
	is( $am->('clean'),      0, 'amavis clean' );
	is( $am->('spam'),       4, 'amavis spam' );
	is( $am->('bad-header'), $am->('badheader'), 'amavis bad-header aliases badheader' );
	is( $am->('virus'),      $am->('infected'),  'amavis virus aliases infected' );
	ok( $am->('clean') < $am->('infected'), 'amavis_category ordered clean-to-worst' );

	my $sr = $M->build( { munger => 'systemd_result_enum', default => -1 } );
	is( $sr->('success'),         0, 'systemd success' );
	is( $sr->('timeout'),         2, 'systemd timeout' );
	is( $sr->('exit-code'),       3, 'systemd exit-code' );
	is( $sr->('exit_code'),       $sr->('exit-code'), 'systemd exit_code underscore alias' );
	is( $sr->('oom_kill'),        $sr->('oom-kill'),  'systemd oom_kill underscore alias' );

	my $cv = $M->build( { munger => 'clamav_result_enum', default => -1 } );
	is( $cv->('OK'),      0,  'clamav OK (case-insensitive)' );
	is( $cv->('FOUND'),   1,  'clamav FOUND' );
	is( $cv->('error'),   2,  'clamav error' );
	is( $cv->('whatnow'), -1, 'clamav default for unlisted' );

	eval { $M->build( { munger => 'rspamd_action_enum' } )->(2) };
	like( $@, qr/no mapping for '2'/, 'daemon enums do not pass a number through' );
}

# ---- Windows / Kerberos named enums -----------------------------------------
{
	# kerberos_etype: hex spellings and names resolve to the RFC 3961 etype
	# number, and a decimal (the wire value) passes straight through.
	my $ke = $M->build( { munger => 'kerberos_etype_enum', default => -1 } );
	is( $ke->('0x17'),        23, 'kerberos_etype hex 0x17 is rc4-hmac' );
	is( $ke->('rc4-hmac'),    23, 'kerberos_etype rc4-hmac name' );
	is( $ke->('RC4'),         23, 'kerberos_etype rc4 alias, case-insensitive' );
	is( $ke->('0x12'),        18, 'kerberos_etype hex 0x12 is aes256' );
	is( $ke->('aes256'),      18, 'kerberos_etype aes256 name' );
	is( $ke->(23),            23, 'kerberos_etype decimal 23 passes through (wire value)' );
	is( $ke->('0x17'), $ke->('rc4-hmac'), 'kerberos_etype hex and name agree' );
	ok( $ke->('rc4-hmac') > $ke->('aes256'), 'kerberos_etype rc4 sorts above aes256 (downgrade signal)' );
	is( $ke->('0xdead'),      -1, 'kerberos_etype default for unlisted' );

	my $il = $M->build( { munger => 'windows_integrity_level_enum', default => -1 } );
	is( $il->('Untrusted'),   0,  'integrity untrusted (case-insensitive)' );
	is( $il->('Medium'),      2,  'integrity medium' );
	is( $il->('System'),      4,  'integrity system' );
	is( $il->('mediumplus'),  2,  'integrity mediumplus folds into medium' );
	is( $il->('S-1-16-12288'), 3, 'integrity high mandatory-label SID' );
	ok( $il->('Low') < $il->('System'), 'windows_integrity_level is ordinal' );
	is( $il->('bogus'),       -1, 'integrity default for unlisted' );

	my $ls = $M->build( { munger => 'windows_logon_status_enum', default => -1 } );
	is( $ls->('0xC0000064'),  0,  'logon_status no-such-user (case-insensitive hex)' );
	is( $ls->('0xc000006a'),  1,  'logon_status bad password' );
	is( $ls->('0xc0000234'),  10, 'logon_status locked out' );
	is( $ls->('0xc000015b'),  11, 'logon_status type not granted' );
	is( $ls->('0x0'),         -1, 'logon_status default for a success/unlisted code' );

	my $im = $M->build( { munger => 'windows_impersonation_level_enum', default => -1 } );
	is( $im->('Anonymous'),      0, 'impersonation anonymous' );
	is( $im->('Impersonation'),  2, 'impersonation impersonation' );
	is( $im->('Delegation'),     3, 'impersonation delegation' );
	is( $im->('%%1832'),         1, 'impersonation %%1832 token is identification' );
	is( $im->('%%1833'),         2, 'impersonation %%1833 token is impersonation' );
	ok( $im->('anonymous') < $im->('delegation'), 'windows_impersonation_level ordered by reach' );

	eval { $M->build( { munger => 'windows_integrity_level_enum' } )->(3) };
	like( $@, qr/no mapping for '3'/, 'windows ordinal enums do not pass a number through' );
}

# ---- O365 / Azure AD / AWS cloud named enums --------------------------------
{
	# aad_signin_error: the sparse ResultType code space collapsed to reasons.
	my $se = $M->build( { munger => 'aad_signin_error_enum', default => -1 } );
	is( $se->('0'),        0,  'aad_signin_error 0 is success' );
	is( $se->('50126'),    1,  'aad_signin_error 50126 bad-password' );
	is( $se->('50056'),    $se->('50126'), 'aad_signin_error 50056 shares bad-password bucket' );
	is( $se->('50144'),    $se->('50055'), 'aad_signin_error 50144 shares password-expired bucket' );
	is( $se->('53000'),    8,  'aad_signin_error 53000 blocked-by-CA bucket' );
	is( $se->(50053),      4,  'aad_signin_error accepts an integer code' );
	is( $se->('99999'),    -1, 'aad_signin_error default for an unlisted code' );

	my $rl = $M->build( { munger => 'risk_level_enum', default => -1 } );
	is( $rl->('none'),   0,  'risk_level none' );
	is( $rl->('High'),   3,  'risk_level high (case-insensitive)' );
	is( $rl->('hidden'), -1, 'risk_level hidden is off-scale (default)' );
	ok( $rl->('low') < $rl->('high'), 'risk_level is ordinal' );

	my $pt = $M->build( { munger => 'aws_principal_type_enum', default => -1 } );
	is( $pt->('Root'),        0,  'aws_principal_type root (the alert signal)' );
	is( $pt->('AssumedRole'), 2,  'aws_principal_type assumedrole' );
	is( $pt->('IAMUser'),     1,  'aws_principal_type iamuser (case-insensitive)' );
	is( $pt->('nope'),        -1, 'aws_principal_type default for unlisted' );

	# aad_client_app: modern < 2, legacy >= 2 (the legacy-auth threshold).
	my $ca = $M->build( { munger => 'aad_client_app_enum', default => -1 } );
	is( $ca->('Browser'),                         0, 'aad_client_app browser is modern' );
	is( $ca->('Mobile Apps and Desktop clients'), 1, 'aad_client_app modern desktop' );
	ok( $ca->('IMAP4') >= 2,  'aad_client_app IMAP4 is legacy (>= 2)' );
	ok( $ca->('POP3')  >= 2,  'aad_client_app POP3 is legacy (>= 2)' );
	is( $ca->('imap'), $ca->('IMAP4'), 'aad_client_app imap short alias' );
	ok( $ca->('Browser') < 2 && $ca->('Other clients') >= 2,
		'aad_client_app: modern sorts below the legacy-auth threshold' );

	my $rs = $M->build( { munger => 'risk_state_enum', default => -1 } );
	is( $rs->('none'),                 0, 'risk_state none' );
	is( $rs->('atRisk'),               4, 'risk_state atRisk (case-insensitive)' );
	is( $rs->('confirmedCompromised'), 5, 'risk_state confirmedCompromised' );

	my $ls = $M->build( { munger => 'vpc_flow_log_status_enum', default => -1 } );
	is( $ls->('OK'),       0,  'vpc_flow_log_status OK' );
	is( $ls->('NODATA'),   1,  'vpc_flow_log_status NODATA' );
	is( $ls->('SKIPDATA'), 2,  'vpc_flow_log_status SKIPDATA' );

	my $et = $M->build( { munger => 'aws_event_type_enum', default => -1 } );
	is( $et->('AwsApiCall'),       0, 'aws_event_type AwsApiCall' );
	is( $et->('AwsConsoleSignIn'), 3, 'aws_event_type AwsConsoleSignIn (the signal)' );

	my $cs = $M->build( { munger => 'conditional_access_result_enum', default => -1 } );
	is( $cs->('success'),    0, 'conditional_access success' );
	is( $cs->('notApplied'), 1, 'conditional_access notApplied (case-insensitive)' );
	is( $cs->('failure'),    4, 'conditional_access failure' );

	eval { $M->build( { munger => 'aws_principal_type_enum' } )->(0) };
	like( $@, qr/no mapping for '0'/, 'cloud category enums do not pass a number through' );
}

# ---- ip_class ---------------------------------------------------------------
{
	my $c = $M->build( { munger => 'ip_class' } );

	# v4: one probe per class
	is( $c->('8.8.8.8'),         0, 'ip_class v4 global' );
	is( $c->('10.1.2.3'),        1, 'ip_class 10/8 private' );
	is( $c->('172.16.0.1'),      1, 'ip_class 172.16/12 private' );
	is( $c->('172.32.0.1'),      0, 'ip_class 172.32 is NOT private' );
	is( $c->('192.168.99.1'),    1, 'ip_class 192.168/16 private' );
	is( $c->('100.64.0.1'),      1, 'ip_class CGNAT counts as private' );
	is( $c->('100.128.0.1'),     0, 'ip_class just past CGNAT is global' );
	is( $c->('127.0.0.53'),      2, 'ip_class loopback' );
	is( $c->('169.254.1.1'),     3, 'ip_class v4 link-local' );
	is( $c->('224.0.0.251'),     4, 'ip_class v4 multicast' );
	is( $c->('239.255.255.250'), 4, 'ip_class multicast high edge' );
	is( $c->('255.255.255.255'), 5, 'ip_class broadcast' );
	is( $c->('0.0.0.0'),         6, 'ip_class v4 unspecified' );
	is( $c->('0.1.2.3'),         7, 'ip_class rest of 0/8 reserved' );
	is( $c->('192.0.2.55'),      7, 'ip_class TEST-NET-1 reserved' );
	is( $c->('198.51.100.7'),    7, 'ip_class TEST-NET-2 reserved' );
	is( $c->('203.0.113.9'),     7, 'ip_class TEST-NET-3 reserved' );
	is( $c->('198.18.0.1'),      7, 'ip_class benchmarking reserved' );
	is( $c->('240.0.0.1'),       7, 'ip_class 240/4 reserved' );

	# v6
	is( $c->('2600:1700::1'),      0, 'ip_class v6 global' );
	is( $c->('fd12:3456:789a::1'), 1, 'ip_class ULA private' );
	is( $c->('::1'),               2, 'ip_class v6 loopback' );
	is( $c->('fe80::1'),           3, 'ip_class v6 link-local' );
	is( $c->('ff02::fb'),          4, 'ip_class v6 multicast' );
	is( $c->('::'),                6, 'ip_class v6 unspecified' );
	is( $c->('2001:db8::1'),       7, 'ip_class v6 documentation reserved' );
	is( $c->('100::1'),            7, 'ip_class discard prefix reserved' );
	is( $c->('::ffff:10.0.0.1'),   1, 'ip_class v4-mapped classifies the embedded v4' );
	is( $c->('::ffff:8.8.8.8'),    0, 'ip_class v4-mapped global' );

	eval { $c->('not-an-ip') };
	like( $@, qr/not a parseable IP address/, 'ip_class croaks on garbage without default' );
	eval { $c->('10.0.0.256') };
	like( $@, qr/not a parseable IP address/, 'ip_class rejects out-of-range octets' );

	my $d = $M->build( { munger => 'ip_class', default => -1 } );
	is( $d->('not-an-ip'), -1, 'ip_class default for garbage' );
	is( $d->(undef),       -1, 'ip_class default for undef' );
	eval { $M->build( { munger => 'ip_class', default => 'x' } ) };
	like( $@, qr/'default' must be numeric/, 'ip_class validates default at build time' );
}

# ---- cidr -------------------------------------------------------------------
{
	my $c = $M->build(
		{
			munger  => 'cidr',
			nets    => [ '10.10.0.0/16', '10.0.0.0/8', '2001:db8:5::/48' ],
			default => -1,
		}
	);
	is( $c->('10.10.3.4'),      0, 'cidr: most-specific first match wins' );
	is( $c->('10.99.0.1'),      1, 'cidr: falls through to the wider net' );
	is( $c->('2001:db8:5::7'),  2, 'cidr: v6 net matches' );
	is( $c->('2001:db8:6::7'), -1, 'cidr: v6 outside the /48 takes default' );
	is( $c->('192.168.1.1'),   -1, 'cidr: unmatched v4 takes default' );
	is( $c->('not-an-ip'),     -1, 'cidr: garbage takes default' );

	# a v4 address is never tested against v6 nets (and vice versa)
	my $v6only = $M->build( { munger => 'cidr', nets => ['::/0'], default => -1 } );
	is( $v6only->('8.8.8.8'), -1, 'cidr: ::/0 does not swallow v4' );
	my $v4any = $M->build( { munger => 'cidr', nets => ['0.0.0.0/0'], default => -1 } );
	is( $v4any->('8.8.8.8'), 0, 'cidr: 0.0.0.0/0 matches any v4' );

	my $strict = $M->build( { munger => 'cidr', nets => ['10.0.0.0/8'] } );
	eval { $strict->('192.168.1.1') };
	like( $@, qr/none of the listed networks/, 'cidr croaks on no match without default' );
	eval { $strict->('nope') };
	like( $@, qr/not a parseable IP address/, 'cidr croaks on garbage without default' );

	eval { $M->build( { munger => 'cidr', nets => [] } ) };
	like( $@, qr/non-empty 'nets'/, 'cidr rejects empty nets' );
	eval { $M->build( { munger => 'cidr', nets => ['10.0.0.0'] } ) };
	like( $@, qr/'address\/prefix' form/, 'cidr rejects a bare address' );
	eval { $M->build( { munger => 'cidr', nets => ['10.0.0.0/33'] } ) };
	like( $@, qr/prefix length must be 0-32/, 'cidr rejects an oversized v4 prefix' );
	eval { $M->build( { munger => 'cidr', nets => ['wat/8'] } ) };
	like( $@, qr/unparseable address/, 'cidr rejects an unparseable net address' );
}

# ---- datetime -------------------------------------------------------------
SKIP: {
	eval { require Time::Piece; 1 }
		or skip 'Time::Piece not available', 3;

	my $ep = $M->build( { munger => 'datetime', format => '%Y-%m-%dT%H:%M:%S', part => 'epoch' } );
	# 2026-07-06T12:00:00 UTC via strptime (Time::Piece strptime is UTC)
	my $t = Time::Piece->strptime( '2026-07-06T12:00:00', '%Y-%m-%dT%H:%M:%S' );
	is( $ep->('2026-07-06T12:00:00'), $t->epoch, 'datetime epoch part' );

	my $hr = $M->build( { munger => 'datetime', format => '%Y-%m-%dT%H:%M:%S', part => 'hour' } );
	is( $hr->('2026-07-06T12:00:00'), 12, 'datetime hour part' );

	my $fd = $M->build( { munger => 'datetime', format => '%Y-%m-%dT%H:%M:%S', part => 'frac_day' } );
	is( $fd->('2026-07-06T12:00:00'), 0.5, 'datetime frac_day at noon' );

	my $fw = $M->build( { munger => 'datetime', format => '%Y-%m-%dT%H:%M:%S', part => 'frac_week' } );
	# 2026-07-05 is a Sunday (wday 0): midnight Sunday is the week origin.
	is( $fw->('2026-07-05T00:00:00'), 0, 'datetime frac_week at Sunday midnight' );
	# 2026-07-06 is Monday (wday 1) noon: (1*86400 + 43200)/604800.
	is( $fw->('2026-07-06T12:00:00'), ( 86400 + 43200 ) / 604800, 'datetime frac_week at Monday noon' );

	# cyclic parts: noon is frac_day 0.5 -> sin(pi)=0, cos(pi)=-1.
	my $sd = $M->build( { munger => 'datetime', format => '%Y-%m-%dT%H:%M:%S', part => 'sin_day' } );
	my $cd = $M->build( { munger => 'datetime', format => '%Y-%m-%dT%H:%M:%S', part => 'cos_day' } );
	ok( abs( $sd->('2026-07-06T12:00:00') - 0 ) < 1e-9, 'sin_day at noon ~ 0' );
	ok( abs( $cd->('2026-07-06T12:00:00') + 1 ) < 1e-9, 'cos_day at noon ~ -1' );
	# continuity across midnight: sin/cos barely move over a one-minute wrap.
	# a 60s wrap moves sin by ~2*pi*(60/86400) ~ 0.0044, vs the ~1.0 jump
	# frac_day would show at the same seam.
	my $near_mid_a = $sd->('2026-07-06T23:59:30');
	my $near_mid_b = $sd->('2026-07-07T00:00:30');
	ok( abs( $near_mid_a - $near_mid_b ) < 1e-2, 'sin_day is continuous across midnight' );

	my $cw = $M->build( { munger => 'datetime', format => '%Y-%m-%dT%H:%M:%S', part => 'cos_week' } );
	# Sunday midnight is frac_week 0 -> cos(0) = 1.
	ok( abs( $cw->('2026-07-05T00:00:00') - 1 ) < 1e-9, 'cos_week at week origin ~ 1' );
} ## end SKIP:

# ---- hash (XS or PP; both must agree with these fixed FNV-1a values) -------
{
	diag( 'hash munger path: HAVE_XS = ' . $Algorithm::ToNumberMunger::HAVE_XS );

	my $raw = $M->build( { munger => 'hash' } );
	# Known FNV-1a 32-bit vectors.
	is( $raw->(''),       2166136261, 'fnv1a empty string' );
	is( $raw->('a'),      3826002220, 'fnv1a "a"' );
	is( $raw->('foobar'), 3214735720, 'fnv1a "foobar"' );

	my $b = $M->build( { munger => 'hash', buckets => 100 } );
	ok( $b->('anything') >= 0 && $b->('anything') < 100, 'hash respects buckets' );

	# Same key + same bucket count is stable; seed decorrelates.
	my $s0 = $M->build( { munger => 'hash', buckets => 1_000_000, seed => 0 } );
	my $s7 = $M->build( { munger => 'hash', buckets => 1_000_000, seed => 7 } );
	isnt( $s0->('shared'), $s7->('shared'), 'seed changes the hash' );

	eval { $M->build( { munger => 'hash', buckets => 0 } ) };
	like( $@, qr/positive integer/, 'hash rejects zero buckets' );
}

# ---- chain ------------------------------------------------------------------
{
	my $tld = $M->build(
		{
			munger => 'chain',
			steps  => [ { op => 'lc' }, { op => 'split', on => '.', index => -1 } ],
			then   => { munger => 'length' },
		}
	);
	is( $tld->('WWW.Example.COM'), 3, 'chain: lc + split[-1] + length takes the last label' );
	is( $tld->('nodots'),          6, 'chain: split with no separator keeps the whole string' );
	is( $tld->(undef),             0, 'chain: undef enters as the empty string' );

	my $oob = $M->build(
		{
			munger => 'chain',
			steps  => [ { op => 'split', on => '.', index => 5 } ],
			then   => { munger => 'length' },
		}
	);
	is( $oob->('a.b'), 0, 'chain: out-of-range split index yields empty' );

	my $cap = $M->build(
		{
			munger => 'chain',
			steps  => [ { op => 'capture', pattern => 'req-(0x[0-9a-f]+)', ignore_case => 1 } ],
			then   => { munger => 'num', base => 16 },
		}
	);
	is( $cap->('REQ-0x2F done'), 47, 'chain: capture feeds num base 16' );

	my $nogroup = $M->build(
		{
			munger => 'chain',
			steps  => [ { op => 'capture', pattern => 'xyz' } ],
			then   => { munger => 'length' },
		}
	);
	is( $nogroup->('xyz'), 0, 'chain: capture with no group in the pattern yields empty' );

	my $norm = $M->build(
		{
			munger => 'chain',
			steps  => [ { op => 'trim' }, { op => 'uc' } ],
			then   => { munger => 'enum', map => { GET => 0, POST => 1 } },
		}
	);
	is( $norm->('  post '), 1, 'chain: trim + uc normalizes into an enum' );

	my $strip = $M->build(
		{
			munger => 'chain',
			steps  => [ { op => 'replace', pattern => '[0-9]' } ],
			then   => { munger => 'length' },
		}
	);
	is( $strip->('a1b2c3'), 3, 'chain: replace deletes matches by default' );

	my $swap = $M->build(
		{
			munger => 'chain',
			steps  =>
				[ { op => 'replace', pattern => '-+', with => '.' }, { op => 'split', on => '.', index => 1 } ],
			then => { munger => 'length' },
		}
	);
	is( $swap->('ab--cdef'), 4, 'chain: replace with a literal string feeds later steps' );

	# nested chain as the terminal
	my $nested = $M->build(
		{
			munger => 'chain',
			steps  => [ { op => 'lc' } ],
			then   => {
				munger => 'chain',
				steps  => [ { op => 'split', on => '.', index => 0 } ],
				then   => { munger => 'length' },
			},
		}
	);
	is( $nested->('AB.cd'), 2, 'chain: a chain can terminate in another chain' );

	# build-time error surface
	eval { $M->build( { munger => 'chain', then => { munger => 'length' } } ) };
	like( $@, qr/non-empty 'steps'/, 'chain requires steps' );

	eval { $M->build( { munger => 'chain', steps => [ { op => 'nope' } ], then => { munger => 'length' } } ) };
	like( $@, qr/unknown op 'nope'/, 'chain rejects an unknown op' );

	eval { $M->build( { munger => 'chain', steps => [ { op => 'lc' } ] }, 'x' ) };
	like( $@, qr/requires a 'then' hashref/, 'chain requires a terminal' );

	eval { $M->build( { munger => 'chain', steps => [ { op => 'lc' } ], then => { munger => 'wat' } } ) };
	like( $@, qr/unknown terminal munger 'wat'/, 'chain rejects an unknown terminal' );

	eval { $M->build( { munger => 'chain', steps => [ { op => 'split' } ], then => { munger => 'length' } } ) };
	like( $@, qr/split step requires a non-empty 'on'/, 'chain split requires on' );

	eval {
		$M->build(
			{ munger => 'chain', steps => [ { op => 'capture', pattern => '(' } ], then => { munger => 'length' } }
		);
	};
	like( $@, qr/cannot compile pattern/, 'chain capture rejects a broken pattern at build time' );

	eval {
		$M->build( { munger => 'chain', steps => [ { op => 'lc' } ], then => { munger => 'log', base => 'x' } },
			'sometag' );
	};
	like( $@, qr/chain terminal/, 'a bad terminal parameter names the chain terminal' );
}

# ---- ratio / combine (compile-only; the scalar path croaks with guidance) ---
{
	for my $name (qw(ratio combine)) {
		ok( $M->has_munger($name), "$name is a known munger" );
		eval { $M->build( { munger => $name }, 'x' ) };
		like( $@, qr/only usable\s+via compile\(\)/, "$name croaks with guidance on the scalar path" );
	}
}

# ---- build_all + error surface -------------------------------------------
{
	my $by_tag = $M->build_all(
		{
			method => { munger => 'enum', map    => { GET => 0, POST => 1 } },
			bytes  => { munger => 'log',  offset => 1 },
		}
	);
	is( $by_tag->{method}->('POST'), 1, 'build_all wires method' );
	is( $by_tag->{bytes}->(0),       0, 'build_all wires bytes' );

	is_deeply( $M->build_all(undef), {}, 'build_all(undef) is empty' );

	eval { $M->build( { munger => 'bogus' }, 'sometag' ) };
	like( $@, qr/unknown munger 'bogus' for tag 'sometag'/, 'unknown munger names the tag' );
}

done_testing;
