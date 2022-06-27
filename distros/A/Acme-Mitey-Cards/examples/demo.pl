use strict;
use warnings;

use Acme::Mitey::Cards;

my $deck = Acme::Mitey::Cards::Deck->new->shuffle;
my $hand = $deck->deal_hand( owner => 'Bob' );
print $hand->to_string, "\n";
