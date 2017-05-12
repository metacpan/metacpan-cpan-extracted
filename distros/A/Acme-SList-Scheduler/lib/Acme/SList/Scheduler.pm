package Acme::SList::Scheduler;
$Acme::SList::Scheduler::VERSION = '0.04';
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(srun label);
our @EXPORT_OK = qw();

use Getopt::Std;
use Acme::SList::Utilities qw(sdate sduration);

getopts('e:r:', \my %opts);

my $active = (defined($opts{r}) || defined($opts{e})) ? 0 : 1;

my $exec = 0;
my $aborted = 0;

my $act_label = '';

END {
    unless ($aborted) {
        if ($exec == 0) {
            my ($rc, $msg);

            if    (defined $opts{e}) { $rc = 242; $msg = "Unable to execute -e $opts{e}"; }
            elsif (defined $opts{r}) { $rc = 243; $msg = "Unable to restart -r $opts{r}"; }
            else                     { $rc = 244; $msg = "No program has been run"; }

            print "\n========================\n";
            print   "System Error (rc=$rc)\n";
            printf  "$msg\n";
            print   "========================\n";
            exit $rc;
        }

        print "\n";
        print "+---------------------------------------------------------------+\n";
        print "| -- SUCCESS --- SUCCESS --- SUCCESS --- SUCCESS --- SUCCESS -- |\n";
        print "+---------------------------------------------------------------+\n";
        print "\n";
    }
}

sub label {
    $act_label = $_[0];
}

sub srun {
    my ($prog) = @_;

    if (defined($opts{r}) and $opts{r} eq $act_label) { $active = 1; }
    if (defined($opts{e})) { $active = $opts{e} eq $act_label; }

    unless ($active) {
        print "\n";
        print "+-------\n";
        print "| Skipping Program '$prog'...\n";
        print "+-------\n";
        return;
    }

    $exec++;

    print "\n";
    print  "+---------------------------------------------------------------+\n";
    printf "| Program: %-52s |\n", "'$prog'";
    print  "+---------------------------------------------------------------+\n";

    my $prog_start = time;

    print "\n";
    print ">> Start : ", sdate($prog_start), "\n";;
    print "\n";

    my $extended = $prog;
    $extended =~ s{[\(,]}' 'xmsg;
    $extended =~ s{\)}''xmsg;

    my $code = system(qq{perl -C${^UNICODE} $extended});

    my $prog_stop = time;

    print "\n";
    print ">> Stop  : ", sdate($prog_stop), ", Duration : ", sduration($prog_start, $prog_stop), "\n";;

    return if $code == 0;

    $aborted = 1;

    my ($rc, $msg);

    if    ($code == -1) { $rc = 240; $msg = "Failed to execute: $!"; }
    elsif ($code & 127) { $rc = 241; $msg = sprintf("Child died with signal %d", ($code & 127)) }
    else {
        $rc = $code >> 8;

        if ($rc == 250) { $msg = "Program '$prog' halted"; }
    }

    if ($rc == 250) {
        print "\n========================\n";
        print   "System Error (rc=$rc)\n";
        printf  "$msg\n";
        print   "========================\n";
        exit $rc;
    }

    print "\n";
    print "\n";
    print "*******************************************************************\n";
    print "*******************************************************************\n";
    print "*******************************************************************\n";
    print "***                                                             ***\n";
    print "***  PROGRAM ABORTED  --- PROGRAM ABORTED  --- PROGRAM ABORTED  ***\n";
    print "***                                                             ***\n";
    print "*******************************************************************\n";
    print "*******************************************************************\n";
    print "*******************************************************************\n";
    print "\n";
    print "Return Code = $rc\n";
    print "\n";

    exit $rc;
}

1;

__END__

=head1 NAME

Acme::SList::Scheduler - Schedule batch files for the SList suite of programs

=head1 SYNOPSIS

    use Acme::SList::Scheduler;

    srun('prog1.pl');
    srun('prog2.pl');
    srun('prog3.pl');

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
