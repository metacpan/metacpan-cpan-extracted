use strict;
use warnings;
use Test::More;

use Command::Run;

# basic code reference
my $result = Command::Run->new(command => [sub { print "from code" }])->run;
is $result->{data}, "from code", 'code reference execution';
is $result->{result}, 0, 'code reference exit status';

# code reference with arguments via @ARGV
$result = Command::Run->new(command => [sub { print "@ARGV" }, 'a', 'b', 'c'])->run;
is $result->{data}, "a b c", 'code reference with @ARGV';

# code reference with arguments via @_
$result = Command::Run->new(command => [sub { print "@_" }, 'x', 'y', 'z'])->run;
is $result->{data}, "x y z", 'code reference with @_';

# code reference with stdin
$result = Command::Run->new(
    command => [sub { print scalar <STDIN> }],
    stdin   => "stdin data",
)->run;
is $result->{data}, "stdin data", 'code reference with stdin';

# code reference stderr redirect
$result = Command::Run->new(
    command => [sub { print "out"; print STDERR "err" }],
    stderr  => 'redirect',
)->run;
like $result->{data}, qr/out/, 'code stdout with redirect';
like $result->{data}, qr/err/, 'code stderr merged';

# code reference stderr capture
$result = Command::Run->new(
    command => [sub { print "out"; print STDERR "err" }],
    stderr  => 'capture',
)->run;
is $result->{data}, "out", 'code stdout with capture';
is $result->{error}, "err", 'code stderr captured';

# result and error methods
my $cmd = Command::Run->new(
    command => [sub { print "data"; print STDERR "error" }],
    stderr  => 'capture',
);
$cmd->run;
is $cmd->result->{data}, "data", 'result method';
is $cmd->error, "error", 'error method';

# date method
ok defined $cmd->date, 'date method';

done_testing;
