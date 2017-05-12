use strict;
use warnings;
use utf8;

use Test::More;
use Test::File::ShareDir::Dist { 'DateTime-Locale' => 'share' };

use DateTime::Locale;

my %tests = (
    'bs-Latn' => {
        name        => 'Bosnian Latin',
        script      => 'Latin',
        script_code => 'Latn',
    },
    'zh-Hans-SG' => {
        script         => 'Simplified',
        native_script  => '简体',
        script_code    => 'Hans',
        territory_code => 'SG',
    },
);

for my $code ( sort keys %tests ) {
    subtest(
        $code,
        sub {
            my $loc = DateTime::Locale->load($code);
            for my $meth ( sort keys %{ $tests{$code} } ) {
                is( $loc->$meth, $tests{$code}{$meth}, "$meth" );
            }
        }
    );
}

done_testing();
