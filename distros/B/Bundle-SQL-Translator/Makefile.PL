#!/usr/bin/perl

# ----------------------------------------------------------------------
# $Id$
# ----------------------------------------------------------------------
# Makefile.PL for Bundle::SQL::Translator.
# Originally created on Tuesday, September  2, 2003.
# ----------------------------------------------------------------------

use strict;

use ExtUtils::MakeMaker;
my (%PREREQ_PM, @EXE_FILES, %clean, %macro, %dist, @AUTHOR, @ABSTRACT);

%PREREQ_PM = (

);

@EXE_FILES = (

);

%clean = (
    FILES => '$(DISTVNAME).tar$(SUFFIX)',
);

%macro = (

);

%dist = (
    PREOP => 'perldoc -t lib/Bundle/SQL/Translator.pm > README; cpansign -s',
);

if ($] >= 5.00503) {
    @AUTHOR = (AUTHOR => 'darren chamberlain <darren@cpan.org>');
    @ABSTRACT = (ABSTRACT => 'a Bundle for SQL::Translator');
}
else {
    @AUTHOR = ();
    @ABSTRACT = ();
}

WriteMakefile(
    NAME        => "Bundle::SQL::Translator",
    VERSION     => "1.00",
    PREREQ_PM   => \%PREREQ_PM,
    EXE_FILES   => \@EXE_FILES,
    clean       => \%clean,
    macro       => \%macro,
    dist        => \%dist,
    @AUTHOR,
    @ABSTRACT,
);

package MY;
use File::Basename qw(basename);

sub libscan {
    my ($self, $file) = @_;
    my $bfile = basename($file);

    return if $bfile =~ /^\.(?:cvs)?ignore$/;
    return if $bfile =~ /\.swp$/;

    return $self->SUPER::libscan($file);
}
