use strict;
use warnings;
use Test::More;

use Scalar::Util qw(blessed refaddr);

use_ok 'Data::Object::Singleton';

ok my $object = main->new;
ok blessed $object;

my $addr1 = refaddr($object);
my $addr2 = refaddr(main->new);
my $addr3 = refaddr(main->renew);
my $addr4 = refaddr(main->new);

is   $addr1, $addr2;
isnt $addr2, $addr3;
is   $addr3, $addr4;
is   $addr1, $addr2;

ok   $addr2;
ok   $addr1;

ok 1 and done_testing;
