
BEGIN{ require "t/lib/t.pl"; &init; }
use Test::More tests => 2;
use t::object;


my $cons = t::object->new;
$cons->extend->extend->extend->extend->extend->extend->extend->extend;

my $b = Data::Rebuilder->new;
my $cons1 = $b->_t($cons);
is( $cons1->length, $cons->length );

$b->parameterize( third => $cons->cdr->cdr );
my $cons2 = $b->_t( $cons , third => t::object->new );
is( $cons2->length, 3 );
