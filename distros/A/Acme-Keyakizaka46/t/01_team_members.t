use strict;
use DateTime;
use Acme::Keyakizaka46;
use Test::More tests => 3;

my $keyaki = Acme::Keyakizaka46->new;

is scalar($keyaki->team_members),             41, " ALL KEYAKI MEMBERS";
is scalar($keyaki->team_members('kanji')),    21, " KANJI KEYAKI MEMBERS";
is scalar($keyaki->team_members('hiragana')), 20, " HIRAGANA KEYAKI MEMBERS";
