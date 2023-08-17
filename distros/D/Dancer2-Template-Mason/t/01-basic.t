use strict;
use warnings;
use FindBin qw($Bin);
use Test2::V0;

use Dancer2::FileUtils 'path';
use Dancer2::Template::Mason;

plan 2;

my $engine;
eval { $engine = Dancer2::Template::Mason->new };
is $@, '', "Dancer2::Template::Mason engine created";

my $template = path($Bin, 'views', 'index');
my $result = $engine->render(
    $template,
    {   var1 => 1,
        var2 => 2,
        foo  => 'one',
        bar  => 'two',
        baz  => 'three'
    }
);

my $expected =
  'this is var1="1" and var2=2' . "\n\nanother line\n\none two three\n";
is $result, $expected, "processed a template given as a file name";
