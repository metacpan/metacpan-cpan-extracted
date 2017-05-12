use strict;
use Acme::Nogizaka46;
use Test::More qw(no_plan);

my $nogizaka  = Acme::Nogizaka46->new;
my @members = $nogizaka->members;

for my $member (@members) {
    ok $member,                           $member->name_en;
    ok $member->name_ja,                  '  name_ja()';
    ok $member->first_name_ja,            '  first_name_ja()';
    ok $member->family_name_ja,           '  family_name_ja()';
    ok $member->name_en,                  '  name_en()';
    ok $member->first_name_en,            '  first_name_en()';
    ok $member->family_name_en,           '  family_name_en()';
    ok ref($member->nick) eq 'ARRAY',     '  nick()';
    ok !$member->birthday || $member->birthday->isa('DateTime'), '  birthday()';
    ok $member->age,                      '  age()';
    ok $member->blood_type,               '  blood_type()';
    ok $member->hometown,                 '  hometown()';
    ok $member->class,                    '  class()';
    ok !$member->center || scalar($member->center) > 0, "  center()";
    ok !$member->graduate_date || $member->graduate_date->isa('DateTime'), '  graduate_date()';
}
