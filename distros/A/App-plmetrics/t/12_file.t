use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::plmetrics;

my $plm = App::plmetrics->new(+{
    '--file' => 'lib/App/plmetrics.pm',
});

{
    my ($stdout, $stderr, @result) = capture {
        $plm->run;
    };
    like $stdout, qr!^lib/App/plmetrics.pm!;
    like $stdout, qr!avg.+max.+min.+range.+sum.+methods!;
    like $stdout, qr!\|\s+cc\s+\|\s+\d!;
    like $stdout, qr!\|\s+lines\s+\|\s+\d!;
    note($stdout) if $ENV{AUTHOR_TEST};
}

done_testing;
