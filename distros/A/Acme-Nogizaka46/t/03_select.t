use strict;
use DateTime;
use Acme::Nogizaka46;
use Test::More tests => 1;

my $nogizaka  = Acme::Nogizaka46->new;

my @maimai = $nogizaka->select('family_name_en', 'Fukagawa', 'eq');
is @maimai[0]->name_en, 'Mai Fukagawa', "select('first_name_en')";

diag( $nogizaka->select('center', undef, 'ne'));
