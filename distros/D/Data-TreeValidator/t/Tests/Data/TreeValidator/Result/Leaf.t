use strict;
use warnings;
use Test::More;
use Test::Routine;
use Test::Routine::Util;

use aliased 'Data::TreeValidator::Result::Leaf' => 'Result';

test 'public api' => sub {
    my $result = Result->new(input => {});
    can_ok($result, $_)
        for qw(
            valid
            clean
        );
};

test 'validity' => sub {
    my $valid_result = Result->new( clean => 'Clean', input => 'leaf' );
    my $invalid_result = Result->new( input => 'leaf' );

    ok($valid_result->valid, 'results with clean data are valid');
    ok(!$invalid_result->valid, 'result without clean data are invalid');
};

run_me;
done_testing;
