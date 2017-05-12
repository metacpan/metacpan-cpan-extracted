package UNIVERSAL;
use Attribute::Handlers::Prospective;
use Tie::RangeHash;

sub Ranged : ATTR(HASH) {
	my ($package, $symbol, $referent, $attr, $data) = @_;
	tie %$referent, 'Tie::RangeHash';
}

package main;

my %next : Ranged;

$next{'cat,dog'} = "animal";
$next{'fish,fowl'} = "meal";
$next{'heaven,hell'} = "reward";

while (<>) {
	chomp;
	print $next{$_}||"???", "\n";
}
