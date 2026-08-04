use strict;
use warnings;
use Test::More;

use Command::Run;

##
## All parameters can be given to run() as temporary ones, which are
## effective only for that execution and leave the object unchanged.
##

# command
{
    my $result = Command::Run->new->run(command => ['echo', 'hello']);
    is $result->{data}, "hello\n", 'run with command';
}

# command in string form goes through the shell
{
    my $result = Command::Run->new->run(command => 'echo shell');
    is $result->{data}, "shell\n", 'run with command in string form';
}

# command overrides the stored one
{
    my $runner = Command::Run->new(command => ['echo', 'stored']);
    is $runner->run(command => ['echo', 'temporary'])->{data}, "temporary\n",
        'temporary command overrides stored one';
    is $runner->run->{data}, "stored\n",
        'stored command is left unchanged';
}

# stdout reference
{
    my $out;
    Command::Run->new(command => ['echo', 'world'])->run(stdout => \$out);
    is $out, "world\n", 'run with stdout reference';
}

# stdout reference does not disturb the stored one
{
    my ($stored, $temporary);
    my $runner = Command::Run->new(command => ['echo', 'x'], stdout => \$stored);
    $runner->run(stdout => \$temporary);
    is $temporary, "x\n", 'temporary stdout reference is filled';
    is $stored, undef, 'stored stdout reference is left unchanged';
}

# stderr reference
{
    my $err;
    my $result = Command::Run->new(command => ['sh', '-c', 'echo err >&2'])
        ->run(stderr => \$err);
    is $err, "err\n", 'run with stderr reference';
    is $result->{error}, "err\n", 'stderr reference implies capture';
}

# combination -- "All-in-one style"
{
    my $result = Command::Run->new->run(
        command => ['cat', '-n'],
        stdin   => "foo\n",
        stderr  => 'redirect',
    );
    like $result->{data}, qr/1.*foo/, 'run with command, stdin and stderr';
}

# no command at all
{
    my $result = Command::Run->new->run;
    is_deeply $result, {}, 'run without command returns empty result';
}

done_testing;
