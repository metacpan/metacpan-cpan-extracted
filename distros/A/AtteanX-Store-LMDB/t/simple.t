use Test::More;
use Test::Modern;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';
use Attean;

use_ok('AtteanX::Store::LMDB');
my $class	= Attean->get_store('LMDB');
is($class, 'AtteanX::Store::LMDB');

done_testing();
