#!perl
use strict;
use warnings;
use FindBin qw($Bin);
use Test::More tests => 2;

use Dancer::Template::Mason2;

my $engine;
eval { $engine = Dancer::Template::Mason2->new };
is $@, '', "Dancer::Template::Mason engine created";

my $template = join( "/", $Bin, 'views', 'index.mc' );
die "cannot find template" unless -f $template;
utime( time, time, $template );    # touch template so it will be recompiled

my $result = $engine->render(
    $template,
    {
        var1 => 1,
        var2 => 2,
        foo  => 'one',
        bar  => 'two',
        baz  => 'three'
    }
);

my $expected = 'this is var1="1" and var2=2' . "\n\nanother line\n\none two three\n";
is $result, $expected, "processed a template given as a file name";
