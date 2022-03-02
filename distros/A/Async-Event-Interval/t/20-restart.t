use strict;
use warnings;

use Async::Event::Interval;
use Time::HiRes qw(usleep);
use Test::More;

my $mod = 'Async::Event::Interval';

my $file = 't/test.data';

my $e = $mod->new(0.2, \&perform, 10);

$e->restart;

is -e $file, undef, "event is asynchronious";

sleep 2;

$e->stop;

my $data;
{
    local $/;
    open my $fh, '<', $file or die $!;
    $data = <$fh>;
}

is $data, 10, "single event does the right thing";

sub perform {
    my $arg = shift;
    sleep 1;
    open my $wfh, '>', $file or die $!;
    print $wfh $arg;
    close $wfh;
}

unlink $file or die $!;
is -e $file, undef, "temp file removed ok";

done_testing();
