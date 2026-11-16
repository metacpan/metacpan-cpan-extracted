use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Command::Run;

##
## Tests for the fork path: the parent must not block on the pipes,
## and the child must never come back into the program of the caller.
##

my $dir = tempdir(CLEANUP => 1);
my @inc = map { "-I$_" } grep { !ref } @INC;

# run code with a time limit, so that a deadlock fails instead of hanging
sub with_timeout {
    my($sec, $code) = @_;
    my $result = eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm $sec;
        my $r = $code->();
        alarm 0;
        $r;
    };
    alarm 0;
    $result;
}

# write a script, run it by a separate perl, return its stdout and status
sub run_script {
    my($name, $text) = @_;
    my $file = "$dir/$name.pl";
    open my $fh, '>', $file or die "$file: $!";
    print $fh $text;
    close $fh;
    my $out = with_timeout(30, sub {
        my $pid = open my $ph, '-|';
        defined $pid or die "fork: $!";
        if ($pid == 0) {
            open STDERR, '>', '/dev/null';
            exec $^X, @inc, $file or POSIX::_exit(1);
        }
        my $out = do { local $/; <$ph> };
        close $ph;
        $out;
    });
    $out;
}

# much stderr with stderr => 'capture': both pipes are read together
{
    my $result = with_timeout(20, sub {
        Command::Run->new(
            command => [$^X, '-e', 'print STDERR "x" x 200000; print "OUT\n"'],
            stderr  => 'capture',
        )->run;
    });
    ok $result, 'much stderr: run returns';
    is $result && $result->{data}, "OUT\n", 'much stderr: stdout';
    is length($result ? $result->{error} : ''), 200000, 'much stderr: stderr';
}

# much stdout and much stderr at the same time
{
    my $result = with_timeout(20, sub {
        Command::Run->new(
            command => [$^X, '-e', 'for (1..100) { print "o" x 3000; print STDERR "e" x 3000 }'],
            stderr  => 'capture',
        )->run;
    });
    ok $result, 'much stdout and stderr: run returns';
    is length($result ? $result->{data}  : ''), 300000, 'much stdout and stderr: stdout';
    is length($result ? $result->{error} : ''), 300000, 'much stdout and stderr: stderr';
}

# output is decoded as a whole, not by each read
{
    my $result = with_timeout(20, sub {
        Command::Run->new(
            command => [$^X, '-e', 'binmode STDOUT, ":utf8"; print "\x{3042}" x 100000'],
        )->run;
    });
    is $result && $result->{data}, "\x{3042}" x 100000, 'large multibyte output';
}

# no output is an empty string
{
    my $result = Command::Run->new(
        command => [$^X, '-e', '1'],
        stderr  => 'capture',
    )->run;
    is $result->{data},  '', 'no output: stdout is empty string';
    is $result->{error}, '', 'no output: stderr is empty string';
}

# END block of the caller does not run in the child
{
    my $out = run_script('end', <<'END_SCRIPT');
use strict; use warnings;
use Command::Run;
$| = 1;
END { print "END\n" }
my $result = Command::Run->new(command => [sub { print "hi\n" }])->run;
(my $data = $result->{data}) =~ s/\n/|/g;
print "data=$data result=$result->{result}\n";
END_SCRIPT
    is $out, "data=hi| result=0\nEND\n", 'END block runs once, in the parent';
}

# output of the code is flushed before the child exits
{
    my $result = Command::Run->new(
        command => [sub { print "out"; print STDERR "err" }],
        stderr  => 'capture',
    )->run;
    is $result->{data},  "out", 'code output is flushed';
    is $result->{error}, "err", 'code error output is flushed';
    is $result->{result}, 0, 'code exit status';
}

# exec failure inside eval: the child does not continue the caller
{
    my $out = run_script('exec', <<'END_SCRIPT');
use strict; use warnings;
use Command::Run;
$| = 1;
my $parent = $$;
my $result = eval {
    Command::Run->new(command => ['no-such-command-xyz'], stderr => 'capture')->run;
};
print $$ == $parent ? "parent\n" : "child\n";
exit if $$ != $parent;
(my $data = $result->{data}) =~ s/\n/|/g;
print "data=$data status=", $result->{result} >> 8, "\n";
print "error ok\n" if $result->{error} =~ /no-such-command-xyz/;
END_SCRIPT
    is $out, "parent\ndata= status=127\nerror ok\n", 'exec failure in eval';
}

# exec failure without eval
{
    my $result = Command::Run->new(
        command => ['no-such-command-xyz'],
        stderr  => 'capture',
    )->run;
    is $result->{result} >> 8, 127, 'exec failure: status 127';
    is $result->{data}, '', 'exec failure: no data';
    like $result->{error}, qr/no-such-command-xyz/, 'exec failure: message';
}

# code that dies inside eval: the child does not continue the caller
{
    my $out = run_script('die', <<'END_SCRIPT');
use strict; use warnings;
use Command::Run;
$| = 1;
my $parent = $$;
my $result = eval {
    Command::Run->new(
        command => [sub { print "out\n"; die "oops\n" }],
        stderr  => 'capture',
    )->run;
};
print $$ == $parent ? "parent\n" : "child\n";
exit if $$ != $parent;
(my $data = $result->{data}) =~ s/\n/|/g;
(my $error = $result->{error}) =~ s/\n/|/g;
print "data=$data error=$error status=", $result->{result} >> 8, "\n";
END_SCRIPT
    is $out, "parent\ndata=out| error=oops| status=255\n", 'code dies in eval';
}

done_testing;
