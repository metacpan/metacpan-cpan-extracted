use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::plmetrics;

{
    my $plm = App::plmetrics->new(+{
        '--module' => 'Test::More',
    });
    my ($stdout, $stderr, @result) = capture {
        $plm->run;
    };
    like $stdout, qr!Test/More.pm!;
    like $stdout, qr!avg.+max.+min.+range.+sum.+methods!;
    like $stdout, qr!\|\s+cc\s+\|\s+\d!;
    like $stdout, qr!\|\s+lines\s+\|\s+\d!;
    note($stdout) if $ENV{AUTHOR_TEST};
}

{
    my $plm = App::plmetrics->new(+{
        '--module' => 'This::Is::No::Exists::Module',
    });
    my ($stdout, $stderr, @result) = capture {
        $plm->run;
    };
    like $stderr, qr!^No such module: This::Is::No::Exists::Module!;
    note($stderr) if $ENV{AUTHOR_TEST};
}

done_testing;
