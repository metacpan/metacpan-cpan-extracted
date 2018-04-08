use strict;
use DateTime;
use Acme::Keyakizaka46;
use Test::More tests => 2;

my $keyaki  = Acme::Keyakizaka46->new;

my @sorted_by_height = $keyaki->sort('height', 'desc');
is $sorted_by_height[0]->name_en, 'Mizuho Habu', "一番高身長";

my @sorted_by_birthday = $keyaki->sort('birthday', 'asc');
is $sorted_by_birthday[0]->name_en, 'Rika Watanabe', "最年長";
# ageでソートすると同い年だと順番がうまく考慮されない