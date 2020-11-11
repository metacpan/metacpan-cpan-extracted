package App::Cpanx;
use 5.006;
use strict;
use warnings;

our $VERSION = "0.10";

1;

__END__

=head1 NAME

cpanx - A CPAN downloader script

=head1 SYNOPSIS

    cpanx [<options>] [<module>]

=head1 OPTIONS

    -h         displays this help text
    -l         look at module's contents in a shell
    -i         displays info about the module
    -f         displays info about what files would be installed
    -p         display perldoc for the module
    -u         uninstalls module
    -n         not interactive
    -S         do not use sudo
    -r         reinstall even if module is installed
    -T         do not run tests
    -d         dependencies only
    -m=<url>   sets the cpan mirror. default www.cpan.org
    -M         choose a cpan mirror
    -c         clean module cache
    -v         displays version

    -I=<loc>   sets install base path. e.g. /usr/local
    -L=<loc>   sets library install path. e.g. /Library/Perl/5.18
    -LL=<loc>  sets library install path including the architecture dependent dirs.
    -B=<loc>   sets the binary install path. e.g. ~/bin
    -SC=<loc>  sets the script install path. e.g. ~/scripts
    -M1=<loc>  sets the man1 install path e.g. /usr/share/man/man1
    -M3=<loc>  sets the man3 install path e.g. /usr/share/man/man3

    <module>   name of the module you want to install
               e.g. DBD::mysql or DBD-mysql-4.046.tar.gz or ./


=head1 DESCRIPTION

This program will download, display, and install modules (and their
dependencies) from CPAN. A public repository of user contributed
perl code.

This script is different to scripts like cpan and cpanm in that it
will show what it will do before it does anything. This is important
when a module has a lot of dependencies.

Just run something like "cpanx Module", it will download what it
needs, then display the dependencies in the order that they will
need to be installed to install the module.

Use the -i option, it will just show the information, and not ask
if you actually want to install it.

Use the -n option to set the script to not be interactive. It will
install without asking first.

Use the -S option to disable sudo during "make install".

If the module is up to date, you can use the -r option to reinstall.

If the tests aren't passing and you want to install anyway, use the
-T option.

Use the -d option to only install the dependencies, not the module
itself.

Use the -l option to open a shell in the module's directory and
then you can look around.

Use the -p option to open perldoc for the module.

The -f option can be used to display what files will be installed.
Use along with the -I, -L, -B, -SC, -M1, -M3 or the PERL_MM_OPT or
PERL_MB_OPT environment variables, to make sure you set the right
settings before you install.

You can uninstall the module with -u. It will show you what files
will be removed before actually removing them.

Set the CPAN mirror with the -m option. By default it uses
http://www.cpan.org.

Find the best CPAN mirror by running the command with -M. It will
ping all CPAN mirrors and show you the 10 servers with the best
time and let you choose which one you want.

Modules are cached and reused between calls, so you can look at the contents of the module in a shell, then get info about the install, then install the module and the module only downloads from cpan once. The cache is stored in ~/.cpanx.

This script has no dependencies. It uses the curl program to download.

This script is self contained. It's runnable if all you have is the one file.

=head1 EXAMPLE OUTPUT

    jacob@prism ~ $ cpanx Acme::MetaSyntactic
    curl http://www.cpan.org/modules/02packages.details.txt.gz -z /Users/jacob/.cpanx/02packages.details.txt.gz -R
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
				     Dload  Upload   Total   Spent    Left  Speed
    100 2028k  100 2028k    0     0   910k      0  0:00:02  0:00:02 --:--:--  911k
    curl http://www.cpan.org/modules/by-authors/id/B/BO/BOOK/Acme-MetaSyntactic-1.014.tar.gz -R
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
				     Dload  Upload   Total   Spent    Left  Speed
    100 56300  100 56300    0     0  70964      0 --:--:-- --:--:-- --:--:-- 70906
    tar -x -v -f ~/.cpanx/Acme-MetaSyntactic-1.014.tar.gz -C ~/.cpanx
    x Acme-MetaSyntactic-1.014/
    curl http://www.cpan.org/modules/by-authors/id/S/SB/SBURKE/Win32-Locale-0.04.tar.gz -R
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
				     Dload  Upload   Total   Spent    Left  Speed
    100  7598  100  7598    0     0  49572      0 --:--:-- --:--:-- --:--:-- 49660
    tar -x -v -f ~/.cpanx/Win32-Locale-0.04.tar.gz -C ~/.cpanx
    x Win32-Locale-0.04/
    /usr/bin/perl Makefile.PL
    Checking if your kit is complete...
    Looks good
    Generating a Unix-style Makefile
    Writing Makefile for Win32::Locale
    Writing MYMETA.yml and MYMETA.json

    Acme-MetaSyntactic 1.014 (not installed)
    Themed metasyntactic variables names
    By Philippe Bruhat (BooK) <book@cpan.org>
    Repository http://github.com/book/Acme-MetaSyntactic

    Dependencies:
    Carp 0 (have 1.29)
    Cwd 0 (have 3.40)
    ExtUtils::MakeMaker 0 (have 7.34)
    File::Basename 0 (have 2.84)
    File::Find 0 (have 1.23)
    File::Glob 0 (have 1.20_01)
    File::Spec 0 (have 3.40)
    File::Spec::Functions 0 (have 3.40)
    Getopt::Long 0 (have 2.49)
    IO::Handle 0 (have 1.34)
    IPC::Open3 0 (have 1.13)
    LWP::UserAgent 0 (have 6.15)
    List::Util 0 (have 1.50)
    Test::Builder::Module 0 (have 1.302136)
    Test::More 0 (have 1.302136)
    Win32::Locale 0 (not installed) *
	ExtUtils::MakeMaker 0 (have 7.34)
    base 0 (have 2.18)
    lib 0 (have 0.63)
    perl 5.006 (have 5.018002)
    strict 0 (have 1.07)
    warnings 0 (have 1.18)

    Install Order:
    Win32::Locale 0.04 (not installed)
    Acme::MetaSyntactic 1.014 (not installed)

    Do you want to install? [n]
    Not installing.

=head1 POSSIBLE ALTERNATIVE

If you don't want to install this module, you can use the existing cpan program to see what will actually be installed. Run "cpan" on the command line to enter its shell. Run "test Module", it will test the module and all it's dependencies, then run "is_tested", it will show the list of modules that will be installed. The format isn't as good as what would be shown by this program, but might be good enough.

=head1 METACPAN

L<https://metacpan.org/pod/App::Cpanx>

=head1 AUTHOR

Jacob Gelbman E<lt>gelbman@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Jacob Gelbman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

