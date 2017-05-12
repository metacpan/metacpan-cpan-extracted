use strict;
use warnings;
use utf8;

use Test::Requires 'PerlIO::Util';
use Test::More;

use App::RunCron;
use Capture::Tiny qw/capture/;

subtest 'opt print' => sub {
    my $runner = App::RunCron->new(
        command   => [$^X, '-e', qq[print "Hello\n"]],
        print          => 1,
        reporter       => 'None',
        error_reporter => 'None',
    );
    my ($stdout, $stderr) = capture { $runner->_run };

    ok $stdout;
    like $stdout, qr/Hello/;

    is $runner->exit_code, 0;
};

done_testing;
