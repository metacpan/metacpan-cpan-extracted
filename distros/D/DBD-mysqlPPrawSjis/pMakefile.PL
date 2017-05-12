######################################################################
#
# pMakefile.PL - Makefile.PL of Perl Poor Tools
#
# Copyright (c) 2008, 2009, 2010, 2011 INABA Hitoshi <ina@cpan.org>
######################################################################

use strict;

# make pmake.bat
if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
    open(FH_MAKEBAT, '>pmake.bat') || die "Can't open file: pmake.bat\n";
    print FH_MAKEBAT <<'END';
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14
undef @rem;
END
    print FH_MAKEBAT <DATA>;
    close FH_MAKEBAT;
}

# make pmake
else {
    open(FH_MAKEBAT, '>pmake') || die "Can't open file: pmake\n";
    print FH_MAKEBAT '#!', &which($^X), "\n";
    print FH_MAKEBAT <DATA>;
    close FH_MAKEBAT;
    chmod 0755, 'pmake';
}

sub which {
    if ($_[0] =~ m#\A / #oxms) {
        return $_[0];
    }
    else {
        for my $path (split(/:/,$ENV{'PATH'})) {
            if (-e qq{$path/$_[0]}) {
                return qq{$path/$_[0]};
            }
        }
        return $_[0];
    }
}

__END__
######################################################################
#
# pmake - make of Perl Poor Tools
#
# Copyright (c) 2008, 2009, 2010 INABA Hitoshi <ina@cpan.org>
######################################################################

use strict;
use File::Path;
use File::Copy;
use File::Basename;
use Test::Harness;

unless (@ARGV) {
    if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
        die <<END;

usage: pmake
usage: pmake test
usage: pmake install
usage: pmake dist
usage: pmake ptar.bat
usage: pmake pwget.bat

END
    }
    else {
        die <<END;

usage: pmake
usage: pmake test
usage: pmake install
usage: pmake dist
usage: pmake ptar
usage: pmake pwget

END
    }
}

# get file list
open(FH_MANIFEST, 'MANIFEST');
chomp(my @file = <FH_MANIFEST>);
close FH_MANIFEST;

