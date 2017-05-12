use strict;
use warnings;

use Test::More;

BEGIN {
    plan( skip_all => 'this test is for windows only' ) if $^O ne 'MSWin32';
};

use Continual::Process;
use Continual::Process::Helper qw(prepare_fork prepare_run);
use Continual::Process::Loop::Simple;
use Win32::Process;
use File::Temp;

$ENV{C_P_DEBUG} = 1;

my $tick = 2;
my $tmp = File::Temp->new();
close $tmp;
my $loop = Continual::Process::Loop::Simple->new(
    instances => [
        Continual::Process->new(
            name => 'job1',
            code => prepare_fork(sub {
                my ($instance) = @_;

                open my $t, '>>', $tmp;
                print $t $instance->id . "\n";
                close $t;
            }),
            instances => 4,
        )->create_instance(),
        Continual::Process->new(
            name => 'job2',
            code => prepare_run($^X, qq{-E "open my \$file, '>>', '$tmp'; say \$file \"\$ENV{C_P_INSTANCE_ID}\n\"; close \$file; while(1) {sleep 1}"}),
        )->create_instance(),
    ],
    tick => sub { $tick-- }
);

$loop->run();

done_testing(1);

runs_check($tmp, { 
        'job2.1' => 1,
        'job1.1' => 2,
        'job1.2' => 2,
        'job1.3' => 2,
        'job1.4' => 2,
    });

sub runs_check {
    my ($tmp, $expected) = @_;

    open my $file, '<', $tmp;
    my @rows = <$file>;
    close $file;

    my %histo;
    foreach my $row (@rows) {
        chomp $row;
        $histo{$row}++;
    }

    is_deeply(\%histo, $expected, 'runs check');
}
