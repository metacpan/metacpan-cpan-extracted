use strict;
use warnings;
use Test::More;

use Command::Run;

# new - direct command style
my $cmd = Command::Run->new('echo', 'hello');
ok $cmd, 'new with command';
isa_ok $cmd, 'Command::Run';
is_deeply [$cmd->command], ['echo', 'hello'], 'command method';

# new - options style
$cmd = Command::Run->new(command => ['echo', 'test']);
is_deeply [$cmd->command], ['echo', 'test'], 'new with options';

# run - basic execution
my $result = Command::Run->new('echo', 'hello')->run;
ok $result, 'run returns result';
is $result->{result}, 0, 'exit status 0';
is $result->{data}, "hello\n", 'captured stdout';
ok defined $result->{pid}, 'pid returned';

# data method
$cmd = Command::Run->new('echo', 'world');
$cmd->run;
is $cmd->data, "world\n", 'data method';

# path method
$cmd = Command::Run->new('echo', 'test');
$cmd->update;
like $cmd->path, qr{^/(dev/fd|proc/self/fd)/\d+$}, 'path method';

# stdin via with()
$result = Command::Run->new('cat')->with(stdin => "input data")->run;
is $result->{data}, "input data", 'stdin via with()';

# stdin via options
$result = Command::Run->new(
    command => ['cat'],
    stdin   => "option input",
)->run;
is $result->{data}, "option input", 'stdin via options';

# stderr - default (pass through, not captured)
$result = Command::Run->new('sh', '-c', 'echo out; echo err >&2')->run;
is $result->{data}, "out\n", 'stdout captured';
is $result->{error}, '', 'stderr not captured by default';

# stderr => 'redirect'
$result = Command::Run->new(
    command => ['sh', '-c', 'echo out; echo err >&2'],
    stderr  => 'redirect',
)->run;
like $result->{data}, qr/out/, 'stdout with redirect';
like $result->{data}, qr/err/, 'stderr merged to stdout';
is $result->{error}, '', 'error empty with redirect';

# stderr => 'capture'
$result = Command::Run->new(
    command => ['sh', '-c', 'echo out; echo err >&2'],
    stderr  => 'capture',
)->run;
is $result->{data}, "out\n", 'stdout with capture';
is $result->{error}, "err\n", 'stderr captured separately';

# exit status
$result = Command::Run->new('sh', '-c', 'exit 42')->run;
is $result->{result} >> 8, 42, 'non-zero exit status';

done_testing;
