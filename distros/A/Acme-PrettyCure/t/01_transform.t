use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my @girls = Acme::PrettyCure->girls('AllStar');

my $output;
open my $OUT, '>', \$output;
local *STDOUT = $OUT;

for my $member (@girls) {
    is $member->name, $member->human_name;
    next if ref($member) =~ /Cure(Black|White|Bloom|Egret|Melody|Rhythm)/;
    $member->transform;
    is $member->name, $member->precure_name;
}

close($OUT);

done_testing;

