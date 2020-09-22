use v5.16;
use Test::More;
use Art::Wildlife;
use Art;
use Data::Printer;
use Faker;

use_ok 'Art::World';
my $aw = Art::World->new_playground;
ok $aw, 'The world is created';

my $art_abstraction = Art->new_abstract;
ok $art_abstraction->does('Art::Abstractions'), 'Art does role Abstractions';


done_testing;
