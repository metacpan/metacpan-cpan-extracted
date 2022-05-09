# Deterministic random test

use strict;
use warnings;
use feature ':5.12';

use Test::More;
use Data::Gimei;

my ( @expected, @actual );

Data::Gimei::set_random_seed(42);
my $name = Data::Gimei::Name->new();
push @expected, $name->kanji;
my $address = Data::Gimei::Address->new();
push @expected, $address->kanji;

# Deteministic random returns same result
Data::Gimei::set_random_seed(42);
$name = Data::Gimei::Name->new();
push @actual, $name->kanji;
$address = Data::Gimei::Address->new();
push @actual, $address->kanji;
ok Test::More::eq_array( \@expected, \@actual );

# Deteministic random DOES NOT depend on calling rand()
@actual = ();
Data::Gimei::set_random_seed(42);
rand;
$name = Data::Gimei::Name->new();
push @actual, $name->kanji;
rand;
$address = Data::Gimei::Address->new();
push @actual, $address->kanji;
ok Test::More::eq_array( \@expected, \@actual );

done_testing();
