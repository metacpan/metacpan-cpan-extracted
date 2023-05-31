#!/usr/bin/perl -w
# -*- perl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use File::Temp qw(tempfile);

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }

    *eq_or_diff = eval { require Test::Differences; \&Test::Differences::eq_or_diff } || \&Test::More::is;
}

my $use_blib = 1;
my $psort = "$FindBin::RealBin/../blib/script/psort";
unless (-f $psort) {
    # blib version not available, use ../bin source version
    $psort = "$FindBin::RealBin/../bin/psort";
    $use_blib = 0;
}

# Special handling for systems without shebang handling
my @full_script = $^O eq 'MSWin32' || !$use_blib ? ($^X, $psort) : ($psort);

my @test_defs =
    (# options
     #       in
     #              out (expected)
     #                     --check(able)
     #                        in is unsorted
     [undef, <<EOF, <<EOF, 1, 1],
c
b
a
EOF
a
b
c
EOF

    [undef, <<EOF, <<EOF, 1, 1],
abc

xyz
EOF

abc
xyz
EOF

    [undef, <<EOF, <<EOF, 1, 1],
\tTAB

EOF

\tTAB
EOF

     [undef, "", "", 1, 0],

     [undef, "\n", "\n", 1, 0],

     [undef, "one line", "one line", 1, 0],

     [undef, "one line\n", "one line\n", 1, 0],

     [["-r"], <<EOF, <<EOF, 1, 0],
c
b
a
EOF
c
b
a
EOF

     [["-f"], <<EOF, <<EOF, 1, 1],
C
b
A
EOF
A
b
C
EOF

     [["-bf"], <<EOF, <<EOF, 1, 1],
 C
  b
A
EOF
A
  b
 C
EOF

     [["-n"], <<EOF, <<EOF, 1, 1],
111
22
3
EOF
3
22
111
EOF

     [["-n", "-r"], <<EOF, <<EOF, 1, 0],
111
22
3
EOF
111
22
3
EOF

     [['-N', '-f'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
Foolio
Foo12a
EOF
9x
14
foo
fooa
foolio
Foolio
foo12
foo12a
Foo12a
foo12z
foo13a
EOF

     # same like -N -f, but manually use'ing the module and defining
     # the compare function
     [['-MSort::Naturally=ncmp', '-C', 'ncmp($a, $b)', '-f'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
Foolio
Foo12a
EOF
9x
14
foo
fooa
foolio
Foolio
foo12
foo12a
Foo12a
foo12z
foo13a
EOF

     # -m works, too
     [['-mSort::Naturally=ncmp', '-C', 'ncmp($a, $b)', '-f'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
Foolio
Foo12a
EOF
9x
14
foo
fooa
foolio
Foolio
foo12
foo12a
Foo12a
foo12z
foo13a
EOF

     # BEGIN blocks work, too
     [['-C', 'BEGIN { use Sort::Naturally qw(ncmp) } ncmp($a, $b)', '-f'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
Foolio
Foo12a
EOF
9x
14
foo
fooa
foolio
Foolio
foo12
foo12a
Foo12a
foo12z
foo13a
EOF

     # -M without import list
     [['-MSort::Naturally', '-C', 'ncmp($a, $b)', '-f'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
Foolio
Foo12a
EOF
9x
14
foo
fooa
foolio
Foolio
foo12
foo12a
Foo12a
foo12z
foo13a
EOF

     [['-N', '-r'], <<EOF, <<EOF, 1, 1],
foo12a
foo12z
foo13a
foo
14
9x
foo12
fooa
foolio
EOF
foo13a
foo12z
foo12a
foo12
foolio
fooa
foo
14
9x
EOF

     [["-V"], <<EOF, <<EOF, 1, 1],
1.0
2.3.0
1.1.5.1
2.3.1
20
10.0
EOF
1.0
1.1.5.1
2.3.0
2.3.1
10.0
20
EOF

     [["-Vr"], <<EOF, <<EOF, 1, 1],
1.0
2.3.0
1.1.5.1
2.3.1
20
10.0
EOF
20
10.0
2.3.1
2.3.0
1.1.5.1
1.0
EOF

     do {
         my $in = <<EOF;
Files=1, Tests=3,  3 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  2 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3, 11 wallclock secs (10.02 usr  0.02 sys +  0.09 cusr  0.01 csys = 10.14 CPU)
EOF
	 my $out = <<EOF;
Files=1, Tests=3,  0 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  2 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3,  3 wallclock secs ( 0.02 usr  0.02 sys +  0.09 cusr  0.01 csys =  0.14 CPU)
Files=1, Tests=3, 11 wallclock secs (10.02 usr  0.02 sys +  0.09 cusr  0.01 csys = 10.14 CPU)
EOF
	 (
	  [["-n", "-e", 'm{(\d+) wallclock secs}; $1'], $in, $out, 1, 1],
	  [["-n", "--rx", '(\d+) wallclock secs'], $in, $out, 1, 1],
	 )
     },

     do {
	 my $in = <<EOF;
xxx c
zzz b
yyy a
EOF
	 my $out = <<EOF;
yyy a
zzz b
xxx c
EOF
	 (
	  [["-e", 'substr $_, 4'], $in, $out, 1, 1],
	  [["--rx", '\S+\s+(\S+)'], $in, $out, 1, 1],
	 )
     },

     do {
	 my $in = <<EOF;
xxx 3
zzz 2
yyy 1
EOF
	 my $out = <<EOF;
yyy 1
zzz 2
xxx 3
EOF
	 (
	  [["-n", "--rx", '\d+'], $in, $out, 1, 1],
	 )
     },

     do {
	 my $in = <<EOF;
xxx /3/
zzz /2/
yyy /1/
EOF
	 my $out = <<EOF;
yyy /1/
zzz /2/
xxx /3/
EOF
	 (
	  [["-n", "--rx", '/(\d+)/'], $in, $out, 1, 1],
	 )
     },

     [["-C", '$a cmp $b'], <<EOF, <<EOF, 1, 1],
c
b
a
EOF
a
b
c
EOF

     [["-u"], <<EOF, <<EOF, 1, 1],
c
b
c
a
b
EOF
a
b
c
EOF

     [["-u", "-e", 'substr($_,0,1)'], <<EOF, <<EOF, 1, 1],
c1
b1
c2
a1
b2
EOF
a1
b1
b2
c1
c2
EOF

     [["-u"], <<EOF, <<EOF, 1, 0],
a
b
c
EOF
a
b
c
EOF

     # non-printables
     [[], <<EOF, <<EOF, 1, 1],
aa
a\7a
EOF
a\7a
aa
EOF

     [["-i"], <<EOF, <<EOF, 1, 0],
aa
a\7a
EOF
aa
a\7a
EOF

     [["-v"], "", qr{^psort version \d+\.\d+(?:_\d+)?$}, 0, undef],

    );

my @erroneous_test_defs =
    (
     [["--invalid-option"], "", qr{usage}],
     [["--field-function", 'perl compile er{ror'], '', qr{Cannot compile}],
     [["--compare-function", 'perl compile er{ror'], '', qr{Cannot compile}],
     [['-MThis::Module::Does::Not::Exist'], '', qr{Can't locate}],
     [['-MSort::Naturally=', '-C', 'ncmp($a,$b)'], "first test line\nsecond test line\n", qr{Undefined subroutine}],
    );

my @warning_test_defs =
    (
     [["-n", "--rx", '/\d+/'], ("xxx 3\nzzz 2\nyyy 1\n") x 2, qr{\QNo regexp match. Maybe you want to omit the slashes, i.e. use --rx '\d+'?}],
     [["--rx", '\d+'], ("xxx\n") x 2, qr{^\QUninitialized value returned in psort eval or regexp at standard input line 1\E$}], # custom warning
     [["--rx", '\d+'], ("xxx\n") x 2, qr{^\QUninitialized value returned in psort eval or regexp at \E.*\.dat\Q line 1\E$}, indata_in_file=>1], # custom warning, with file name
     [["-X", "--rx", '\d+'], ("xxx\n") x 2, qr{^$}], # custom warning suppressed
     [["--no-warnings", "--rx", '\d+'], ("xxx\n") x 2, qr{^$}], # custom warning suppressed
    );

my $ok_test_count    = 4;
my $error_test_count = 2;
my $warning_test_count = 3;
plan tests => 1 + $ok_test_count*@test_defs + $error_test_count*@erroneous_test_defs + $warning_test_count*@warning_test_defs;

SKIP: {
    skip "-x test does not work on Windows", 1
	if $^O eq 'MSWin32';

    ok -x $psort, 'psort is executable';
}

for my $test_def (@test_defs) {
    run_psort_testcase(@$test_def);
}

for my $test_def (@erroneous_test_defs) {
    run_psort_erroneous_testcase(@$test_def);
}

for my $test_def (@warning_test_defs) {
    run_psort_warning_testcase(@$test_def);
}

sub _run_psort_testcase {
    my($expect_error, $args, $indata, $expected, $checkable, $unsorted_in) = @_;
    $args = [] if !$args;

    my($tmpfh,$tmpfile) = tempfile(UNLINK => 1, SUFFIX => ".dat")
	or die $!;
    print $tmpfh $indata;
    close $tmpfh
	or die $!;

    my @sort_cmd  = (@full_script, @$args, $tmpfile);

 SKIP: {
	my $run_res = _run_psort(\@sort_cmd, $expect_error, undef);
	if ($run_res->{error}) {
	    skip $run_res->{error}, $expect_error ? $error_test_count : $ok_test_count;
	}

	my $cmd_res = $run_res->{cmdres};
	my $buf     = $expect_error ? $run_res->{stderr} : $run_res->{stdout};

	if ($expect_error) {
	    ok !$cmd_res, 'Expected failure'
		or diag "While running '@sort_cmd'";
	} else {
	    ok $cmd_res, 'Expected success'
		or diag "While running '@sort_cmd': $?";
	}

	my $testlabel = !defined $args ? '<no args>' : "args: <@$args>";
	if (ref $expected eq 'Regexp') {
	    like $buf, $expected, $testlabel;
	} else {
	    eq_or_diff $buf, $expected, $testlabel;
	}

	if (!$expect_error) {
	SKIP: {
		skip "This test case is not checkable", 2
		    if !$checkable;

		# Check input data
		{
		    my @check_args = (@$args, (rand(2) < 1 ? '--check' : '-c'));
		    my @check_cmd = (@full_script, @check_args, $tmpfile);
		    system @check_cmd;
		    my $ret = $?>>8;
		    is $ret, $unsorted_in, "Check command with args <@check_args> returned $ret (in data)";
		}

		# Check sorted data
		{
		    my($tmpsortfh,$tmpsortfile) = tempfile(UNLINK => 1, SUFFIX => '.dat')
			or die $!;
		    print $tmpsortfh $buf;
		    close $tmpsortfh
			or die $!;

		    my @check_args = (@$args, (rand(2) < 1 ? '--check' : '-c'));
		    my @check_cmd = (@full_script, @check_args, $tmpsortfile);
		    system @check_cmd;
		    is $?, 0, "Check command with args <@check_args> returned $? (sorted data)";

		    unlink $tmpsortfile;
		}
	    }
	}
    }

    unlink $tmpfile;
}

sub run_psort_testcase {
    my($args, $indata, $expected, $checkable, $unsorted_in) = @_;
    _run_psort_testcase(0, $args, $indata, $expected, $checkable, $unsorted_in);
}

sub run_psort_erroneous_testcase {
    my($args, $indata, $expected) = @_;
    _run_psort_testcase(1, $args, $indata, $expected);
}

sub run_psort_warning_testcase {
    my($args, $indata, $expected, $expected_warning, %opts) = @_;
    my $indata_in_file = delete $opts{indata_in_file};
    die "Unhandled options: " . join(" ", %opts) if %opts;

    my @run_psort_args;
    if ($indata_in_file) {
	my($tmpfh,$tmpfile) = tempfile(UNLINK => 1, SUFFIX => ".dat")
	    or die $!;
	print $tmpfh $indata;
	close $tmpfh
	    or die $!;
	@run_psort_args = ([@full_script, @$args, $tmpfile], 1, undef);
    } else {
	@run_psort_args = ([@full_script, @$args          ], 1, \$indata);
    }

    my($result) = _run_psort(@run_psort_args);
 SKIP: {
	skip $result->{error}, $warning_test_count
	    if $result->{error};
	my $testlabel = !defined $args ? '<no args>' : "args: <@$args>";
	$testlabel .= " (with option indata_in_file)" if $indata_in_file;
	ok $result->{cmdres}, "Expected success for $testlabel";
	eq_or_diff $result->{stdout}, $expected, "Expected output for $testlabel";
	like $result->{stderr}, $expected_warning, "Expected warning for $testlabel";
    }
}

sub _run_psort {
    my($sort_cmd, $get_stderr, $input_ref) = @_;

    my $stdout = '';
    my $stderr = '';
    my $cmdres;

    if (eval { require IPC::Run; 1 }) {
	$cmdres = IPC::Run::run($sort_cmd, ">", \$stdout, "2>", \$stderr, ($input_ref ? ("<", $input_ref) : ()));
    } else {
	if ($get_stderr) {
	    return { error => "Can't run stderr tests without IPC::Run" };
	} elsif ($input_ref) {
	    return { error => "Can't run stdin tests without IPC::Run" };
	} elsif ($^O eq 'MSWin32') {
	    return { error => "MSWin32 needs IPC::Run for tests because: List form of pipe open not implemented" };
	} else {
	    my $fh;
	    if ($] < 5.008) {
		open $fh, "-|" or exec @$sort_cmd;
	    } else {
		open $fh, "-|", @$sort_cmd
		    or die "While running @$sort_cmd: $!";
	    }
	    while(<$fh>) {
		$stdout .= $_;
	    }
	    $cmdres = close $fh;
	}
    }
    return {
	    cmdres => $cmdres,
	    stdout => $stdout,
	    stderr => $stderr,
	   };
}

__END__
