use Benchmark;
use ClearCase::Argv;

use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;

ClearCase::Argv->attropts;

# Alert the user if a trigger may be skewing the benchmark.
$ENV{CLEARCASE_TRACE_TRIGGERS} = 1;

sub readops {
    my @elems = @_;
    my $style = ClearCase::Argv->exec_style;
    my $t1 = new Benchmark;
    my $ct = ClearCase::Argv->new;
    $ct->stdout(0);
    for my $elem (@elems) {
	$ct->desc($elem)->system;
	$ct->ls($elem)->system;
	$ct->lsvt($elem)->system;
    }
    printf "%-6s: %s\n", $style, timestr(timediff(new Benchmark, $t1), 'noc');
}

my @elems = grep { ! -l } map { MSWIN ? glob : $_ } @ARGV;

printf "Benchmarking reads with %d elements ...\n", scalar(@elems);

ClearCase::Argv->fork_exec(2);
readops(@elems);

ClearCase::Argv->ctcmd(2);
readops(@elems);

# Benchmark IPC::ClearTool mode - turned off by default.
#ClearCase::Argv->ipc(2);
#readops(@elems);
