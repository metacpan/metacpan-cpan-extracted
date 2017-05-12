use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::plmetrics;

my $plm = App::plmetrics->new(+{
    '--dir'    => '.',
    '--result' => 'files',
});

{
    my ($stdout, $stderr, @result) = capture {
        $plm->run;
    };
    like $stdout, qr!^files!;
    like $stdout, qr!\|\s+file\s+\|\s+lines\s+\|\s+methods\s+\|\s+packages\s+\|!;
    note($stdout) if $ENV{AUTHOR_TEST};
}

done_testing;
