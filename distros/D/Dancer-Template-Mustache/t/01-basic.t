use strict;
use warnings;
use FindBin qw($Bin);
use Test::More tests => 3;

use Dancer::FileUtils 'path';
use Dancer::Template::Mustache;

my $engine;
eval { $engine = Dancer::Template::Mustache->new };
is $@, '', "Dancer::Template::Mustache engine created";

my $result = $engine->render(
    'basic.mustache',
    { style => 'handlebar' }
);

like $result => qr/welcome to Dancer::Template::Mustache/, "template read";
like $result => qr/mustache style: handlebar/, "variable interpolated";

