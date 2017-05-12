use strict;
use warnings;
use Test::More;
use Test::Output;

BEGIN {
    use_ok('AlignDB::Run');
}

my $jobs = [ 'a' .. 'z' ];
my $code = sub {
    my $task = shift;

    print $task, "\n";

    return;
};

my $run = AlignDB::Run->new(
    parallel => 4,
    jobs     => $jobs,
    code     => $code,
);

stdout_like(
    sub {$run->run},
    qr{===Do task 26 out of 26===},
    "Outputs"
);

is( scalar @$jobs, 0, "There should be no task lefted" );

done_testing();
