package Alien::Autotools;

use v5.10;
use strict;
use warnings FATAL => "all";
use utf8;
use Exporter "import";

our $VERSION = 'v0.0.6'; # VERSION
# ABSTRACT: Build and install the GNU build system.

our @EXPORT_OK = qw(autoconf_dir automake_dir libtool_dir);

sub autoconf_dir () { "##" }

sub automake_dir () { "##" }

sub libtool_dir () { "##" }

1;
=encoding utf8

=head1 NAME

Alien::Autotools - Build and install the GNU build system.

=head1 SYNOPSIS

    use Alien::Autotools qw(autoconf_dir);
    print autoconf_dir(), "\n";

=head1 DESCRIPTION

This module looks for minimum versions of the tools that make up the "GNU build
system": version 2.68 of C<autoconf>, version 1.11.0 of C<automake>, and version
2.4.0 of C<libtool>. For each tool that is not found or below the minimum
version, it is downloaded, compiled and installed it to the B<Alien-Autotools>
distribution's shared directory. Compilation can be made to happen regardless
of whether minimum versions are already found by setting the  environment
variable, C<COMPILE_ALIEN_AUTOTOOLS>, to a true value.

Tool source archives are downloaded from the official GNU FTP server,
L<ftp://ftp.gnu.org/>.


=head1 FUNCTIONS

=over

=item autoconf_dir()

=item automake_dir()

=item libtool_dir()

=back

Each function is exportable on request, takes no arguments, and returns the
absolute path to its respective executable binary's directory. The directory
will be in the shared directory if a given tool was installed, or the directory
path from C<$ENV{PATH}> otherwise.

=head1 AUTHOR

Richard Simões C<< <rsimoes AT cpan DOT org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2012 Richard Simões. This module is released under the terms of the
L<GNU Lesser General Public License v. 3.0|http://gnu.org/licenses/lgpl.html>
and may be modified and/or redistributed under the same or any compatible
license.
