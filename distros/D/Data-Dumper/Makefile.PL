#-*- buffer-read-only: t -*-

# This Makefile.PL was written by make_ext.pl.
# It will be deleted automatically by make realclean

use strict;
use ExtUtils::MakeMaker;

# This is what the .PL extracts to. Not the ultimate file that is installed.
# (ie Win32 runs pl2bat after this)


my $script_ext = $^O eq 'VMS' ? '.com' : '';
my %pod_scripts;
foreach (glob('pod*.PL')) {
    my $script = $_;
    s/.PL$/$script_ext/i;
    $pod_scripts{$script} = $_;
}
my @exe_files = values %pod_scripts;

WriteMakefile(
    NAME          => 'Data::Dumper',
    VERSION_FROM  => 'Dumper.pm',
    ABSTRACT_FROM => 'Dumper.pm',
    DEFINE        => '-DUSE_PPPORT_H',
    (%pod_scripts ? (
        PL_FILES  => \%pod_scripts,
        EXE_FILES => \@exe_files,
        clean     => { FILES => "@exe_files" },
    ) : ()),
);

# ex: set ro:
