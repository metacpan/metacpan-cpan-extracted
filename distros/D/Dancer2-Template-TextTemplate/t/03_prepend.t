use Test::More tests => 2;
use Test::Fatal;
use Dancer2::Template::TextTemplate::FakeEngine;

my $template = <<'TEMPLATE_END';
1 { $n / 4 } 3
TEMPLATE_END

my $expected = <<'EXPECTED_END';
1 2 3
EXPECTED_END

my $e = Dancer2::Template::TextTemplate::FakeEngine->new;

# This is supposed to be the default, but enforce strictures just to be sure:
$e->prepend(<<'STRICTURES_END');
use strict;
use warnings FATAL => 'all';
STRICTURES_END

is(
    $e->process(\$template, { n => 8 }),
    $expected,
    'arguments produce defined variables in templates'
);

like(
    $e->process(\$template ), # no args provided here
    qr/Program fragment delivered error ``.*?\$n\b/,
    'missing arguments produce warnings in template output'
);

1;
