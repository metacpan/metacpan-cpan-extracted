#!perl

use Test::More tests => 28;
use Config::Param;

use strict;

# Testing variants of providing array and hash arguments with and
# without equal sign.

my $config = {verbose=>0, nofinals=>1};
my $p;
# Baseline: Clearing should work.

my $ref = { help=>0, config=>[], arr=>[], has=>{} };

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $Config::Param::arg ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $Config::Param::arg ]
], ["--arr//", "--has//"] );
is_deeply($p, $ref, "clearing 1");

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $Config::Param::arg ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $Config::Param::arg ]
], ["-a//", "-H//"] );
is_deeply($p, $ref, "clearing 2");

for my $sep ('', '/,/')
{

my $rac = 0;
my $name = $sep ? "required with separator ": "required arg ";
my $ref = $sep
? { help=>1, config=>[], arr=>['a', 'b'], has=>{a=>1,b=>2}  }
: { help=>1, config=>[], arr=>['a,b'],    has=>{a=>'1,b=2'} };
my $p;
my $flags = $Config::Param::arg;

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $flags ]
], ["--arr$sep=a,b", "--has$sep=a=1,b=2", "-h"] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $flags ]
], ["--arr$sep", "a,b", "--has$sep", "a=1,b=2", "-h"] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $flags ]
],["-a$sep=a,b", "-H$sep=a=1,b=2", "-h"] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $flags ]
],["-ha$sep=a,b", "-H$sep=a=1,b=2" ] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $flags ]
], ["-a$sep", "a,b", "-H$sep", "a=1,b=2", "-h"] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $flags ]
], ["-a${sep}a,b", "-H${sep}a=1,b=2", "-h"] );
is_deeply($p, $ref, $name.++$rac);

# Now with appendage

push(@{$ref->{arr}}, 'c');
$ref->{has}{c} = 3;

$p = Config::Param::get( $config, [
	[ 'arr', ['foo'], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {foo=>'bar'}, 'H', 'stuff'
	,	'elements', $flags ]
], ["--arr$sep=a,b", "--arr.=c", "--has$sep=a=1,b=2", "--has.=c=3", "-h"] );
is_deeply($p, $ref, $name.++$rac);

# Now with implicit appendages.

$name .= "(appending) ";
$flags |= $Config::Param::append;

push(@{$ref->{arr}}, 'd');
$p = Config::Param::get( $config, [
	[ 'arr', [], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {}, 'H', 'stuff'
	,	'elements', $flags ]
], [
	"--arr$sep=a,b", "--arr=c",
,	"--has$sep=a=1,b=2", "--has=c=3"
,	"--arr.=d" # Also should not break explicit appending!
,	"-h"
] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', [], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {}, 'H', 'stuff'
	,	'elements', $flags ]
], [
	"--arr$sep", "a,b", "--arr", "c"
,	"--has$sep", "a=1,b=2", "--has", "c=3"
,	"--arr.=d" # Also should not break explicit appending!
,	"-h"
] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', [], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {}, 'H', 'stuff'
	,	'elements', $flags ]
],[
	"-a$sep=a,b", "-a=c", "-a.=d"
,	"-H$sep=a=1,b=2", "-H=c=3"
,	"-h"
] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', [], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {}, 'H', 'stuff'
	,	'elements', $flags ]
],[
	"-ha$sep=a,b", "-a=c", "-a.=d"
,	"-H$sep=a=1,b=2", "-H=c=3"
] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', [], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {}, 'H', 'stuff'
	,	'elements', $flags ]
], [
	"-a$sep", "a,b", "-a", "c", "-a.=d"
,	"-H$sep", "a=1,b=2", "-H", "c=3"
,	"-h"
] );
is_deeply($p, $ref, $name.++$rac);

$p = Config::Param::get( $config, [
	[ 'arr', [], 'a', 'stuff'
	,	'elements', $flags ]
,	[ 'has', {}, 'H', 'stuff'
	,	'elements', $flags ]
], [
	"-a${sep}a,b", "-ac", "-a.=d"
,	"-H${sep}a=1,b=2", "-Hc=3"
,	"-h"
] );
is_deeply($p, $ref, $name.++$rac);


}
