use strict;
use Acme::MomoiroClover::Z;
use Test::More qw(no_plan);

my $momoclo_chan = Acme::MomoiroClover::Z->new;
my @members = $momoclo_chan->members;

for my $member (@members) {
    ok $member,                           $member->name_en;
    ok $member->name_ja,                  '  name_ja()';
    ok $member->first_name_ja,            '  first_name_ja()';
    ok $member->family_name_ja,           '  family_name_ja()';
    ok $member->name_en,                  '  name_en()';
    ok $member->first_name_en,            '  name_en()';
    ok $member->family_name_en,           '  family_name_en()';
    ok ref($member->nick) eq 'ARRAY',     '  nick()';
    ok !$member->birthday || $member->birthday->isa('Date::Simple'), '  birthday()';
    ok $member->age,                      '  age()';
    ok $member->blood_type,               '  blood_type()';
    ok $member->hometown,                 '  hometown()';
    ok ref($member->emoticon) eq 'ARRAY', '  emoticon()';
    ok !$member->graduate_date || $member->graduate_date->isa('Date::Simple'), '  join_daate()';
    ok $member->join_date->isa('Date::Simple'), '  join_date()';
    ok $member->can('color'),             '  color()';
    ok $member->say(''),                  '  say()';
}
