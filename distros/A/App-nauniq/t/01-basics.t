#!perl

use 5.010;
use strict;
use warnings;
use FindBin;

use File::chdir;
use File::Slurp::Tiny qw(read_file write_file);
use File::Temp qw(tempdir);
use IPC::Cmd qw(run_forked);
use String::ShellQuote;
use Test::More 0.98;

BEGIN {
    if ($^O =~ /win/i) {
        plan skip_all => "run_forked() not available on Windows";
        exit 0;
    }
}

sub lines { join("", map {"$_\n"} @_) }

my ($tmpdir) = tempdir(CLEANUP => 1);
$CWD = $tmpdir;

# convention: all input files are named if*, output files of*

write_file("if1", lines(1, 2, 3));
write_file("if2", lines(1, 2, 3, 3, 2, 4));

subtest "no options" => sub {
    test_nauniq(
        args    => [qw//],
        input   => lines(1, 2, 3),
        output  => lines(1, 2, 3),
    );
    test_nauniq(
        args    => [qw//],
        input   => lines(1, 2, 3, 3, 2, 4),
        output  => lines(1, 2, 3, 4),
    );
    test_nauniq(
        name    => 'input from file',
        args    => [qw/if2/],
        output  => lines(1, 2, 3, 4),
    );
    test_nauniq(
        name    => 'output to file',
        args    => [qw/- of2/],
        input   => lines(1, 2, 3, 3, 2, 4),
        outfile => "of2",
        outfile_content => lines(1, 2, 3, 4),
    );
    test_nauniq(
        name    => 'input from file & output to file',
        args    => [qw/if2 of2/],
        outfile => "of2",
        outfile_content => lines(1, 2, 3, 4),
    );
};

subtest "option: --repeated -d" => sub {
    for my $opt (qw/--repeated -d/) {
        test_nauniq(
            args   => [$opt],
            input  => lines(1, 2, 3, 3, 2),
            output => lines(3, 2),
        );
        test_nauniq(
            name   => "cancels --unique",
            args   => ["--unique", $opt],
            input  => lines(1, 2, 3, 3, 2),
            output => lines(3, 2),
        );
    }
};

subtest "option: --ignore-case -i" => sub {
    for my $opt (qw/--ignore-case -i/) {
        test_nauniq(
            args   => [$opt],
            input  => lines(qw/a B b A c/),
            output => lines(qw/a B c/),
        );
    }
};

subtest "option: --num-entries" => sub {
    for my $opt (qw/--num-entries/) {
        test_nauniq(
            args   => [$opt, 4],
            input  => lines(1, 2, 3, 2, 4, 1),
            output => lines(1, 2, 3, 4),
        );
        test_nauniq(
            args   => [$opt, 3],
            input  => lines(1, 2, 3, 2, 4, 1),
            output => lines(1, 2, 3, 4, 1),
        );
    }
};

subtest "option: --skip-chars -s" => sub {
    for my $opt (qw/--skip-chars -s/) {
        test_nauniq(
            args   => [$opt, 2],
            input  => lines(qw/aa1 aa2 ab1 ab2/),
            output => lines(qw/aa1 aa2/),
        );
    }
};

subtest "option: --unique -u" => sub {
    for my $opt (qw/--unique -u/) {
        test_nauniq(
            args   => [$opt],
            input  => lines(1, 2, 3, 3, 2),
            output => lines(1, 2, 3),
        );
        test_nauniq(
            name   => "cancels --repeated",
            args   => ["--repeated", $opt],
            input  => lines(1, 2, 3, 3, 2),
            output => lines(1, 2, 3),
        );
    }
};

subtest "option: --check-chars -w" => sub {
    for my $opt (qw/--check-chars -w/) {
        test_nauniq(
            args   => [$opt, 1],
            input  => lines(qw/1aa 2aa 1ab 2ab/),
            output => lines(qw/1aa 2aa/),
        );
        test_nauniq(
            name   => "combined with --skip-chars",
            args   => [$opt, 1, "--skip-chars", 2],
            input  => lines(qw/aa1aa aa2aa ab1ab ab2ab/),
            output => lines(qw/aa1aa aa2aa/),
        );
    }
};

subtest "option: --forget-pattern" => sub {
    for my $opt (qw/--forget-pattern/) {
        test_nauniq(
            name     => "invalid regex -> exit 99",
            args     => [$opt, "("],
            exitcode => 99,
        );
        test_nauniq(
            args   => [$opt, "^\\*"],
            input  => lines(qw/1 2 2 *break* 1 1 2/),
            output => lines(qw/1 2 *break* 1 2/),
        );
    }
};

subtest "option: --append" => sub {
    for my $opt (qw/--append/) {
        write_file("af1", lines(1, 2, 3));
        test_nauniq(
            args    => [$opt, "-", "af1"],
            input   => lines(1, 2, 2, 3, 4, 1),
            outfile => "af1",
            outfile_content => lines(1, 2, 3, 1, 2, 3, 4),
        );
    }
};

subtest "option: -a" => sub {
    for my $opts (["-a"], ["--append", "--read-output"]) {
        write_file("af1", lines(1, 2, 3));
        test_nauniq(
            args    => [@$opts, "-", "af1"],
            input   => lines(1, 2, 2, 3, 4, 1),
            outfile => "af1",
            outfile_content => lines(1, 2, 3, 4),
        );
    }
};

subtest "option: --md5" => sub {
    for my $opt (qw/--md5/) {
        test_nauniq(
            args   => [$opt],
            input  => lines(1, 2, 3, 4, 1),
            output => lines(1, 2, 3, 4),
        );
    }
};

DONE_TESTING:
done_testing;
if (Test::More->builder->is_passing) {
    diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}

sub test_nauniq {
    my %args = @_;

    # delete all output files first
    unlink <of*>;

    my @progargs = @{ $args{args} // [] };
    my $name = $args{name} // join(" ", @progargs);
    subtest $name => sub {
        my $expected_exit = $args{exitcode} // 0;
        my %runopts;
        $runopts{child_stdin} = $args{input} if defined $args{input};
        # run_forked() doesn't accept arrayref command, lame
        my $cmd = join(
            " ",
            map {shell_quote($_)}
                ($^X, "$FindBin::Bin/../bin/nauniq", @progargs));
        note "cmd: $cmd";
        my $res = run_forked($cmd, \%runopts);

        is($res->{exit_code}, $expected_exit,
           "exit code = $expected_exit") or do {
               if ($expected_exit == 0) {
                   diag explain $res;
               }
           };

        if (defined $args{output}) {
            is($res->{stdout}, $args{output}, "output");
        }

        if (defined $args{outfile}) {
            if (ok((-f $args{outfile}), "output file exists")) {
                if (defined $args{outfile_content}) {
                    is(read_file($args{outfile}), $args{outfile_content},
                       "output file content");
                }
            }
        }
    };
}
