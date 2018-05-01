#!perl -- -*- mode: cperl -*-

use strict;
BEGIN {
    my $exit_message = "";
    unless ($exit_message) {
        if (!$ENV{AUTHOR_TEST}) {
            $exit_message = "envariable AUTHOR_TEST not set";
        }
    }
    if ($exit_message) {
        $|=1;
        print "1..0 # SKIP $exit_message\n";
        eval "require POSIX; 1" and POSIX::_exit(0);
    }
}

use File::Path qw(mkpath);
use Test::More;
use File::Spec;
use CPAN::Testers::ParseReport;
use Time::HiRes qw(time);

my $plan;

{
    BEGIN { $plan += 1 }
    mkpath "t/var-live";
    my $system = qq{"$^X" "-Ilib" "bin/ctgetreports" "--prefer-local-reports" "--cachedir" "t/var-live" "--solve" "--verbose" "--transport" "http_cpantesters_gzip" "Scriptalicious-1.16" 2>&1};
    diag "running system='$system'";
    my $start = time;
    open my $fh, "-|", $system or die "could not fork: $!";
    my @reg;
    while (<$fh>) {
        push @reg, $1 if /^Regression '(.+)'/;
    }
    my $duration = time - $start;
    @reg = sort @reg; # make it a bit less fragile
    is "@reg",
        "conf:archname+osvers fail:t/04-fork.t meta:osname+perl",
        "found the 'right' top 3 candidates in $duration seconds; (a very fragile test)";
}

unlink "ctgetreports.out";

BEGIN {
      plan tests => $plan;
}

__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:

