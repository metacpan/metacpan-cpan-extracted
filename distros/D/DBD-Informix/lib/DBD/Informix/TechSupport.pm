#   @(#)$Id: TechSupport.pm,v 2015.2 2015/08/27 02:28:24 jleffler Exp $
#
#   Technical Support Tools for Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
#
#   Copyright 2000-01 Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2004-15 Jonathan Leffler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

{
    package DBD::Informix::TechSupport;

    use strict;
    use warnings;
    use vars qw( @ISA @EXPORT $VERSION );
    require Exporter;

    @ISA = qw(Exporter);
    @EXPORT = qw(print_versions bug_report it_works);

    $VERSION = "2015.1101";
    $VERSION = "0.97002" if ($VERSION =~ m%[:]VERSION[:]%);

    use Config;
    use DBI;
    use DBD::Informix::Configure;
    use DBD::Informix::TestHarness;

    # Print version numbers for Perl, DBI, DBD::Informix or ESQL/C
    sub print_versions
    {
        my ($items) = @_;
        $items = "Perl DBI DBD::Informix ESQL/C" if ! defined($items) || $items eq "";

        my $drh = DBI->install_driver('Informix');
        print "Perl Version $]\n" if ($items =~ m%\bperl\b%i);
        print "DBI Version $DBI::VERSION\n" if ($items =~ m%\bDBI\b%i);
        print "DBD::Informix Version $drh->{Version}\n" if ($items =~ m%\bDBD::Informix\b%i);
        print "$drh->{ix_ProductName}\n" if ($items =~ m%\bESQL/C\b%i);
    }

    # Produce a Bug Report
    # * By default (no arguments), produces just the most basic bug
    #   reporting info - versions and platform and environment.
    # * If given an argument A or B or C, produces the info for that
    #   type of bug report.
    # * If given an argument D and one or more specific test names,
    #   produces the info for a type D bug report.
    # * It is not unreasonable to build DBD::Informix using:
    #   perl BugReport 2>&1 | tee bugreport.out

    sub bug_report
    {
        my ($opt, @tests) = @_;

        $| = 1;

        # Simulate (Solaris dialect of) 'id' program in Perl.
        my ($id, $name, $gid, @rgrps, $egid, @egrps, $pad);
        $name = getpwuid($<);
        $id = "uid=$<($name)";
        @rgrps = split / /, $(;
        $gid = $rgrps[0];
        shift @rgrps;
        $name = getgrgid($gid);
        $id .= " gid=$gid($name)";
        if ($< != $>)
        {
            $name = getpwuid($>);
            $id .= " euid=$>($name)";
        }
        @egrps = split / /, $);
        $egid = $egrps[0];
        if ($egid != $gid)
        {
            $name = getgrgid($egid);
            $id .= " egid=$egid($name)";
        }
        $pad = " groups=";
        foreach $gid (@rgrps)
        {
            $name = getgrgid($gid);
            $id .= "$pad$gid($name)";
            $pad = ",";
        }

        system qq{
            echo "Command:   $0 $opt @tests"
            echo "Date:      `date`"
            echo "Machine:   `uname -n` (`uname -s -r`)"
            echo "User:      $id"
            echo "Directory: `pwd`"
            echo "Umask:     `umask`"
            echo "Terminal:  `tty 2>/dev/null`"
            };

        print "\n#\n# Perl Version\n";
        system("$^X -V");

        print "\n#\n# Informix Version\n";
        my ($INFORMIXDIR, $ESQLC) = &find_informixdir_and_esql();
        my ($esqlversion, $esqlvernum) = &get_esqlc_version($ESQLC);
        print "INFORMIXDIR = $INFORMIXDIR\n";
        print "ESQLC = $ESQLC\n";
        print "Version = $esqlversion\n";

        my $dbmsversion;
        $dbmsversion = `$INFORMIXDIR/bin/onstat   -V 2>/dev/null`;
        $dbmsversion = `$INFORMIXDIR/bin/tbstat   -V 2>/dev/null` unless $dbmsversion;
        $dbmsversion = `$INFORMIXDIR/bin/dbaccess -V 2>/dev/null` unless $dbmsversion;
        $dbmsversion = `$INFORMIXDIR/lib/sqlturbo -V 2>/dev/null` unless $dbmsversion;
        $dbmsversion = `$INFORMIXDIR/lib/sqlexec  -V 2>/dev/null` unless $dbmsversion;
        $dbmsversion = "*** indeterminate ***" unless $dbmsversion;

        chomp $dbmsversion;
        $dbmsversion =~ s/Software Serial Number.*//m;
        print "DBMS Version = $dbmsversion\n";

        use vars qw($db1 $db2 $server1 $server2 $hosts);
        $db1 = $ENV{DBD_INFORMIX_DATABASE};
        $db2 = $ENV{DBD_INFORMIX_DATABASE2};
        if (defined $db1) { $server1 = ($db1 =~ s/.*@//); } else { $server1 = $ENV{INFORMIXSERVER}; }
        if (defined $db2) { $server2 = ($db2 =~ s/.*@//); } else { $server2 = $ENV{INFORMIXSERVER}; }
        $hosts = $ENV{INFORMIXSQLHOSTS};
        $hosts = "$ENV{INFORMIXDIR}/etc/sqlhosts" unless defined $hosts;
        if (open(HOSTS, "<$hosts"))
        {
            print "Informix Server Entries in sqlhosts file ($hosts)\n";
            while (<HOSTS>)
            {
                print if m /^($server1|$server2)\s/;
            }
            close HOSTS;
        }
        else
        {
            print "**** Unable to read sqlhosts file $hosts\n";
        }

        # Print environment, not compromising passwords.
        use vars qw($var $val);
        print "\n#\n# Sorted Environment\n";
        for $var (sort keys %ENV)
        {
            $val = $ENV{$var};
            $val = "XXXXXXXX" if ($var =~ m/^DBD_INFORMIX_PASSWORD[12]?$/o);
            print "$var=$val\n";
        }
        print "\n# End of Configuration Report\n";

        return 1 unless ($opt);

        # Handle bug reports for bug classes A through D.
        if ($opt =~ m/^-?[abcdABCD]$/)
        {
            print "\n#\n# Redoing configuration\n";
            execute_command("[ ! -f Makefile ] || make realclean", "failed on preliminary cleanup");
            execute_command("rm -f esql esqlvrsn.h esqlinfo.h",    "failed on preliminary cleanup");
            execute_command("$^X Makefile.PL", "running on configuration");
            if ($opt =~ m/^[bcdBCD]$/)
            {
                print "\n#\n# Redoing build\n";
                execute_command("make", "failed on build");
                if ($opt =~ m/^[cdCD]$/)
                {
                    print "\n#\n# Redoing general testing\n";
                    execute_command("make test", "failed on general testing");
                    if ($opt =~ m/^[dD]$/ && $#tests >= 0)
                    {
                        print "\n#\n# Doing selective testing\n";
                        execute_command("sh test.one.sh @tests", "failed on selective tests");
                        if ($#tests == 0)
                        {
                            print "\n#\n# Rerunning single test with debug fully enabled\n";
                            # JL 2000-02-08: This should work:
                            #execute_command("PERL_DBI_DEBUG=9 sh test.one.sh @tests", "failed on selective tests");
                            # ...but there is a bug in Perl 5.005_03...
                            #
                            # From: Doug Wilson <dougw@safeguard.net>
                            # To: Jonathan Leffler <jleffler@informix.com>
                            # Subject: FW: [ID 20000121.005] System command starting with environment
                            #       [PATCH for tests] DBD::Informix BugReport bug
                            # Date: Tue, 8 Feb 2000 09:43:02 -0800
                            #
                            # Thought you might like to know, the bug in your BugReport script is
                            # really a bug in perl (I thought it was just my system), and happens
                            # whenever you do a system() call that starts with a 'VAR=VALUE' where
                            # the VAR contains a digit or underscore character. I submitted the
                            # bug and got this patch which appears to work:
                            #
                            # From: Dominic Dunlop [mailto:domo@computer.org]
                            # Sent: Monday, January 24, 2000 1:15 AM
                            # To: perl5-porters@perl.org
                            # Cc: Ilya Zakharevich; dougw@safeguard.net
                            # Subject: Re: [ID 20000121.005] System command starting with
                            #       environment [PATCH for tests]
                            #
                            # [...a patch followed...]
                            #
                            # When enough time has elapsed and/or the Perl version requirements for
                            # DBD::Informix are sufficiently stringent for the fix to be universal,
                            # you can replace the workaround below with the code above.
                            # JL 2002-12-09: Replace PERL_DBI_DEBUG with DBI_TRACE.
                            execute_command("sh -c 'DBI_TRACE=9 sh test.one.sh @tests'", "failed on selective tests");
                        }
                    }
                }
            }
            print "\n# End of Bug Report\n";
        }
        else
        {
            print STDERR "Usage: $0 [A|B|C|D] [test cases...]\n";
            return 0;
        }

        1;
    }

    # Execute a command, logging it if $sx is set, and dying with given message
    # if command fails.
    sub execute_command
    {
        my ($cmd, $msg) = @_;
        print "+ $cmd\n";
        warn $msg unless system($cmd) == 0;
    }


    # Print a report that the installation works
    sub it_works
    {
        my ($sec,$min,$hour,$mday,$mon,$year) = gmtime(time);
        my ($date) = sprintf "%04d-%02d-%02d", $year + 1900, $mon + 1, $mday;
        my ($uname,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell) = getpwuid $>;

        #perl -MConfig -e 'for $key (sort keys %Config) { print "$key = $Config{$key}\n"; }'

        # Try to generate an email name and address
        my ($who) = "$uname\@$Config{myhostname}$Config{mydomain}";
        if ($comment)
        {
            $who = "$comment <$who>";
        }
        elsif ($gcos)
        {
            $who = "$gcos <$who>";
        }

        my ($dbh) = &connect_to_primary(0);

        my (%tags);

        # If you significantly change this list of tags, then change the version
        # number in the WORKING_VERSION open tag.

        $tags{DBD_INFORMIX} = "$dbh->{Driver}->{Version}";
        $tags{DBI} = "$DBI::VERSION";
        $tags{INFORMIX_ESQLC} = "$dbh->{ix_ProductName}";
        my ($server) = ($dbh->{ix_InformixOnLine} == 0) ? "SE"
                     : ($dbh->{ix_ServerVersion} < 600) ? "OnLine"
                     : ($dbh->{ix_ServerVersion} < 730) ? "ODS"
                     : ($dbh->{ix_ServerVersion} < 800) ? "IDS"
                     : ($dbh->{ix_ServerVersion} < 900) ? "XPS"
                     : ($dbh->{ix_ServerVersion} < 920) ? "IUS"
                     :                                    "IDS"
                     ;
        $tags{INFORMIX_SERVER} = sprintf "%.2f (%s)", ($dbh->{ix_ServerVersion}/100),
                                        $server;
        $tags{PERL} = "$] @Config{qw(archname dlsrc)}";
        $tags{SYSTEM} = "@Config{qw(myuname)}";
        $tags{SYS_COMPILER} = "@Config{qw(cc gccversion)}";
        $tags{SYS_LOADER} = "$Config{ld}";
        $tags{WHEN} = "$date";
        $tags{WHO} = "$who";
        $tags{Z_NOTES} = "Optional Notes";

        my ($keylen) = (0);
        my ($key, $tag);

        # Determine longest key
        foreach $key (keys %tags)
        {
            $keylen = length($key) if (length($key) > $keylen);
        }

        my ($fmt) = "    <%s>%s %s </%s>\n";

        print "<WORKING_VERSION VERSION=\"1.00\">\n";
        for $key (sort keys %tags)
        {
            printf $fmt, $key, " " x ($keylen - length($key)), $tags{$key}, $key;
        }
        print "</WORKING_VERSION>\n";

        $dbh->disconnect;
    }

    1;
}

__END__

=head1 NAME

DBD::Informix::TechSupport - Obtaining Technical Support for DBD::Informix

=head1 SYNOPSIS

use DBD::Informix::TechSupport;

=head1 DESCRIPTION

This document describes how to obtain technical support for
Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
(which is also known as DBD::Informix).
It also describes how to use the Perl module to report information to
any of technical support channels.

=head1 IBM INFORMIX TECHNICAL SUPPORT

Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
is not officially supported by IBM Informix Technical Support.
If you are using a supported configuration, they will route problem
reports to the maintenance team listed below.

This release is supported by Jonathan Leffler <dbd.informix@gmail.com>.
You may also report your bugs via the CPAN resolution tracking system:

    http://rt.cpan.org/

Such bug reports can be sent by email to <bug-DBD-Informix@rt.cpan.org>
they also get sent to dbd.informix@gmail.com, etc.

Under normal circumstances, you will receive a response (but not
necessarily a solution) by the end of the next working day (California
time, California holiday schedule).

=head1 OTHER SUPPORT

The mailing list for Perl DBI and DBD::Informix is dbi-users@perl.org.
For information on how to subscribe to (and unsubscribe from) the dbi-users
mailing list, send a message to dbi-users-help@perl.org.
You could also consider using the news groups comp.lang.perl.modules (for
Perl and DBI) and comp.databases.informix (for DBD::Informix).
These channels may provide quicker support, especially over holiday
weekends.

=head1 CONFIGURATIONS SUPPORTED

We normally only support Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
if you are using certain supported versions of ESQL/C or Client SDK:

=over 2

=item *

Client SDK Version 3.00 (ESQL/C 3.00) or later

=back

You may use Perl Version 5.008001, but you should ideally be using Perl
Version 5.022000 or a later, stable version of Perl.

You must be using DBI Version 1.607 or later.  You should ideally
be using DBI Version 1.634 or later.

If you are using some other version of ESQL/C, or some other version
of Perl or DBI, you must use the other support channels documented
above.

=head1 OTHER CONFIGURATIONS WHICH PROBABLY WORK

Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01) is believed to work with all versions of ESQL/C and ClientSDK
from ESQL/C 5.00.UC1 upwards.
However, you may run into problems with shared libraries if you use
versions of ESQL/C which are not explicitly supported.
This is sometimes because of problems with the way ESQL/C handles
either its own shared libraries or other (system) libraries.
If you run into such problems, you can consider editing the library
list (see the fix_hpux_syslibs and fix_aix_netstub functions in
Makefile.PL for illustrations), or you can build a statically linked
Perl executable (see Notes/static.build).

At various times, DBD::Informix has been tested with both OnLine and
SE at most versions from 5.00 upwards.

DBD::Informix will probably work with most versions of Perl from
5.008001 upwards (subject to using an appropriate version of DBI), but
you should aim to use 5.022000 until there is a later stable version available.

DBD::Informix currently requires DBI version 1.607; it will not accept earlier
versions.  You should be using at least DBI version 1.634.

=head1 USING THE DBD::Informix::TechSupport Module

The script InformixTechSupport illustrates how to use the various
functions described here.

=head2 Using bug_report

The Notes/bug.report file describes in detail the various classes of
bug report (A, B, C or D).
You specify the bug class and optionally (for a class D bug) a list of
tests to run.

    bug_report("A");

    bug_report("D", @test_list);

You should trap both the standard output and standard error output
into a file and use that as the basis of your bug report.
You will also need to describe the symptoms of any detailed failure
you have if the tests pass.
Although you would often use the distributed tests, you can substitute
your own test provided you include the source code with the bug report
and it is cribbed from one the distributed tests.

The bug_report function reconfigures DBD::Informix (all classes), then
builds it (classes B, C, D) and tests it (classes C, D).

=head2 Using it_works

This generates the information needed for a report that you have managed
to get Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01) working.

    it_works;

=head2 Using print_versions

This function is called with a string containing the names of the
items for which you need the version.

    print_versions("Perl DBI DBD::Informix ESQL/C");

The valid items are:

=over 2

=item *

Perl

=item *

DBI

=item *

DBD::Informix

=item *

ESQL/C

=back

=head1 AUTHOR

Jonathan Leffler

=cut
