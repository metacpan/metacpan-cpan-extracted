use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure;

my @girls = Acme::PrettyCure->girls('AllStar');

my $output;
open my $OUT, '>', \$output;
local *STDOUT = $OUT;

# The girls who cannot transform without their buddy (CureBlack and CureWhite also match their
# MaxHeart versions). They are checked to die alone, so that the list follows the code (#7).
my $needs_buddy = qr/::Cure(?:Black|White|Bloom|Egret|Melody|Rhythm)(?:MH)?\z/;

for my $member (@girls) {
    is $member->name, $member->human_name;
    if (ref($member) =~ $needs_buddy) {
        ok !eval { $member->transform; 1 }, ref($member) . ' cannot transform alone';
        ok !$member->is_precure, ref($member) . ' is not transformed';
        next;
    }
    $member->transform;
    is $member->name, $member->precure_name;
}

close($OUT);

done_testing;
