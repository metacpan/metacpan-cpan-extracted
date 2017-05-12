#!perl -wT
use strict;

use Test::More tests => 12;

use Scalar::Util qw(tainted);

use Acme::StringFormat;

# TAINT

my $tainted = substr($^X, 0, 0);

ok tainted($tainted), 'running in taint mode';

ok !tainted('[%s]' % 'foo'), 'untainted';

ok tainted( "[%s]$tainted" % 'foo' ), 'lhs';
ok tainted( '[%s]' % "foo$tainted" ), 'rhs';

my $fmt = '[%s]';

$fmt %= "foo$tainted";

ok tainted($fmt), 'assign';

# UTF8

my $unistr = "\x{307b}\x{3052}\x{ff01}"; # [hoge] in Japanese hiragana

ok utf8::is_utf8($unistr), 'deals with utf8 string';

ok utf8::is_utf8("[%s]$unistr" % 'foo'), 'lhs';
is "[%s]$unistr" % 'foo', "[foo]$unistr";

ok utf8::is_utf8('[%s]' % $unistr), 'rhs';
is '[%s]' % $unistr, "[$unistr]";

$fmt = '[%s]';
$fmt %= $unistr;

ok utf8::is_utf8($fmt), 'assign';
is $fmt, "[$unistr]";
