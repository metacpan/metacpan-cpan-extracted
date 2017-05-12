#!perl -- -*- mode: cperl -*-

use strict;
BEGIN {
    my $exit_message = "";
    unless ($exit_message) {
        if (!$ENV{AUTHOR_TEST}) {
            $exit_message = "envariable AUTHOR_TEST not set";
        }
    }
    unless ($exit_message) {
        eval "use Devel::NYTProf";
        $exit_message = "Devel::NYTProf required for testing profiling"
            if $@;
    }
    unless ($exit_message) {
        my $d = "/home/andreas/data/cnntp-solver-2009/workdir/solved";
        $exit_message = "Directory '$d' not found but required by test"
            unless -d $d;
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
use List::Util qw(sum);
use Time::HiRes qw(time);

my $plan;

use warnings;
{
    BEGIN { $plan += 2 }
    mkpath "t/var-live";
    my $system = qq{"$^X" "-Ilib" "-d:NYTProf" "bin/ctgetreports" "--prefer-local-reports" "--cachedir" "t/var-live" --pce --q meta:from --q 'qr:(.*version .+? required--this is only.*)' --q 'qr:("[A-Za-z0-9_]+" is not exported by the [A-Za-z0-9_:]+ module.*)' --q 'qr:(.*instance running.*)' --q 'qr:(.*could.?n.t (?:open|connect).*)' --q 'qr:((?i:.*could.?n.t find.*))' --q 'qr:(.*Base class package.*)' --q 'qr:(Can.t call method .*)' --q 'qr:(Can.t use an undefined value.*)' --q 'qr:(Can.t use string .*)' --q 'qr:(Can.t modify division)' --q 'qr:(Connection refused)' --q 'qr:(Can.t use keyword .*? as a label)' --q 'qr:(Could not open .*)' --q 'qr:(Address already in use)' --q 'qr:(.*is deprecated (?:and will be removed)?)' --q 'qr:(skip(?:ping |ped: | test).*)' --q 'qr:(Please rerun the make command)' --q 'qr:(v-string .* non-portable at \\S+)' --q 'qr:(The module .* isn.t available on CPAN)' --q 'qr:(Invalid version format)' --q 'qr:did you mean \$\] \?' --q 'qr:Unescaped left brace in regex is deprecated' --q 'qr:Non-ASCII character seen before =encoding' --q 'qr:((Smartmatch|given|when) is experimental)' --q 'qr:# (.+ alternative text .+ contains non-escaped .+)' --q 'qr:=over without closing =back' --q 'qr:starts or ends with whitespace' --q 'qr:Acme::Override::INET replaced IO::Socket::INET' --q 'qr:Invalid byte sequence' --q 'qr:Insecure dependency in require' --q 'qr:Passing a list of values to enum' --q 'qr:(undefined symbol: [A-Za-z0-9_]+ )' --solve --solvetop=123 --dumpfile=/home/andreas/data/cnntp-solver-2009/workdir/solved/Internals-DumpArenas-0.12.slvdv --minpass=3 --transport=http_cpantesters_gzip --prefer-local-reports --vdistro=Internals-DumpArenas-0.12 Internals-DumpArenas "--verbose" > ctgetreports-nytprof.out 2>&1};
    diag "running system='$system'";
    my $start = time;
    if (ok(0 == system($system), "system calc")) {
        my $makehtml = $^X;
        $makehtml =~ s|/perl$|/nytprofhtml|;
        ok(0 == system($system), "system make html");
    } else {
        fail; # just to count according to plan
    }
}

BEGIN {
      plan tests => $plan;
}

__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:

