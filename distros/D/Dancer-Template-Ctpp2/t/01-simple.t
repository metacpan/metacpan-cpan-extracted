use strict;
use warnings;
use Test::More tests => 2;
use Dancer::FileUtils 'path';

use Dancer::Template::Ctpp2;

my $engine;
eval { $engine = Dancer::Template::Ctpp2->new };
is $@, '',
  "Dancer::Template::Ctpp2 template engine created";

my $template = path('t', 'index.tmpl');
my $result = $engine->render(
    $template,
    {   var1 => 'bar',
        array  => [0,1,2,3,4],
    }
);

my $expected =
  "this is foo=\"bar\"\n\nnew line\n\n01234\n";
is $result, $expected, "processed a template given as a file name";
