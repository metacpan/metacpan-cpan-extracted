use strict;
use DateTime;
use Acme::Keyakizaka46;
use Test::More tests => 2;

my $keyaki  = Acme::Keyakizaka46->new;

my @neru = $keyaki->select('family_name_en', 'Nagahama', 'eq');
is $neru[0]->name_en, 'Neru Nagahama', "ねるを検索";

my @ab = $keyaki->select('blood_type', 'AB', 'eq');
is scalar @ab, 5, "AB型のメンバーは5人";

diag( $keyaki->select('center') ); # センター経験者はてちのみ
