package App::Cpanx;
use 5.006;
use strict;
use warnings;

our $VERSION = "0.06";

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
    -m=<url>   sets the cpan mirror
    -M         choose a cpan mirror. default www.cpan.org
    -c         clean module cache

    -I=<loc>   sets install base path. e.g. /usr/local
    -L=<loc>   sets library install path. e.g. /Library/Perl/5.18
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

