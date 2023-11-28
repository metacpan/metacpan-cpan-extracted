#!perl
use 5.012;
use warnings FATAL => 'all';

use Test::More;

unless (eval {
    require Capture::Tiny;
}) {
    plan(skip_all => 'Capture::Tiny is not installed.');
}
plan('no_plan');
use Capture::Tiny 'capture_merged';
use Symbol qw/ gensym /;

# Control for this env being set
local $ENV{NO_COLOR};

require App::Hack::Exe;

my $he = App::Hack::Exe->new(no_delay => 1);

my ($errout) = capture_merged {
    # Close prompt immediately
    local *STDIN = gensym();
    $he->run('localhost');
};
like($errout, qr/^\e\[31m/,
    q{Demon should be colorized red}
);
like($errout, qr/\e\[33mDIE\e\[31m/,
    q{Demon's eyes should be colored yellow}
);
like($errout, qr/\e\[33mHUMAN\e\[31m/,
    q{Demon's eyes should be colored yellow}
);
