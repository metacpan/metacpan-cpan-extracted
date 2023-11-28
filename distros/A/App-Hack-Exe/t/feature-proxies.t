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

require App::Hack::Exe;

my $he = App::Hack::Exe->new(
    no_delay => 1,
    proxies => [qw/ MOO OOM /],
);

my ($errout) = capture_merged {
    # Close prompt immediately
    local *STDIN = gensym();
    $he->run('localhost');
};

like($errout, qr/MOO>OOM/,
    'proxies from constructor should be used'
);
