#!perl -T

use strict;
use warnings;
use Test::More tests => 4;
use utf8;

use Dancer::FileUtils 'path';
use Dancer::Template::Tenjin;

my $engine;

eval { $engine = Dancer::Template::Tenjin->new };
is($@, '', "Dancer::Template::Tenjin engine created");

$engine->{engine}->{path} = ['t'];

is($engine->render(path('t', '01-basic.tt'), {
	var1 => 1,
	var2 => 2,
	foo  => 'one',
	bar  => 'two',
	baz  => 'three'
}), 'this is var1="1" and var2=2' . "\n\nanother line\n\none two three\n", 'processed a template given as a file name');

is($engine->render(path('t', '01-encoding.tt')), "מי שלא שותה לא משתין\n");

is($engine->render(path('t', '01-encoding2.tt')), "<h1>«…»</h1>\n");

done_testing();
