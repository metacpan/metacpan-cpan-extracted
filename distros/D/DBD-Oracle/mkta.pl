#!/bin/env perl -w

# mkta - make-test-all
#
# quick hack to run test suite against multiple dbs
# for each db runn alternate charset tests in parallel
# keep log files from failures

use strict;
use Symbol;

local $| = 1;

use DBI;
use DBD::Oracle qw(ORA_OCI);
my @sid = DBI->data_sources('Oracle');
s/^dbi:Oracle://i for @sid;

# set TEST_FILES env var to override which tests are run
my $opt_full = 1;
my $opt_dir = "mkta";
my $opt_tf = $ENV{TEST_FILES};
my $opt_j = 6;

my $seq = 0;
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my (@queue, @run, %running, %skipped, @fail, $tested);

my @cs_utf8 = (ORA_OCI() < 9.2) ? ("UTF8") : ("AL32UTF8", ($opt_full) ? ("UTF8") : ());
my @cs_8bit = ($opt_full) ? ("WE8ISO8859P1", "WE8MSWIN1252") : ("WE8MSWIN1252");
my @charsets = ("", @cs_utf8, @cs_8bit);

# need to add in:
#	multiple perl versions/achitectures
#	multiple oracle versions

for my $sid (@sid) {
    mkta_sid_cs($sid, \@charsets);
}

sub mkta_sid_cs {
    my ($sid, $charsets) = @_;
    my $start_time = time;

    local $ENV{ORACLE_SID} = $sid;
    my $dbh = DBI->connect("dbi:Oracle:", $dbuser, undef, { PrintError=>0 });
    unless ($dbh) {
        (my $errstr = $DBI::errstr) =~ s/\n.*//s;
	push @{ $skipped{$errstr} }, $sid;
    	return;
    }
    mkdir $opt_dir, 0771 unless -d $opt_dir;
    print "$sid: testing with @$charsets ...\n";

    system("make") == 0
        or die "$0 aborted - make failed\n";
    system("rm -f $opt_dir/$sid-*-*.log");

    for my $ochar (@$charsets) {
        for my $nchar (@$charsets) {
	    # because empty NLS_NCHAR is same as NLS_LANG charset
	    next if $nchar eq '' && $ochar ne '';
	    push @queue, [ $sid, $ochar, $nchar ];
	}
    }
    while (@queue) {
        while (@queue && keys %running < $opt_j) {
	    my ($tag, $fh) = start_test(@{ shift @queue });
	    $running{$tag} = $fh;
	    push @run, $tag;
	    ++$tested;
	}
	wait_for_tests();
    }
    wait_for_tests();
    printf "$sid: completed in %.1f minutes\n", (time-$start_time)/60;
    print "\n";
}

sub start_test {
    my ($sid, $ochar, $nchar) = @_;
    local $ENV{NLS_LANG}  = ($ochar) ? ".$ochar" : "";
    local $ENV{NLS_NCHAR} = ($nchar) ?   $nchar  : "";
    local $ENV{DBD_ORACLE_SEQ} = ++$seq; # unique id for parallel runs
    my $tag = join "-", map { $_ || "unset" } ($sid, $ochar, $nchar);
    my $fh = gensym();
    my @make_opts;
    push @make_opts, "TEST_FILES='$opt_tf'" if $opt_tf;
    open $fh, "make test @make_opts > $opt_dir/$tag.log 2>&1 && rm $opt_dir/$tag.log |";
    print "$tag: started\n";
    return ($tag, $fh);
}

sub wait_for_tests {
    while(%running) {
        my @running = grep { $running{$_} } @run;
	my $tag = $running[0] or die;
	close $running{ $tag };
	printf "$tag: %s\n", ($?) ? "FAILED" : "pass";
	push @fail, $tag if $?;
	delete $running{$tag};
    }
}

print "Skipped due to $_: @{ $skipped{$_} }\n" for keys %skipped;

printf "Failed %d out of %d: @fail\n", scalar @fail, $tested;
print "done.\n"
