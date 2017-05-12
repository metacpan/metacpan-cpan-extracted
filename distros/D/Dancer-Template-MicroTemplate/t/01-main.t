use strict;
use warnings;
use Test::More tests => 2;
use File::Spec::Functions qw(catfile);

use Dancer::Template::MicroTemplate;

ok(
    my $engine = Dancer::Template::MicroTemplate->new,
    "Dancer::Template::MicroTemplate engine created"
);

my $template = catfile(qw(t views 01-main.mt));
my $result   = $engine->render(
    $template, {
        var1 => 1,
        var2 => 2,
        foo  => 'one',
        bar  => 'two',
        baz  => 'three'
    }
);

my $expected
    = 'this is var1="1" and var2=2' . "\n\nanother line\n\none two three\n";
is $result, $expected, "processed a template given as a file name";
