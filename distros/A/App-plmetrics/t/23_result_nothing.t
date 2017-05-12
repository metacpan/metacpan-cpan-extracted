use strict;
use warnings;
use Test::More;
use Capture::Tiny qw/capture/;

use App::plmetrics;

my $plm = App::plmetrics->new(+{
    '--module' => 'Test::More',
    '--result' => 'this_is_wrong_result_label',
});

{
    my ($stdout, $stderr, @result) = capture {
        $plm->run;
    };
    like $stderr, qr!^wrong option: --result this_is_wrong_result_label!;
}

done_testing;
