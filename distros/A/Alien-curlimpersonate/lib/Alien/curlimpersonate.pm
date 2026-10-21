package Alien::curlimpersonate;
use v5.10; use strict; use warnings;
use parent 'Alien::Base';
our $VERSION = '0.04';
1;

__END__

=head1 NAME

Alien::curlimpersonate - build and find libcurl-impersonate

=head1 SYNOPSIS

In your F<Makefile.PL>:

    use ExtUtils::MakeMaker;
    use Alien::Base::Wrapper ();
    use Alien::curlimpersonate ();

    my %args = Alien::Base::Wrapper->new('Alien::curlimpersonate')->mm_args2;

    # See "LINKING AGAINST IT" below: the wrapper emits no rpath, so add one.
    my ($libdir) = Alien::curlimpersonate->dynamic_libs;
    $libdir =~ s{/[^/]+$}{} if defined $libdir;
    $args{LDDLFLAGS} = join ' ', grep { defined && length }
        $args{LDDLFLAGS}, ($libdir ? "-Wl,-rpath,$libdir" : ());

    WriteMakefile(NAME => 'My::Module', %args);

Or just to see what was built:

    use Alien::curlimpersonate;
    say Alien::curlimpersonate->cflags;        # -I/.../include
    say Alien::curlimpersonate->libs;          # -L/.../lib -lcurl-impersonate
    say for Alien::curlimpersonate->dynamic_libs;

=head1 DESCRIPTION

Builds curl-impersonate (a patched libcurl with a bundled BoringSSL) from
source and exposes its cflags/libs, so an XS module can link a libcurl that
reproduces a real browser's TLS and HTTP/2 fingerprint -- JA3/JA4 and the
HTTP/2 SETTINGS "Akamai" fingerprint -- rather than the one libcurl would
otherwise present. See L<Curl::Impersonate> for a Perl client built on it.

This is a source-only Alien: there is no system package of
libcurl-impersonate to find, so the probe always selects a C<share> install
and the library is compiled at install time. See L</"SYSTEM REQUIREMENTS">,
because that build is neither short nor dependency-free.

The pinned version is B<v2.3.0>, built from
L<https://github.com/lexiforest/curl-impersonate> itself. It is an exact tag
rather than the newest one: upstream 2.0.0 replaced autotools with a CMake
superbuild, and the target names this library is asked for are load-bearing in
whatever links it, so neither is left to float.

=head1 SYSTEM REQUIREMENTS

curl-impersonate statically builds BoringSSL, c-ares, zlib, zstd, brotli, nghttp2 and
ngtcp2 alongside curl itself. That needs, on top of a C and C++ compiler:

=over 4

=item * C<git> -- the source is fetched by cloning the upstream repository

=item * C<cmake> 3.20 or newer -- the build is a CMake superbuild.
L<Alien::cmake3> supplies one where the system has none, but it promises only
3.x, so the version is checked before the build starts.

=item * C<ninja> (or C<ninja-build>) -- the curl subproject forces the Ninja
generator

=item * C<go> -- BoringSSL's build generates sources with it

=item * C<patch> -- upstream patches curl and its dependencies

=item * C<curl> and C<make> -- libidn2 is fetched and built by a shell script,
separately from CMake, because CMake requires it prebuilt and will not build it

=back

The build checks for these before it starts and names anything missing,
rather than failing deep inside a compile. On Debian or Ubuntu:

    apt-get install git cmake ninja-build golang-go patch curl build-essential

B<Expect the install to take several minutes> -- around five or six on a
current machine, and longer on a slow or loaded one. It is a full BoringSSL
and curl build, which is why installing this dist takes far longer than the
Perl code in it would suggest.

=head1 METHODS

This is an L<Alien::Base> subclass and adds nothing of its own; the useful
methods are inherited. The ones that matter here:

=over 4

=item C<< Alien::curlimpersonate->cflags >>

The include flags, as C<-I$prefix/include>.

=item C<< Alien::curlimpersonate->libs >>

The link flags, as C<-L$prefix/lib -lcurl-impersonate>. No rpath -- see below.

=item C<< Alien::curlimpersonate->dynamic_libs >>

The shared library B<file> paths -- not directories, and including the
versioned names. The order is not defined, but they all live in the same
directory, so taking that of any one of them is what you want for an rpath.

=back

=head1 LINKING AGAINST IT

C<libs> deliberately carries no C<-Wl,-rpath>. L<Alien::Base> relocates the
C<-L> it emits when the Alien is installed to its final location, but it does
B<not> relocate an rpath -- so an rpath baked in here would point at the
staging directory and be wrong by the time anyone links against it.

The consequence is that a consumer linking with C<libs> alone produces an
extension that builds cleanly and then fails at runtime with something like
C<libcurl-impersonate.so.4: cannot open shared object file>, unless
C<LD_LIBRARY_PATH> happens to be set.

So add the rpath yourself, against the resolved library directory, as the
SYNOPSIS shows: take C<dynamic_libs>, strip the filename, and pass
C<-Wl,-rpath,$libdir>. L<Curl::Impersonate>'s F<Makefile.PL> is a working
example.

=head1 CAVEATS

The version is pinned exactly. That is deliberate -- the whole point of this
Alien is a reproducible fingerprint, and the set of impersonation targets
changes between releases -- but it means a newer curl-impersonate needs a new
release of this dist rather than a rebuild. It is also load-bearing: upstream
2.0.0 replaced the autotools build with CMake outright, so a floating pin would
have broken the build the moment that tag was cut.

=head1 SEE ALSO

L<Curl::Impersonate>, L<Alien::Base>, L<Alien::Build>,
L<https://github.com/lexiforest/curl-impersonate>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The library it builds, curl-impersonate, is distributed under its own terms;
see the upstream project for details.

=cut
