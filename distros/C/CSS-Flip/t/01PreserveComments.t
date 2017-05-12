#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 5;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase = '/* left /* right */left: 10px';
$shouldbe = '/* left /* right */right: 10px';
is($self->transform($testcase), $shouldbe);

$testcase = '/*left*//*left*/left: 10px';
$shouldbe = '/*left*//*left*/right: 10px';
is($self->transform($testcase), $shouldbe);

$testcase = "/* Going right is cool */\n#test {left: 10px}";
$shouldbe = "/* Going right is cool */\n#test {right: 10px}";
is($self->transform($testcase), $shouldbe);

$testcase = "/* padding-right 1 2 3 4 */\n#test {left: 10px}\n/*right*/";
$shouldbe = "/* padding-right 1 2 3 4 */\n#test {right: 10px}\n/*right*/";
is($self->transform($testcase), $shouldbe);

$testcase = "/** Two line comment\n * left\n \\*/\n#test {left: 10px}";
$shouldbe = "/** Two line comment\n * left\n \\*/\n#test {right: 10px}";
is($self->transform($testcase), $shouldbe);

