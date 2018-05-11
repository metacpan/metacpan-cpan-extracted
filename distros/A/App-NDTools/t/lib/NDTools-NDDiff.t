use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Term::ANSIColor qw(color);
use Test::More tests => 6;

use App::NDTools::Test;

chdir t_dir or die "Failed to change test dir";

use_ok('App::NDTools::NDDiff') || die "Failed to load module";

my ($mod, $got, $exp);

$mod = App::NDTools::NDDiff->new('foo', 'bar');

$got = capture { $mod->print_term_header('one.json', 'two.json') };
is($got, '', "term header: noTTY");

$mod->{TTY} = 1;
$mod->{OPTS}->{quiet} = 1;
$got = capture { $mod->print_term_header('one.json', 'two.json') };
$mod->{OPTS}->{quiet} = 0;
is($got, '', "term header: TTY, but opt quiet");

$exp = "!!! diff.json\n";
$mod->{TTY} = 1;
$got = capture { $mod->print_term_header('diff.json') };
is($got, $exp, "term header: TTY, one name");

$exp = "--- one.json\n+++ two.json\n";
$mod->{TTY} = 1;
$got = capture { $mod->print_term_header('one.json', 'two.json') };
is($got, $exp, "term header: TTY");

$exp = color('yellow') . "--- one.json\n+++ two.json" . color('reset') . "\n";
$mod->{OPTS}->{colors} = 1;
$mod->configure();
$got = capture { $mod->print_term_header('one.json', 'two.json') };
is($got, $exp, "term header: TTY, colors");

