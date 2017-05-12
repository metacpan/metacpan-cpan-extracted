use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::plmetrics;

my $plm = App::plmetrics->new(+{
    '--module' => 'Test::More',
    '--result' => 'cc',
});

{
    my ($stdout, $stderr, @result) = capture {
        $plm->run;
    };
    like $stdout, qr!^cc!;
    like $stdout, qr!Test/More.pm!;
    like $stdout, qr!avg.+max.+min.+range.+sum.+methods!;
    note($stdout) if $ENV{AUTHOR_TEST};
}

done_testing;
