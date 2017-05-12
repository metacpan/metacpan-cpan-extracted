use strict;
use warnings;
use Test::More tests => 2;
use File::Spec::Functions qw(catfile);

use Dancer::Template::Xslate;

ok(
    my $engine = Dancer::Template::Xslate->new,
    "Dancer::Template::Xslate engine created"
);
my $template = catfile(qw(t views index.xslate));
my $result = $engine->render(
    $template,
    {   var1 => 1,
        var2 => 2,
        foo  => "one",
        bar  => "two",
        baz  => "three"
    }
);

my $expected =
    qq(this is var1="1" and var2=2\n\nanother line\n\none two three\n);
is $result, $expected, "processed a template given as a file name";