for my $target (@ARGV) {
    if ($target eq 'test') {
        my @test = grep m{ \A (?: test\.pl | t/.+\.t ) \z }xmsi, @file;
        runtests(@test);
    }
    elsif ($target eq 'install') {

        # install *.pm files to /Perl/site/lib
        my $perl_site_lib = '';
        if (($perl_site_lib) = grep(m{site_perl}xms, reverse @INC)) {
        }
        elsif (($perl_site_lib) = grep(m{site}xms, reverse @INC)) {
        }
        if ($perl_site_lib ne '') {
            for (grep m/ \. pm \z /xmsi, @file) {
                if (m#^(.+)/#) {
                    print STDERR "copy $_ $perl_site_lib/$1\n";
                    mkpath("$perl_site_lib/$1", 0, 0777) unless -d "$perl_site_lib/$1";
                    copy($_, "$perl_site_lib/$1");
                }
                else {
                    print STDERR "copy $_ $perl_site_lib\n";
                    copy($_, $perl_site_lib);
                }
            }
        }

        # install *.pl, *.bat, *.exe, and *.com files to /Perl/bin
        my($perl_bin) = $^X =~ /^(.*)\\[^\\]*$/;
        for (grep m/ \. (?: pl | bat | exe | com ) \z /xmsi, @file) {
            next if m/(?: Makefile | pMakefile | test ) \.pl  $/xmsi;
            next if m/(?: pmake | ptar )                \.bat $/xmsi;
            if (m#^(.+)/#) {
                print STDERR "copy $_ $perl_bin/$1\n";
                mkpath("$perl_bin/$1", 0, 0777) unless -d "$perl_bin/$1";
                copy($_, "$perl_bin/$1");
            }
            else {
                print STDERR "copy $_ $perl_bin\n";
                copy($_, $perl_bin);
            }
        }
    }
    elsif ($target eq 'dist') {

        # make work directory
        my($changes) = grep(/^Changes$/i,@file);
        open(FH_CHANGES, $changes) || die "Can't open file: $changes\n";
        my $version = 0;
        while (<FH_CHANGES>) {
            if (/^(\d+\.\d+(\.\d+\.\d+)*)/) {
                if ($1 > $version) {
                    $version = $1;
                }
            }
        }
        close FH_CHANGES;
        my $dirname  = dirname($file[0]);
        my $basename = basename($file[0], '.pm','.pl','.bat');
        my $tardir;
        if ($dirname eq 'lib') {
            $tardir = "$basename-$version";
        }
        elsif ($dirname ne '.') {
            $dirname =~ tr#/#-#;
            $tardir = "$dirname-$basename-$version";
        }
        else {
            $tardir = "$basename-$version";
        }
        rmtree($tardir,0,0);

        # rewrite META.yml file
        if (my($metayml) = grep(/^META\.yml$/i,@file)) {
            if (open(FH_METAYML, $metayml)) {
                $_ = join('',<FH_METAYML>);
                close FH_METAYML;
                if (open(FH_METAYML, ">$metayml")) {
                    s/^(version:\s*)\d+\.\d+(\.\d+\.\d+)*/$1$version/m;
                    binmode FH_METAYML;
                    print FH_METAYML $_;
                    close FH_METAYML;
                }
            }
        }

        if ($^O =~ /solaris|linux/i) {
            system(qq{tar -cvf $tardir.tar $tardir});
            system(qq{gzip $tardir.tar});
        }
        else {
            eval q{
                use Compress::Zlib;
                use Archive::Tar;
            };

            # make *.tar file
            my $tar = Archive::Tar->new;
            for my $file (@file) {
                if (-e $file) {
                    mkpath(dirname("$tardir/$file"), 0, 0777);
                    print STDERR "copy $file $tardir/$file\n";
                    copy($file, "$tardir/$file");

#-----------------------------------------------------------------------------
# Sunday December 21, 2008 07:38 PM 
# Fixing world writable files in tarball before upload to CPAN [ #38127 ]
# http://use.perl.org/~bart/journal/38127 (dead link)
#-----------------------------------------------------------------------------
#                   $tar->add_files("$tardir/$file");
#-----------------------------------------------------------------------------
                    open(FH, $file) || die "Can't open file: $file\n";
                    binmode FH;
                    local $/ = undef; # slurp mode
                    my $data = <FH>;
                    close FH;
                    if ($file =~ m/\. (com|exe|bat|pl) \z/oxmsi) {
                        $tar->add_data("$tardir/$file", $data, {'mode' => 0775});
                    }
                    else {
                        $tar->add_data("$tardir/$file", $data, {'mode' => 0664});
                    }
#-----------------------------------------------------------------------------
                }
                else {
                    die "file: $file is not exists.\n";
                }
            }

            $tar->write("$tardir.tar");
            rmtree($tardir,0,0);

            # make *.tar.gz file
            my $gz = gzopen("$tardir.tar.gz", 'wb');
            open(FH_TAR, "$tardir.tar") || die "Can't open file: $tardir.tar\n";
            binmode FH_TAR;
            $gz->gzwrite(join('',<FH_TAR>));
            close FH_TAR;
            $gz->gzclose;
            unlink "$tardir.tar";
        }

        # P.565 Cleaning Up Your Environment
        # in Chapter 23: Security
        # of ISBN 0-596-00027-8 Programming Perl Third Edition.

        # local $ENV{'PATH'} = '.';
        local @ENV{qw(IFS CDPATH ENV BASH_ENV)};

        # untar test
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            system(qq{pmake.bat ptar.bat});
            system(qq{ptar.bat xzvf $tardir.tar.gz});
        }
        else {
            system(qq{./pmake ptar});
            system(qq{./ptar xzvf $tardir.tar.gz});
        }
    }
    elsif ($target =~ /^ptar(?:\.bat)?$/) {

        my $ptar = <<'PTAR_END';
######################################################################
#
# ptar - tar of Perl Poor Tools
#
# Copyright (c) 2008, 2009, 2010, 2011 INABA Hitoshi <ina@cpan.org>
######################################################################

use strict;

if ($ARGV[0] ne 'xzvf') {
    die <<END;

usage: ptar xzvf file1.tar.gz file2.tar.gz ...

** This ptar supports xzvf option only. **

e(x)tract
(z)ip-file
(v)erbose
(f)ile

END
}

for my $gzfile (grep m/\.tar\.gz$/xmsi, @ARGV) {

    if ($^O =~ /solaris|linux/i) {
        system(qq{gzip -cd $gzfile | tar -xvf -});
    }
    else {
        eval q{
            use Compress::Zlib;
            use Archive::Tar;
        };

        my $gz = gzopen($gzfile, 'rb');
        (my $tarfile = $gzfile) =~ s/\.gz$//xmsi;
        open(FH_TAR, ">$tarfile") || die "Can't open file: $tarfile\n";
        binmode FH_TAR;
        while ($gz->gzreadline(my $line)) {
            print FH_TAR $line;
        }
        $gz->gzclose;
        close FH_TAR;

        my $tar = Archive::Tar->new($tarfile,1);
        for my $file ($tar->list_files){
            if (-e $file) {
                print STDERR "skip $file is already exists.\n";
            }
            else {
                print STDERR "x $file\n";
                $tar->extract($file);
            }
        }
        unlink $tarfile;
    }
}

__END__
PTAR_END

        # make ptar.bat
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            open(FH_TARBAT, '>ptar.bat') || die "Can't open file: ptar.bat\n";
            print FH_TARBAT <<'END';
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14
undef @rem;
END
            print FH_TARBAT $ptar;
            print FH_TARBAT ":endofperl\n";
            close FH_TARBAT;
        }

        # make ptar
        else {
            open(FH_TARBAT, '>ptar') || die "Can't open file: ptar\n";
            print FH_TARBAT '#!', &which($^X), "\n";
            print FH_TARBAT $ptar;
            close FH_TARBAT;
            chmod 0755, 'ptar';
        }
    }
    elsif ($target =~ /^pwget(?:\.bat)?$/) {

        my $pwget = <<'PWGET_END';
######################################################################
#
# pwget - wget of Perl Poor Tools
#
# Copyright (c) 2011 INABA Hitoshi <ina@cpan.org>
######################################################################

use Socket;

unless (@ARGV) {
    die <<END;

usage: pwget http://www.foo.com/bar/baz.tar.gz

END
}

my $url = $ARGV[0];
my $forward = 3;
while ($forward-- > 0) {
    my($hostname) = $url =~ m#http://([^/]+)/#;
    my $port = ($hostname =~ s/:([0-9]+)//) ? $1 : 80;

    socket(SOCKET,PF_INET,SOCK_STREAM,getprotobyname('tcp')) || die "Can't open TCP/IP socket.\n";
    connect(SOCKET,sockaddr_in($port,inet_aton($hostname)))  || die "Can't connect to $hostname:$port.\n";
    select SOCKET;
    $| = 1;
    select STDOUT;

    my $request = <<END;
GET $url HTTP/1.0
Accept: */*
User-Agent: $0

END
    $request =~ s/\n/\r\n/g;
    print SOCKET $request;

    my($head,$body) = split(/\r\n\r\n/,join('',<SOCKET>),2);
    close SOCKET;

    if ($head =~ m#^Location: (\S+)#ms) {
        $url = $1;
        print STDERR "Location: $url\n";
        next;
    }

    my($file) = $ARGV[0] =~ m#([^/]+)$#;
    open(FILE,">$file") || die "Can't open file: $file\n";
    binmode FILE;
    print FILE $body;
    close FILE;
    if ($head =~ m#Content-Length: ([0-9]+)#ms) {
        if (-s $file == $1) {
            print STDERR "ok - $file\n";
        }
        else {
            print STDERR "not ok - $file\n";
            unlink $file;
        }
    }
    last;
}

__END__
PWGET_END

        # make pwget.bat
        if ($^O =~ /\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
            open(FH_WGETBAT, '>pwget.bat') || die "Can't open file: pwget.bat\n";
            print FH_WGETBAT <<'END';
@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#!perl
#line 14
undef @rem;
END
            print FH_WGETBAT $pwget;
            print FH_WGETBAT ":endofperl\n";
            close FH_WGETBAT;
        }

        # make pwget
        else {
            open(FH_WGETBAT, '>pwget') || die "Can't open file: pwget\n";
            print FH_WGETBAT '#!', &which($^X), "\n";
            print FH_WGETBAT $pwget;
            close FH_WGETBAT;
            chmod 0755, 'pwget';
        }
    }
    else {
        warn "unknown target: $target.\n";
    }
}

sub which {
    if ($_[0] =~ m#\A / #oxms) {
        return $_[0];
    }
    else {
        for my $path (split(/:/,$ENV{'PATH'})) {
            if (-e qq{$path/$_[0]}) {
                return qq{$path/$_[0]};
            }
        }
        return $_[0];
    }
}

__END__
:endofperl
