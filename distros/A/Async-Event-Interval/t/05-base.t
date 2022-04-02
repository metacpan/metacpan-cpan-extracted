use strict;
use warnings;

use Data::Dumper;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

my $file = 't/test.data';

my $e = $mod->new(0.2, \&perform, 10);

$e->start;

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

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();
