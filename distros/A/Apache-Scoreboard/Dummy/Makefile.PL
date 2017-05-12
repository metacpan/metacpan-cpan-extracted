use ExtUtils::MakeMaker;

use strict;
use warnings FATAL => 'all';

use ModPerl::MM ();

#mmm
system "cp ../typemap ." unless -e "typemap";

sub genxs {
    system "cat dummy.c ../Scoreboard.xs > DummyScoreboard.xs";
    system $^X, "-pi", "-e",
        "s/(MODULE *= *Apache::)Scoreboard/\$1.DummyScoreboard/e; " .
        "s|apxs/send.c|../apxs/send.c|;",
        "DummyScoreboard.xs";
}

genxs();

# get the apr header files, depending on where they are
my $apr_config = `which apr-config 2>/dev/null` || `which apr-1-config 2>/dev/null`;
chomp $apr_config;
my $apr_inc = `$apr_config --includedir`;
chomp $apr_inc;
my $extra_inc;
$extra_inc = "-I$apr_inc"       if ($apr_inc);

ModPerl::MM::WriteMakefile(
    NAME	 => 'Apache::DummyScoreboard',
    VERSION_FROM => 'DummyScoreboard.pm',
    INC => join " ", $extra_inc, ModPerl::MM::get_def_opt('INC'),

);
