use Test::More;

BEGIN {
    use_ok('Akamai::Open::DiagnosticTools');
    use_ok('Akamai::Open::Client');
}
require_ok('Akamai::Open::DiagnosticTools');
require_ok('Akamai::Open::Client');

# object tests
my $client = new_ok('Akamai::Open::Client');
my $tool   = new_ok('Akamai::Open::DiagnosticTools');

# subobject tests
isa_ok($tool->debug, 'Akamai::Open::Debug');

# functional tests
ok($tool->client($client),    'setting client');

done_testing;
