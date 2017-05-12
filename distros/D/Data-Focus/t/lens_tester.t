use strict;
use warnings FATAL => "all";

use Test::More;
use Data::Focus::LensTester;
use Data::Focus::Lens::HashArray::Index;

my $tester = Data::Focus::LensTester->new(
    test_whole => sub { is_deeply($_[0], $_[1]) },
    test_part  => sub { is($_[0], $_[1]) },
    parts => [undef, 1, "str"]
);

my $create_target = sub {
    +{ foo => "bar" }
};

my $lens = Data::Focus::Lens::HashArray::Index->new(
    index => "foo"
);

$tester->test_lens_laws(
    lens => $lens, target => $create_target,
    exp_focal_points => 1,
);

done_testing;

