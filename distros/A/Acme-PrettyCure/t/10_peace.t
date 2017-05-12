use strict;
use warnings;
use utf8;
use Test::More;

use Acme::PrettyCure::Girl::CurePeace;

my $yayoi = Acme::PrettyCure::Girl::CurePeace->new;

subtest 'random mode' => sub {
    for ( 1 ..100 ) {
        like $yayoi->challenge_with_jankenpon, qr/じゃんけんぽん（(グー|チョキ|パー)）♪ /;
    }
};

subtest 'story mode' => sub {
    unlike $yayoi->challenge_with_jankenpon(1), qr/じゃんけんぽん（(グー|チョキ|パー)）♪ /;
    like $yayoi->challenge_with_jankenpon(3), qr/じゃんけんぽん（チョキ）♪ /;
    like $yayoi->challenge_with_jankenpon(11), qr/じゃんけんぽん（グー）♪ /;
    like $yayoi->challenge_with_jankenpon(17), qr/じゃんけんぽん（パー）♪ /;
    unlike $yayoi->challenge_with_jankenpon(32), qr/じゃんけんぽん（(グー|チョキ|パー)）♪ /;
};

done_testing;
