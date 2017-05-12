use strict;
use Test::More 0.98;
use Acme::BABYMETAL;

my $babymetal = new Acme::BABYMETAL;

is scalar $babymetal->members('MOAMETAL'), 1;
is scalar $babymetal->members('moametal'), 1;
is scalar $babymetal->members('moa'), 1;

for my $member ($babymetal->members('MOAMETAL')) {
    is $member->metal_name, 'MOAMETAL';
    is $member->name_ja, '菊地最愛';
    is $member->first_name_ja, '最愛';
    is $member->family_name_ja, '菊地';
    is $member->name_en, 'Moa Kikuchi';
    is $member->first_name_en, 'Moa';
    is $member->family_name_en, 'Kikuchi';
    is $member->birthday, '1999-07-04';
    ok $member->age;
    is $member->blood_type, 'A';
    is $member->hometown, '愛知県';
}


done_testing;

