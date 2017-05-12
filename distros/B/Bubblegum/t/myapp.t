BEGIN {
    use FindBin;
    use lib $FindBin::Bin . '/myapp/lib';
}

use MyApp::Core;
use Test::More;

ok ! main->isa('Moo::Object'), 'class not an object';

isa_ok 'a'->digest,  'Bubblegum::Wrapper::Digest',  'digest invoked';
isa_ok [1]->dumper,  'Bubblegum::Wrapper::Dumper',  'dumper invoked';
isa_ok 'a'->encoder, 'Bubblegum::Wrapper::Encoder', 'encoder invoked';
isa_ok [1]->json,    'Bubblegum::Wrapper::Json',    'json invoked';
isa_ok [1]->yaml,    'Bubblegum::Wrapper::Yaml',    'yaml invoked';

my $string = "foo bar baz";
is_deeply $string->words, ["foo", "bar", "baz"];
is $string->proper, 5678;

done_testing;
