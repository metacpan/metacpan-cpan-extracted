use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::plmetrics;

my $plm = App::plmetrics->new(+{
    '--git' => 'git://github.com/bayashi/Test-AllModules.git',
});

ok 1;

SKIP: {
    skip 'only author or travis-ci', 4
        if !$ENV{AUTHOR_TEST} || !$ENV{CI} || !$ENV{TRAVIS};

    my ($stdout, $stderr, @result) = capture {
        $plm->run;
    };
    like $stdout, qr!^lib/Test/AllModules.pm!;
    like $stdout, qr!avg.+max.+min.+range.+sum.+methods!;
    like $stdout, qr!\|\s+cc\s+\|\s+\d!;
    like $stdout, qr!\|\s+lines\s+\|\s+\d!;
    note($stdout) if $ENV{AUTHOR_TEST};
}

done_testing;
