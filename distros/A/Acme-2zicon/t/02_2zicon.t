use strict;
use Acme::2zicon;
use Test::More qw(no_plan);

my $nizicon  = Acme::2zicon->new;
my @members = $nizicon->members;

for my $member (@members) {
    ok $member,                           $member->name_en;
    ok $member->name_ja,                  '  name_ja()';
    ok $member->first_name_ja,            '  first_name_ja()';
    ok $member->family_name_ja,           '  family_name_ja()';
    ok $member->name_en,                  '  name_en()';
    ok $member->first_name_en,            '  name_en()';
    ok $member->family_name_en,           '  family_name_en()';
    ok ref($member->nick) eq 'ARRAY',     '  nick()';
    ok !$member->birthday || $member->birthday->isa('DateTime'), '  birthday()';
    ok $member->age,                      '  age()';
    ok $member->blood_type,               '  blood_type()';
    ok $member->hometown,                 '  hometown()';
    # ok $member->introduction,             '  introduction()';
    ok $member->twitter,                  '  twitter()';
}
