use strict;
use warnings;

use Test::More tests => 2;

use File::Spec;

use_ok('Dancer::Template::Caml');

my $engine = Dancer::Template::Caml->new;

my $template = File::Spec->catfile('t', 'index.caml');

my $result = $engine->render($template, {name => 'vti'});

is $result, 'Hello vti!';
