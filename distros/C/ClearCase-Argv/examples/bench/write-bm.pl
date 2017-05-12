use Benchmark;
use ClearCase::Argv;

use constant MSWIN => $^O =~ /MSWin32|Windows_NT/i ? 1 : 0;

ClearCase::Argv->attropts;

# Alert the user if a trigger may be skewing the benchmark.
$ENV{CLEARCASE_TRACE_TRIGGERS} = 1;

sub writeops {
    my @elems = @_;
    my $style = ClearCase::Argv->exec_style;
    my $t1 = new Benchmark;
    my $ct = ClearCase::Argv->new;
    $ct->stdout(0);
    for (@elems) {
	my $elem = "$_.$style";
	if (open(VP, ">$elem")) {
	    print VP scalar(localtime), "\n";
	    close(VP);
	} else {
	    warn "$0: $elem: $!";
	    next;
	}
	next if $ct->mkelem([qw(-ci -nc)], $elem)->system;
	next if $ct->co([qw(-nc)], $elem)->system;
	next if $ct->ci([qw(-nc -ide)], $elem)->system;
    }
    printf "%-6s: %s\n", $style, timestr(timediff(new Benchmark, $t1), 'noc');
}

my @elems = map { MSWIN ? glob : $_ } @ARGV;

printf "Benchmarking writes with %d new elements ...\n", scalar(@elems);

ClearCase::Argv->fork_exec(2);
writeops(@elems);

ClearCase::Argv->ctcmd(2);
writeops(@elems);

# Benchmark IPC::ClearTool mode - turned off by default.
ClearCase::Argv->ipc(2);
writeops(@elems);
