package Alt::ExtUtils::PkgConfig::PLICEASE;

use strict;
use warnings;

# ABSTRACT: Simplistic interface to pkgconf (like pkg-config)
our $VERSION = '1.15'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alt::ExtUtils::PkgConfig::PLICEASE - Simplistic interface to pkgconf (like pkg-config)

=head1 VERSION

version 1.15

=head1 SYNOPSIS

 env PERL_ALT_INSTALL=OVERWRITE cpanm Alt::ExtUtils::PkgConfig::PLICEASE

=head1 DESCRIPTION

This distribution provides an alternative implementation of L<ExtUtils::PkgConfig> which uses L<PkgConfig::LibPkgConf> 
(itself using C<libpkgconf> which is the C library interface to C<pkgconf>) instead of C<pkg-config>.  It is unlikely
to replace the original module, but is intended to gather reliability statistics for L<PkgConfig::LibPkgConf> as compared
with the original version and C<pkg-config>.

That being said, all effort has been made to make this module correct, and if you are in an environment where you have
C<libpkgconf> but not C<pkg-config>, then this module may be of use to you.  In order to get it to install you MUST set
the environment variable C<PERL_ALT_INSTALL> to C<OVERWRITE>.  For further rationale and details on this and other
"Alternative" implementation modules see L<Alt>.

Here are some differences between my version and the original:

=over 4

=item no forking

Because this implementation uses a library instead of a program to query the C<.pc> file database, this version does
not need to use C<fork> or C<system>.

=item no C<AUTOLOAD>

This version doesn't use C<AUTOLOAD>.  As a result, dashed versions of the methods (C<cflags-only-I>) are not supported.
You must use the underscore methods (C<cflags_only_I>).  As the dashed versions were probably unintentional that is
probably okay.

=back

=head1 SEE ALSO

=over 4

=item L<Alt>

=item L<ExtUtils::PkgConfig>

=item L<PkgConfig>

=item L<PkgConfig::LibPkgConf>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Graham Ollis.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
