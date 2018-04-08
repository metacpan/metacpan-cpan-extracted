use strict;
use Acme::Keyakizaka46;
use Test::More qw(no_plan);

my $keyaki = Acme::Keyakizaka46->new;
my @members = $keyaki->team_members;

for my $member (@members) {
    ok $member,                                         $member->name_en;
    ok $member->first_name_en,                          '  first_name_en()';
    ok $member->family_name_en,                         '  family_name_en()';
    ok $member->name_en,                                '  name_en()';
    ok $member->first_name_ja,                          '  first_name_ja()';
    ok $member->family_name_ja,                         '  family_name_ja()';
    ok $member->name_ja,                                '  name_ja()';
    ok $member->birthday->isa('DateTime'),              '  birthday()';
    ok $member->age 
        && $member->age =~ /\d{2}/,                     '  age()';
    ok $member->zodiac_sign,                            '  zodiac_sign()';
    ok $member->height 
        && $member->height =~ /\d{3}/,                  '  height()';
    ok $member->hometown,                               '  hometown()';
    ok $member->blood_type,                             '  blood_type()';
    ok $member->team,                                   '  team()';
    ok $member->class,                                  '  class()';
    ok !$member->center || scalar($member->center) > 0, '  center()';
}
