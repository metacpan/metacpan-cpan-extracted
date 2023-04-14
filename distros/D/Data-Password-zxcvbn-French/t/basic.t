use Test2::V0;
use Data::Password::zxcvbn::French qw(password_strength);

sub test_one {
    my ($string, $expected_score) = @_;

    is(
        password_strength(
            $string,
        ),
        hash {
            field score => $expected_score;
            etc;
        },
        "$string should be a $expected_score",
    );
}

test_one('abandonner',1);
test_one('aZerTy',1);
test_one('marie',0);
test_one('dupont',0);
test_one('89475tnuihthnb',4);

done_testing;
