use Test::More tests => 3;

use strict;
use warnings;

use Dancer qw(:tests);
use Dancer::Plugin::Passphrase;

my $with_defaults   = passphrase->generate_random;
my $extra_length    = passphrase->generate_random({ length => 32 });
my $scouse_password = passphrase->generate_random({ charset => ['a'], length => 3 });


ok($with_defaults,             "Basic password generation");
ok(length $extra_length eq 32, "Custom password length");
ok($scouse_password eq 'aaa',  "Custom chracter set");
