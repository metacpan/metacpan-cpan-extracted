package TestClass;
use Moose;
use Argon::Encryption;
with 'Argon::Encryption';
__PACKAGE__->meta->make_immutable;
1;

package main;
use Test2::Bundle::Extended;

my $payload = 'how now brown bureaucrat';

ok my $obj = TestClass->new(key => 'foo'), 'consumer';
ok my $data = $obj->encrypt($payload), 'encrypt';
is $obj->decrypt($data), $payload, 'decrypt';
isnt $data, $payload, 'encrypted';

my $other = TestClass->new(key => 'bar');
isnt $obj->encrypt($payload), $other->encrypt($payload), 'key incompatibility';

done_testing;
