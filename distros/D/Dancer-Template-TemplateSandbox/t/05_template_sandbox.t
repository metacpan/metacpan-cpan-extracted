use Test::More;

#  Lifted from Dancer's test-suite: 05_template_toolkit.t.

use strict;
use warnings;
use Dancer::ModuleLoader;
use Dancer::FileUtils 'path';

use lib 't/lib';
use EasyMocker;

BEGIN { 
    plan skip_all => "need Template::Sandbox to run this test" 
        unless Dancer::ModuleLoader->load('Template::Sandbox');
    plan tests => 6;
    use_ok 'Dancer::Template::TemplateSandbox';
};

my $mock = { 'TemplateSandbox' => 0 };
mock 'Dancer::ModuleLoader'
    => method 'load'
    => should sub { $mock->{ $_[1] } };

my $engine;
eval { $engine = Dancer::Template::TemplateSandbox->new };
like $@, qr/Template::Sandbox is needed by Dancer::Template::TemplateSandbox/, 
    "Template::Sandbox dependency caught at init time";

$mock->{ 'Template::Sandbox' } = 1;
eval { $engine = Dancer::Template::TemplateSandbox->new };
is $@, '', 
    "Template::Sandbox dependency is not triggered if Template::Sandbox is there";

my $template = path('t', 'index.txt');
my $result = $engine->render(
    $template, 
    { var1 => 1, 
      var2 => 2,
      foo => 'one',
      bar => 'two',
      baz => 'three'});

my $expected = 'this is var1="1" and var2=2'."\n\nanother line\n\n one two three\n";
is $result, $expected, "processed a template given as a file name";

$expected = "one=1, two=2, three=3";
$template = "one=<% one %>, two=<% two %>, three=<% three %>";

eval { $engine->render($template, { one => 1, two => 2, three => 3}) };
like $@, qr/is not a regular file/, "prorotype failure detected";

$result = $engine->render(\$template, { one => 1, two => 2, three => 3});
is $result, $expected, "processed a template given as a scalar ref";

#  TODO: figure out how to fake dancer's settings, to test caching behaviour.
