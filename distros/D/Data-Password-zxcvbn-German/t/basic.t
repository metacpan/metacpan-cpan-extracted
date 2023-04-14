use Test2::V0;
use Data::Password::zxcvbn::German qw(password_strength);

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

test_one('Herbert',0);
test_one('!"34%&',1);
test_one('fggthduie678uiht',4);

done_testing;
