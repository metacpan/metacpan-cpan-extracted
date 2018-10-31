#   @(#)$Id: Configure.pm,v 2018.2 2018/10/31 03:47:17 jleffler Exp $
#
#   Informix ESQL/C Support Routines for DBD::Informix
#   (Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31))
#
#   Copyright 1999      Jonathan Leffler
#   Copyright 2000      Informix Software Inc
#   Copyright 2002      IBM
#   Copyright 2003-2018 Jonathan Leffler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

#TABSTOP=4

# This file defines the following subs, which are used by both
# Makefile.PL and BugReport.
# -- find_informixdir_and_esql
# -- get_esqlc_version
# -- map_informix_lib_names
# It also defines the DBI and Perl minimum and reference versions,
# centralizing this information.  It is used by Makefile.PL and
# setmincur.pl (and the values end up in various bits of documentation).

{
    package DBD::Informix::Configure;

    use strict;
    use warnings;
    use vars qw( @ISA @EXPORT $VERSION );
    use vars qw( $DBI_MINVERSION $DBI_REFVERSION );
    use vars qw( $PERL_MINVERSION $PERL_REFVERSION );

    require Exporter;

    @ISA = qw(Exporter);
    @EXPORT = qw(find_informixdir_and_esql get_esqlc_version map_informix_lib_names);

    # Minimum and reference versions of DBI and Perl
    $DBI_MINVERSION = "1.607";
    $DBI_REFVERSION = "1.642";
    $PERL_MINVERSION = "5.008001";
    $PERL_REFVERSION = "5.026002";

    $VERSION = "2018.1031";

    # Fettle version for DBD::Informix development
    $VERSION = "0.97002" if ($VERSION =~ m%[:]VERSION[:]%);

    use Config;
    use DBI;

    # Locate $INFORMIXDIR and the ESQL/C compiler
    sub find_informixdir_and_esql
    {
        my ($NTConfiguration) = @_;
        my ($esql, $ID);
        if ($NTConfiguration)
        {
            # NT configuration
            # Tested for Config: archname='MSWin32' osname='MSWin32' osvers='4.0'
            my ($p);
            # Trying to find ESQL (and determining INFORMIXDIR too)
            foreach $p (split( /;/, $ENV{PATH}))
            {
                if (-x "$p/ESQL.EXE")
                {
                    # HUMS: \\ needed, because string goes into Makefile (via postamble)
                    $esql = "$p\\ESQL.EXE";
                    # HUMS: \\ necessary because string comes from ENV
                    $p  =~ s%[/\\]BIN%%i;
                    $ID = $p;
                    last;
                }
            }
            &did_not_read('No executable ESQL/C compiler found in $PATH')
                unless defined $esql;
            if ($esql =~ /\s/o)
            {
                warn "Path to ESQL/C compiler ($esql) contains white space";
                if (defined($ENV{INFORMIXDIR}))
                {
                    $ID = $ENV{INFORMIXDIR};
                    die 'Value of %INFORMIXDIR% ', "($ID) also contains spaces"
                        if ($ID =~ /\s/o);
                    my $p = "$ID/BIN/";
                    if (-x "$p/ESQL.EXE")
                    {
                        warn 'Also found ESQL/C compiler via %INFORMIXDIR% - without spaces';
                        $esql = "$p\\ESQL.EXE";
                    }
                }
            }
        }
        else
        {
            # Unix configuration
            $ID = $ENV{INFORMIXDIR};
            &did_not_read('$INFORMIXDIR is not set') unless ($ID);
            $esql = $ENV{ESQL};
            $esql = "esql" unless $esql;
            if ($esql =~ m%/%)
            {
                # ESQL/C program specified with path name
                &did_not_read("No executable ESQL/C compiler $esql")
                    unless (-x $esql);
            }
            else
            {
                # ESQL/C program specified without any path name
                &did_not_read("No executable ESQL/C compiler $ID/bin/$esql")
                    unless (-x "$ID/bin/$esql");
            }
            # Allow for $INFORMIXDIR = "/opt/informix/ids1170+csdk350".
            # Without the \Q...\E notation, the metacharacter '+' is active.
            # Reported by Julian Bridle <julian.bridle@pacepetroleum.com>
            &did_not_read('$INFORMIXDIR/bin is not in $PATH')
                unless ($ENV{PATH} =~ m%:\Q$ID\E/bin:% ||
                        $ENV{PATH} =~ m%^\Q$ID\E/bin:% ||
                        $ENV{PATH} =~ m%:\Q$ID\E/bin$%);
        }
        print "Using INFORMIXDIR=$ID and ESQL/C compiler $esql\n";
        return $ID, $esql;
    }

    # --- Find out which version of Informix ESQL/C by running 'esql -V'
    # NB: Argument should be name of esql program which can be executed.
    #     The checks for Unix in find_informixdir_and_esql should be OK.
    #     Allow for version 10.00 and later -- still hypothetical but...
    sub get_esqlc_version
    {
        my ($esql) = @_;
        my ($infv, $vers);

        open(ESQL, "$esql -V|") || die;
        # Read all the input to avoid Broken Pipe messages, and to avoid
        # problems with RedHat 9 wittering about the ESQL/C compiler being
        # an "Incorrectly built binary which accesses errno, ...".  Last
        # version line wins!  Jay Hannah <jhannah@omnihotels.com> gets the
        # credit for reporting the RedHat 9 problem.
        while (<ESQL>)
        {
            $infv = $_ if (m%Informix.* Version%i);
        }
        die "Failed to read any Informix version from 'esql -V'\n"
            unless defined $infv;
        close ESQL;

        chomp($infv);
        $infv =~ s/\s+$//;  # Delete trailing white space
        $infv =~ s/\s+/ /g; # Replace white space with single blanks
        $vers = $infv;
        # JL 2002-11-06:
        # CSDK 2.70 and earlier produces:
        #     INFORMIX-ESQL Version 9.51.UC1
        # CSDK 2.80 (and later) produces:
        #     IBM Informix CSDK Version 2.80, IBM Informix-ESQL Version 9.52.UC1
        # I4GL produces (note the extra spaces between Version and the number):
        #     IBM INFORMIX-4GL Version   7.31.UC3
        # (I4GL issue reported by Roderick Schertler <roderick@argon.com>
        # on 1999-07-25).  The s/// expression below picks up the I4GL or
        # ESQL/C version correctly from all three formats, relying on
        # case-insensitivity, the '-', and a string of alphanumerics to
        # identify the correct codewords prior to Version.  Fortunately,
        # the ESQL/C support code treats I4GL 7.31 the same as ESQL/C 9.x.
        $vers =~ s/.*INFORMIX-\w+ Version\s+(\d+[.]\d+).*/$1/i;
        die "Unexpected message from esql script -- $infv\n"
            unless ($vers =~ /^\d+[.]\d+$/);
        $vers =~ s/^([0-9])\./$1/;

        return $infv, $vers;
    }

    # If DBD_INFORMIX_RELOCATABLE_INFORMIXDIR is set, then leave Informix
    # library file specifications alone.  If it is not set, then hard-code the
    # Informix library path names.  This will simplify life on most platforms.
    # It also, more or less, follows the ideas espoused in 'Why LD_LIBRARY_PATH
    # is bad', by David Barr (http://www.visi.com/~barr/ldpath.html).
    #
    # This gets tricky.  We need to remove any library path arguments which
    # refer to $INFORMIXDIR, such as -L$INFORMIXDIR/lib, and map any references
    # to -lixlib into $INFORMIXDIR/lib/libixlib.so (unless that's libixlib.sl,
    # etc).  Further, you can write -L $INFORMIXDIR/lib and -l ixlib, so we
    # should be prepared to handle adjacent pairs of arguments on occasion.
    # NB: this version does not support spaces between -[lL] and the argument.
    # And heaven help us on systems where we are not using this script (eg
    # AIX 4.2).  Note, too, that this assumes you will use shared libraries
    # if they exist.  It needs to be rigged to avoid doing the mapping if
    # shared libaries are not wanted at all.

    sub map_informix_lib_names
    {
        my @i_libs = @_;
        my @o_libs = ();
        my $ixd = $ENV{INFORMIXDIR};
        my @ixlibdirs = ();

        foreach my $arg (@i_libs)
        {
            if ($arg =~ m%^-L$ixd/%o)
            {
                push @o_libs, $arg;
                $arg =~ s%-L%%;
                push @ixlibdirs, $arg;
            }
            elsif ($arg =~ m%^-l.+%o)
            {
                push @o_libs, &map_library($arg, @ixlibdirs);
            }
            else
            {
                push @o_libs, $arg;
            }
        }

        @o_libs;
    }

    # Non-exported sub to map a single library name if found in one
    # of the (Informix) library directories
    sub map_library
    {
        my ($lib, @libdirs) = @_;
        my $ar_ext = $Config{lib_ext};  # Regular, static libraries
        my $dl_ext = ".$Config{dlext}"; # Shared, dynamic libraries
        my $so_ext = ".$Config{so}";    # Shared, dynamic libraries
        my $stub = $lib;
        $stub =~ s/-l//;
        $stub = "lib$stub";
        foreach my $dir (@libdirs)
        {
            foreach my $ext ($so_ext, $dl_ext, $ar_ext)
            {
                my $path = "$dir/$stub$ext";
                if (-f $path)
                {
                    print "\t$0: map $lib to $path\n" if $ENV{DBD_INFORMIX_DEBUG_LIBMAP};
                    return $path;
                }
            }
        }
        return $lib;
    }

    # Tell the user that they did not read the README file and why
    # we think they didn't read it.
    sub did_not_read
    {
        die "\n*** You didn't read the README file!\n@_\n\n";
    }

    1;
}

__END__

=head1 NAME

DBD::Informix::Configure - Determining your ESQL/C Configuration

=head1 SYNOPSIS

use DBD::Informix::Configure;

=head1 DESCRIPTION

This module is used by Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31) in the build and bug reporting code.
You will seldom if ever have cause to use this module directly.

=head2 Using find_informixdir_and_esql

The function find_informixdir_and_esql returns both the value of
$INFORMIXDIR and the pathname of the ESQL/C compiler executable (a
script on Unix, an executable program on Windows NT).
The parameter should be true if the search is being done on Windows
NT; it is false if it is being done on a Unix system.

    my ($ixd, $esql) = find_informix_dir_and_esql($nt);

=head2 Using get_esqlc_version

Given the pathname of the ESQL/C compiler, this function returns
the ESQL/C version number as a string (such as 9.21.UC1) and as a
pure integer (such as 921).

    my ($infversion, $vernum) = &get_esqlc_version($esqlprog);

=head1 AUTHOR

Jonathan Leffler

=cut
