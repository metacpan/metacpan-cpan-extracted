use strict;
use warnings;
use FindBin qw($Bin);
use Test::More tests => 3;

use Dancer2::Template::Mustache;

my $engine = eval { Dancer2::Template::Mustache->new };
is $@, '', "Dancer2::Template::Mustache engine created";

my $result = $engine->render(
    'basic.mustache',
    { style => 'handlebar' }
);

like $result => qr/welcome to Dancer2::Template::Mustache/, "template read";
like $result => qr/mustache style: handlebar/, "variable interpolated";

