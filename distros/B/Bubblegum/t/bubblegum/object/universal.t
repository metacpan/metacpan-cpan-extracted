use Bubblegum;
use Test::More;

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::Universal', 'instance';
can_ok 'Bubblegum::Object::Universal', 'wrapper';

isa_ok(''->wrapper('Digest'),  'Bubblegum::Wrapper::Digest');
isa_ok(''->wrapper('Dumper'),  'Bubblegum::Wrapper::Dumper');
isa_ok(''->wrapper('Encoder'), 'Bubblegum::Wrapper::Encoder');
isa_ok(''->wrapper('Json'),    'Bubblegum::Wrapper::Json');
isa_ok(''->wrapper('Yaml'),    'Bubblegum::Wrapper::Yaml');

my $string = '';
ok $string->isa_string;

done_testing;
