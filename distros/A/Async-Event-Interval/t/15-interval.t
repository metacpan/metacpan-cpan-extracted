use strict;
use warnings;

use Async::Event::Interval;
use Time::HiRes qw(usleep);
use Test::More;

my $mod = 'Async::Event::Interval';

my $file = 't/test.data';

my $x = 0;
is $x, 0, "baselline var ok";

my $e = $mod->new(1, \&perform, $x);
$e->start;

sleep 2;
my $data = data();
ok $data > 0 && $data < 30, "event is async and correct";

sleep 2;
$e->stop;
$data = data();
ok $data >= 30, "event is async, and is correct again";

sub perform {
    $x += 10;
    open my $wfh, '>', $file or die $!;
    print $wfh $x;
    close $wfh;
}
sub data {
    my $data;
    {
        local $/;
        open my $fh, '<', $file or die $!;
        $data = <$fh>;
    }
    return $data;
}

unlink $file or die $!;
is -e $file, undef, "temp file removed ok";

done_testing();
