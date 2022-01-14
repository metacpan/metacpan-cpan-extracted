use Test2::V0;
use Test2::Require::Module 'Regexp::Pattern::License' => '3.9.0';

use Log::Any::Test;
use Log::Any qw($log);

use App::Licensecheck;

plan 14;

my $short_head = App::Licensecheck->new(
	shortname_scheme => 'debian,spdx',
	top_lines        => 10,
);

my $short_head_short_tail = App::Licensecheck->new(
	shortname_scheme => 'debian,spdx',
	top_lines        => 10,
	end_bytes        => 10,
);

my $only_at_end  = 't/devscripts/artistic-2-0-modules.pm';
my $at_end       = 't/devscripts/info-at-eof.h';
my $complex_tail = 't/exception/Bison/grammar.cxx';
my $complex      = 't/exception/Cecill/tv_implementpoly.reference';

sub msgs
{
	return map { $_->{message} } @{ $log->msgs };
}

sub some_msgs
{
	return [ grep {/^(?:header|tail|-----)/} msgs() ];
}

is [ $short_head->parse($only_at_end) ], [
	'Artistic-2.0',
	'2009 Moritz Lenz and the SVG::Plot contributors (see file'
	],
	'Detected trailing Artistic license and owner';
is some_msgs(), [
	match qr/label-font-size;\n----- end header -----$/s,
	'tail offset set to 2498',
	match qr/^----- tail -----\n\};\n/s,
	],
	'logs', msgs();

$log->clear;
is [ $short_head->parse($at_end) ],
	[ 'Expat', '1994-2012 Lua.org, PUC-Rio.' ],
	'Detected trailing Expat license and owner';
is some_msgs(), [
	match qr/#define lua_h\n----- end header -----$/s,
	'tail offset set to 7131',
	match qr/^----- tail -----\n\(lua_State /s,
	],
	'logs', msgs();

$log->clear;
is [ $short_head->parse($complex_tail) ],
	[ 'MPL-2.0', '' ],
	'Missed complex licensing and owner';
is some_msgs(), [
	match qr/notice:\n \*\n----- end header -----$/s,
	'tail offset set to 13328',
	],
	'logs', msgs();

$log->clear;
is [ $short_head->parse($complex) ],
	[ 'CECILL-C with Sollya-4.1 exception', '2006-2018' ],
	'Missed owner at top';
is some_msgs(), [
	match qr/exception below\.\n----- end header -----$/s,
	'tail offset set to 669 (end of header)',
	match qr/^----- tail -----\n    Sollya is\n/s,
	],
	'logs', msgs();

$log->clear;
is [ $short_head_short_tail->parse($only_at_end) ],
	[ 'UNKNOWN', '' ],
	'Missed trailing Artistic license and owner';
is some_msgs(), [
	match qr/label-font-size;\n----- end header -----$/s,
	'tail offset set to 7488',
	match qr/^----- tail -----\n ft=perl6/s,
	],
	'logs', msgs();

$log->clear;
is [ $short_head_short_tail->parse($at_end) ],
	[ 'UNKNOWN', '' ],
	'Missed trailing Expat license and owner';
is some_msgs(), [
	match qr/#define lua_h\n----- end header -----$/s,
	'tail offset set to 12121',
	match qr/^----- tail -----\n\n\n\n#endif/s,
	],
	'logs', msgs();

$log->clear;
is [ $short_head_short_tail->parse($complex) ],
	[ 'UNKNOWN', '' ],
	'Missed owner at top and complex licensing at end';
is some_msgs(), [
	match qr/exception below\.\n----- end header -----$/s,
	'tail offset set to 4899',
	match qr/^----- tail -----\n\.\n/s,
	],
	'logs', msgs();

done_testing;
