use strict;
use warnings;

use lib 't/apps/Foo/lib';

use FindBin qw($Bin);
use Test::More tests => 3;

use Dancer::Template::TemplateDeclare;

my $engine;
eval { $engine = Dancer::Template::TemplateDeclare->new( 
    dispatch_to => [ 'TD' ],
) };
is $@, '', "Dancer::Template::TemplateDeclare engine created";

$engine->init(
    dispatch_to => [ 'TD' ],
);

my $result = $engine->render(
    'simple',
);

is $result, "\n<h1>hi there</h1>", 'simple';

$result = $engine->render(
    'with_vars' => {
        name => 'Bob',
    },
);

is $result, "\n<h1>hi Bob</h1>", "with vars";
