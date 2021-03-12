use strict;
use warnings;
use FindBin qw($Bin);
use Test::More tests => 3;

use Dancer2::Template::Handlebars;

my $engine = eval { Dancer2::Template::Handlebars->new() };
is $@, q//, 'Dancer2::Template::Handlebars engine created';

my $result = $engine->render( 't/views/basic.hbs', { style => 'handlebar' } );

like $result => qr/welcome to Dancer2::Template::Handlebars/, 'template read';
like $result => qr/mustache style: handlebar/, 'variable interpolated';

