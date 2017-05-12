use strict;
use Test::More 0.98;
use Acme::BABYMETAL;

my $babymetal = new Acme::BABYMETAL;

is scalar $babymetal->members('YUIMETAL'), 1;
is scalar $babymetal->members('YUImetal'), 1;
is scalar $babymetal->members('yui'), 1;
is scalar $babymetal->members('Yui-chan Maji Yui-chan'), 1;

for my $member ($babymetal->members('YUIMETAL')) {
    is $member->metal_name, 'YUIMETAL';
    is $member->name_ja, '水野由結';
    is $member->first_name_ja, '由結';
    is $member->family_name_ja, '水野';
    is $member->name_en, 'Yui Mizuno';
    is $member->first_name_en, 'Yui';
    is $member->family_name_en, 'Mizuno';
    is $member->birthday, '1999-06-20';
    ok $member->age;
    is $member->blood_type, 'O';
    is $member->hometown, '神奈川県';
}


done_testing;

