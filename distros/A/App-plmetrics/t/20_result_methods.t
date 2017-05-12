use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::plmetrics;

my $plm = App::plmetrics->new(+{
    '--module' => 'Test::More',
    '--result' => 'methods',
});

{
    my ($stdout, $stderr, @result) = capture {
        $plm->run;
    };
    like $stdout, qr!\|\s+\|\s+cc\s+\|\s+lines\s+\|!;
    note($stdout) if $ENV{AUTHOR_TEST};
}

done_testing;
