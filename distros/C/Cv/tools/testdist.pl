#!/usr/bin/perl

my ($cv, $rev) = (&getCvVersion, &getSvnRevision);

foreach my $cc (qw(cc c++ g++-4 gcc-4 gcc44 g++44 gcc45 g++45 gcc46 g++46)) {
    my $test = "Cv-$cv-$rev-$cc";
    unless (system("which $cc") == 0) {
	system("touch $test.skipped");
	next;
    }
    my $cmd = join("\n",
		   "(",
		   echo_run("date"),
		   echo_run("uname -a"),
		   echo_run("perl -V"),
		   echo_run("$cc -v"),
		   "unset CXX",
		   "CC=$cc; export CC",
		   echo_run("make clean"),
		   echo_run("rm -rf Cv-$cv"),
		   echo_run("perl Makefile.PL && make distcheck disttest"),
		   ")",
	);
    my $test_ing = "$test...";
    my $test_ok = "$test.ok";
    my $test_notok = "$test.notok";
    unlink($test_ok);
    unlink($test_notok);
    my $r = xsystem("$cmd </dev/null", $test_ing);
    if ($r == 0) {
	rename($test_ing, $test_ok);
    } else {
	rename($test_ing, $test_notok);
    }
}

sub echo_run {
    my $cmd = shift;
    join("\n", "echo \'== $cmd ==\'", $cmd);
}

sub xsystem {
    my $cmd = shift;
    my $log = shift;
    local *STDOUT_COPY;
    local *STDERR_COPY;
    open(STDOUT_COPY, '>&STDOUT');
    open(STDERR_COPY, '>&STDERR');
    open(STDOUT, ">$log");
    open(STDERR, '>&STDOUT');
    my $r = system($cmd);
    open(STDOUT, ">&STDOUT_COPY");
    open(STDERR, ">&STDERR_COPY");
    # print STDERR $cmd, "\n";
    $r;
}

sub getCvVersion {
    open(GREP, "lib/Cv.pm") or die "can't get version";
    local $/ = ';';
    while (<GREP>) {
	next unless /\$VERSION\b/;
	eval $_;
	return $VERSION if defined $VERSION;
    }
    undef;
}

sub getSvnRevision {
    if (0) {
	open(SVN, "svn status -v|");
	my $rev = "unknown";
	while (<SVN>) {
	    next unless /^...\s+(\d+)/;
	    $rev = $1 if $1 > $rev;
	}
	return $rev;
    }
    if (1) {
	open(GIT, "git log|");
	my $rev = 0;
	while (<GIT>) {
	    next unless /^commit/;
	    $rev++;
	}
	return $rev;
    }
}
