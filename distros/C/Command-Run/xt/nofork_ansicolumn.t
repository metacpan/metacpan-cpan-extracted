use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require App::ansicolumn }
        or plan skip_all => 'App::ansicolumn not installed';
}

use Command::Run;

my $func = \&App::ansicolumn::ansicolumn;
my $input = join("\n", 1..20) . "\n";

subtest 'fork vs nofork: same output' => sub {
    my @cmd = ($func, '-c80', '-C2');
    my $fork   = Command::Run->new(command => \@cmd, stdin => $input)->run;
    my $nofork = Command::Run->new(command => \@cmd, stdin => $input, nofork => 1)->run;
    is $fork->{result},   0, 'fork: exit status 0';
    is $nofork->{result}, 0, 'nofork: exit status 0';
    is $nofork->{data}, $fork->{data}, 'fork and nofork produce same output';
};

subtest 'fork vs nofork+raw: same output' => sub {
    my @cmd = ($func, '-c80', '-C2');
    my $fork = Command::Run->new(command => \@cmd, stdin => $input)->run;
    my $raw  = Command::Run->new(command => \@cmd, stdin => $input, nofork => 1, raw => 1)->run;
    is $raw->{result}, 0, 'nofork+raw: exit status 0';
    is $raw->{data}, $fork->{data}, 'nofork+raw produces same output as fork';
};

subtest 'nofork: column options' => sub {
    my $result = Command::Run->new(
        command => [$func, '-c80', '-C4'],
        stdin   => $input,
        nofork  => 1,
    )->run;
    is $result->{result}, 0, 'exit status 0';
    my @lines = split /\n/, $result->{data};
    is scalar @lines, 5, '20 items in 4 columns = 5 rows';
};

subtest 'nofork: fillrows mode' => sub {
    my $result = Command::Run->new(
        command => [$func, '-c80', '-C4', '-x'],
        stdin   => $input,
        nofork  => 1,
    )->run;
    is $result->{result}, 0, 'exit status 0';
    like $result->{data}, qr/^1\s+2\s+3\s+4\s*$/m, 'fillrows order';
};

subtest 'nofork: stdout/stderr references' => sub {
    my ($out, $err);
    Command::Run->new(
        command => [$func, '-c80', '-C2'],
        stdin   => $input,
        stdout  => \$out,
        stderr  => \$err,
        nofork  => 1,
    )->run;
    ok length($out) > 0, 'stdout captured via reference';
    is $err, '', 'no stderr on success';
};

subtest 'nofork: repeated execution' => sub {
    my $runner = Command::Run->new(
        command => [$func, '-c80', '-C2'],
        nofork  => 1,
    );
    my $r1 = $runner->run(stdin => join("\n", 'a'..'j') . "\n");
    my $r2 = $runner->run(stdin => join("\n", 1..10) . "\n");
    is $r1->{result}, 0, 'first run ok';
    is $r2->{result}, 0, 'second run ok';
    like $r1->{data}, qr/a/, 'first run has expected data';
    like $r2->{data}, qr/1/, 'second run has expected data';
    isnt $r1->{data}, $r2->{data}, 'different input gives different output';
};

done_testing;
