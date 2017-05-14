use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my @members = Acme::PrettyCure->members('AllStar');

for my $member (@members) {
    is $member->name, $member->human_name;
    next if ref($member) =~ /Cure(Black|White|Bloom|Egret)/;
    $member->transform;
    is $member->name, $member->precure_name;
}

done_testing;

