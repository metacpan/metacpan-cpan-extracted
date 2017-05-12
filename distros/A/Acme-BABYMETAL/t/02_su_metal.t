use strict;
use Test::More 0.98;
use Acme::BABYMETAL;

my $babymetal = new Acme::BABYMETAL;

is scalar $babymetal->members('SU-METAL'), 1;
is scalar $babymetal->members('su-metal'), 1;
is scalar $babymetal->members('su'), 1;

for my $member ($babymetal->members('SU-METAL')) {
    is $member->metal_name, 'SU-METAL';
    is $member->name_ja, '中元すず香';
    is $member->first_name_ja, 'すず香';
    is $member->family_name_ja, '中元';
    is $member->name_en, 'Suzuka Nakamoto';
    is $member->first_name_en, 'Suzuka';
    is $member->family_name_en, 'Nakamoto';
    is $member->birthday, '1997-12-20';
    ok $member->age;
    is $member->blood_type, 'B';
    is $member->hometown, '広島県';
}


done_testing;

