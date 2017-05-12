use strict;
use warnings;

use Test::More 0.88;
use Test::Exception;

use Dancer 1.1801 ':syntax';
use Dancer::FileUtils 'path';
use Dancer::Template::Alloy;

my $engine;
lives_ok { $engine = Dancer::Template::Alloy->new }
    "creating a new instance of the template engine worked";
isa_ok $engine, 'Dancer::Template::Alloy';

# Now, trial rendering the template and make sure that works too.
my $template = path('t', 'basic.tt');
-f $template or BAIL_OUT("template '${template}' not found!");

my $result;
lives_ok {
    $result = $engine->render($template, {
        one => 1, two => 2
    })
} "rendering the trial template works";

like $result, qr/This is line one, value of two is '2'/,
    "We found the first output we expected in the template.";

like $result, qr/This is line two, value of one is '1'/,
    "We found the second output we expected in the template.";

done_testing;
