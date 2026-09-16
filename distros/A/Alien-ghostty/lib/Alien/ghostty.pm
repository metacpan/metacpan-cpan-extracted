package Alien::ghostty;
use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Alien::ghostty - Find or build libghostty-vt, Ghostty's terminal emulation library

=head1 SYNOPSIS

In your F<Makefile.PL>:

    use ExtUtils::MakeMaker;
    use Alien::Base::Wrapper ();

    WriteMakefile(Alien::Base::Wrapper->new('Alien::ghostty')->mm_args2(
        NAME => 'My::XS',
        ...
    ));

In your XS code:

    #include <ghostty/vt.h>

=head1 DESCRIPTION

This distribution provides C<libghostty-vt>, the terminal emulation core of
the L<Ghostty|https://ghostty.org/> terminal: a VT parser and terminal state
machine with formatters for plain text, VT and HTML. See L<Term::Ghostty> for
a Perl interface.

Ghostty has no tagged release of this API yet, so the library is built from
Ghostty's latest development snapshot, its C<tip> release. That API still
changes, so two installs made at different times can provide different
versions of it. An installed C<libghostty-vt> is used only when
C<ALIEN_INSTALL_TYPE=system> is set, and only if it provides the API that
L<Term::Ghostty> needs.

The build installs a static library for XS modules to link against, so they
keep working if this module is later upgraded; the shared library is
installed as well, in a separate directory, for FFI users.

=head1 METHODS

All methods are inherited from L<Alien::Base>. C<version> returns the
C<libghostty-vt> version; for a built library it carries the Ghostty commit,
for example C<0.1.0-dev+661e1e7>, and
C<< Alien::ghostty->runtime_prop->{ghostty_version} >> is the Ghostty source
version.

=head1 BUILD REQUIREMENTS

Building needs L<Zig|https://ziglang.org/> 0.16. A C<zig> of that series on
C<PATH>, or named by C<ALIEN_GHOSTTY_ZIG>, is used; otherwise the official
binary is downloaded from ziglang.org and checked against a pinned SHA-256.
Binaries are available for x86_64 and aarch64 Linux, macOS, FreeBSD, NetBSD
and OpenBSD; unpacking one needs C<tar> with xz support, or C<xz>.

The Ghostty source is downloaded from the C<tip> release on GitHub, and Zig
downloads the packages the build depends on from deps.files.ghostty.org and
codeberg.org. The build takes a few minutes and about 1 GB of disk; after a
successful build the downloaded compiler and the build cache are removed, and
the installed library takes about 30 MB.

Windows is not supported.

=head1 ENVIRONMENT

=over 4

=item ALIEN_INSTALL_TYPE

C<system> to use an installed library instead of building one. See
L<Alien::Build/ENVIRONMENT>.

=item ALIEN_GHOSTTY_ZIG

Absolute path to the C<zig> executable to build with.

=item ALIEN_GHOSTTY_SOURCE

An absolute path or URL of a libghostty-vt source tarball to build instead of
the current C<tip>, for example to keep a known snapshot.

=item ALIEN_INSTALL_NETWORK

Set to 0 to forbid downloads. A build then needs a local C<zig> and
C<ALIEN_GHOSTTY_SOURCE> pointing to a local tarball that already contains
the Zig packages (in F<zig-pkg/>, as left by a previous build).

=back

They are read by both C<perl Makefile.PL> and C<make>, so export them.

=head1 SEE ALSO

L<Term::Ghostty>, L<Alien::Base>, L<Alien::Build>,
L<Ghostty|https://ghostty.org/>

=head1 AUTHOR

vividsnow

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

libghostty-vt is copyright Mitchell Hashimoto and the Ghostty contributors
and is distributed under the MIT license. It includes third-party code, such
as simdutf, Highway and Wuffs, under their own permissive licenses; see its
source for the texts.

=cut
