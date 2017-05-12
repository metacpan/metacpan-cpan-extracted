
# There is not much we can test without an account so most of the tests are in ../scripts/userTest.pl

use lib '../lib';
use Test::More tests => 8;
use Exception::Class;

BEGIN { use_ok( 'DNS::WorldWideDns' ); }

my $dns = DNS::WorldWideDns->new ('Andy','Dufresne');
isa_ok ($dns, 'DNS::WorldWideDns');

is($dns->username, 'Andy', 'username() works');
is($dns->password, 'Dufresne', 'password() works');

my $borked = eval { DNS::WorldWideDns->new('Red')};
ok(Exception::Class->caught('MissingParam'), 'Expecting a missing param exception on password.');
$borked = eval { DNS::WorldWideDns->new()};
ok(Exception::Class->caught('MissingParam'), 'Expecting a missing param exception on username.');

my $domains = eval{$dns->getDomains};
my $e;
ok($e = Exception::Class->caught('RequestError'), 'Expecting an invalid account exception on request.');
my $code = $e->code;
SKIP: {
    skip("Need a network connection.", 1) unless defined $code;
    is($code, '403', 'Expecting a 403 error code.');
}


