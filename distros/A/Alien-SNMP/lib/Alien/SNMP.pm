package Alien::SNMP;

use strict;
use warnings;
use 5.010001;
use parent qw(Alien::Base);

our $VERSION = '4.0509050201';

# Preload the dynamic Net-SNMP library with global symbol visibility so that
# the bundled SNMP XS module (which has `use Alien::SNMP;` injected ahead of
# its XSLoader call) and any downstream XS resolve libnetsnmp from our share
# dir whatever path was baked into them: the loader matches the already-loaded
# image by SONAME on ELF, and by install name on darwin.  This is what lets the
# test suite pass before `make install` populates the final share dir (the
# window CPAN Testers run in), and lets the distribution work with no
# system-level libnetsnmp present.
# Best-effort: never let a failure here break `use Alien::SNMP` (e.g. when the
# module is loaded from source before the share dir exists).  The baked-in
# run-path still resolves libnetsnmp once the share is installed.
eval { __PACKAGE__->_preload_netsnmp };

sub _preload_netsnmp {
    my ($class) = @_;
    require DynaLoader;
    DynaLoader::dl_load_file($_, 0x01)   # 0x01 = RTLD_GLOBAL
      for $class->_netsnmp_dynamic_libs;
}

# The dynamic libnetsnmp under whichever name this platform gives it:
# libnetsnmp.so[.N...] on ELF, libnetsnmp[.N...].dylib on darwin.  Sibling
# libraries (libnetsnmpagent and friends) deliberately do not match; libnetsnmp
# is what the bundled XS records as a dependency.  Matching nothing is silent,
# because the preload is best-effort, so t/06 asserts this finds something: an
# ELF-only pattern here is what left macOS unable to run its own test suite.
# The capture also untaints the trusted share-dir path for dl_load_file.
sub _netsnmp_dynamic_libs {
    my ($class) = @_;
    return unless $class->install_type eq 'share';
    return map { m{(/.*/libnetsnmp(?:\.[0-9]+)*\.(?:so(?:\.[0-9]+)*|dylib))\z} ? $1 : () }
           $class->dynamic_libs;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::SNMP - Alien package for the Net-SNMP library

=cut

=head1 SYNOPSIS

 use Alien::SNMP;
 # then it's just like SNMP.pm
 
 say Alien::SNMP->bin_dir;
 # where the net-snmp apps (snmptranslate, etc) live

=head1 DESCRIPTION

L<Alien::SNMP> downloads and installs the Net-SNMP library and
associated perl modules.

The library is built with the following options:

=over

=item C<--disable-agent>

=item C<--disable-manuals>

=item C<--disable-scripts>

=item C<--disable-mibs>

=item C<--enable-ipv6>

=item C<--with-mibs="">

=item C<--with-perl-modules>

=item C<--disable-embedded-perl>

=item C<--enable-blumenthal-aes>

=item C<--with-defaults>

=back

=head2 macOS

Build this with a Homebrew or perlbrew perl. Apple's F</usr/bin/perl> is not a
supported target: it is frozen at whatever version macOS shipped, its
directories need root, and Apple has deprecated the runtime. Continuous
integration covers Homebrew perl on both Intel and Apple Silicon.

If a bare C<perl> on your C<PATH> still resolves to F</usr/bin/perl>,
C<Makefile.PL> aborts with C<Can't locate Alien/Build/MM.pm>. Run it with the
full path to the perl you mean.

=head1 BACKGROUND

Net-SNMP's Perl modules live in the Net-SNMP source tree; they are not a
separately maintained CPAN distribution. The standalone C<SNMP> release on CPAN
is 5.0404, whose version number encodes the Net-SNMP 5.4.4 release it was taken
from. This distribution instead installs the C<SNMP> module out of the Net-SNMP
tarball it builds and pins, so the Perl module and the C library beneath it
always come from the same upstream release. That coupling matters, because the
XS is compiled against one specific libnetsnmp, and it is what keeps the Perl
side level with the library rather than years behind it.

Three kinds of user need that.

=over

=item Anyone installing outside the system perl

The Perl modules in a distribution's C<net-snmp> package are built for the
system perl and installed into system directories, so under perlbrew,
L<local::lib>, or any C<INSTALL_BASE> prefix they are simply not on C<@INC>.
This distribution builds them with the perl that is running the build and
installs them wherever that perl's install target points. See
L</BUNDLED PERL MODULES>.

=item Anyone parsing large MIB collections

Older Net-SNMP had fixed ceilings in the MIB parser: a maximum number of
Textual Conventions, and a maximum number of imports per module. Large vendor
MIB collections reached them, which is why patched Net-SNMP builds were once
needed for MIB development. Both limits are gone as of Net-SNMP 5.9, where the
Textual Convention list grows on demand and C<MAX_IMPORTS> is 512. A stock
build from this distribution needs no patching for that work.

=item Anyone shelling out to the Net-SNMP tools

The command line utilities are built here too, from the same source, and can be
put ahead of the system ones on C<PATH>. See L</COMMAND LINE UTILITIES>.

=back

=head1 BUNDLED PERL MODULES

The Net-SNMP source ships the C<SNMP> and C<NetSNMP::*> XS modules. They are
built against the library built here, by the same perl that is building this
distribution, and are installed along with it. A bare C<use SNMP;> therefore
works, and they follow whatever installation target you give L<Alien::SNMP>
itself (C<INSTALL_BASE>, C<PREFIX>, C<DESTDIR>, L<local::lib>).

They resolve C<libnetsnmp> from this Alien's share dir, so they coexist with an
operating system C<net-snmp> package: system tools keep using the system
library, while these modules use ours. That is arranged two ways: Net-SNMP bakes
the share dir into the XS modules' run-path, and this module additionally
preloads the share copy at use-time. Note that the run-path is emitted as
C<DT_RUNPATH>, which C<LD_LIBRARY_PATH> takes precedence over; the preload is
what makes the choice robust in that case.

On macOS the mechanism differs but the outcome does not: the XS modules record
C<libnetsnmp> by its absolute path in the installed share dir, so that is the
copy they load.

=head2 Shadowing an operating system packaged SNMP.pm

Some operating systems ship Net-SNMP's Perl modules as a package of their own,
installed into the system perl's vendor directories. Installing L<Alien::SNMP>
into that same perl, which is what happens when it is installed as root outside
perlbrew or L<local::lib>, puts our copy in the site directories. Those precede
the vendor ones in C<@INC>, so ours answers C<use SNMP;> for every script that
perl runs.

Nothing is overwritten. The two copies live in different directories, and
removing L<Alien::SNMP> brings the operating system packaged one back. But the
substitution is silent, and our copy looks in different places than the
operating system packaged one did:

=over

=item MIB files

The operating system packaged module searches the system MIB directory, usually
F</usr/share/snmp/mibs>. Ours does not. See L</MIBS>.

=item F<snmp.conf>

The operating system packaged module reads F</etc/snmp/snmp.conf>, where a site
keeps defaults such as C<defVersion>, C<defCommunity>, C<mibdirs> and C<mibs>.
Ours reads F<snmp.conf> from its own share directory and from F<~/.snmp>, never
from F</etc/snmp>, so those defaults stop applying. Set C<SNMPCONFPATH> to the
directories you want searched to get them back.

=back

Neither change reports anything: symbolic names quietly stop resolving and site
defaults quietly stop being read. Installing into a perlbrew or L<local::lib>
perl raises neither question, because nothing is shadowed.

=head1 MIBS

No MIB files are shipped, because Net-SNMP is configured here with
C<--disable-mibs> and C<--with-mibs="">. Out of the box both the Perl modules
and the command line tools work in numeric OIDs, and C<snmptranslate> reports
C<Cannot find module>.

The system MIB directory is not consulted either. The default search path is
F<~/.snmp/mibs> plus a directory inside this distribution's share, and nothing
else, whatever the operating system may have installed elsewhere.

That is a matter of supplying MIBs, not a missing capability. Symbolic names
resolve normally, in both directions, once a collection is on the search path.
Put one there with the C<-M> option or the C<MIBDIRS> environment variable, or
place files in F<~/.snmp/mibs>, which is on the default path:

 $ MIBDIRS=/path/to/mibs snmptranslate .1.3.6.1.2.1.1.3.0
 SNMPv2-MIB::sysUpTime.0

From Perl, C<SNMP::addMibDirs> and C<SNMP::loadModules> do the same job. Either
way that covers the modules Net-SNMP loads by default; anything outside that
list also needs naming, with C<-m> or the C<MIBS> environment variable.

=head2 The MIB index files are gone

Net-SNMP 5.9 removed the on-disk MIB index cache. It no longer writes or reads
the C<.index> files older versions left inside MIB directories, nor the numbered
files under C<SNMP_PERSISTENT_DIR>, and that variable now has no bearing on MIB
indexing at all. Parsing is unaffected: C<snmptranslate>, C<SNMP::addMibDirs>
and C<SNMP::loadModules> behave as they always did, and directories are simply
rescanned each run instead of being read from a cache.

What is gone is any way to ask Net-SNMP B<which file defines a given module>.
It still tracks that internally but exposes no accessor, so code that located a
module's file by reading an index directory will find nothing there. Derive the
mapping from the files instead, following Net-SNMP's own rule from
C<add_mibfile()> in F<snmplib/parse.c>: a file defines a module when its first
token is a label and its second is C<DEFINITIONS>, and that first token is the
module name. Reading the head of each candidate file until C<DEFINITIONS>
appears is enough to build the map.

Two things trip up a hand-rolled version. Strip C<--> comments before looking
for C<DEFINITIONS>, or a mention of it in a file's comment header ends the read
early; note too that an ASN.1 comment ends at a second C<--> as well as at end
of line. And do not derive the module from the file name: F<SNMPv2-MIB.txt> does
contain C<SNMPv2-MIB>, so that shortcut passes on the common case and then fails
on vendor MIBs, where F<CISCO-90-MIB.my> defines C<Cisco90Series-MIB>.

Building the map opens every file in the collection, so cache it if you need it
often.

=head1 COMMAND LINE UTILITIES

The build also produces the Net-SNMP client tools, C<snmpget>, C<snmpwalk>,
C<snmpbulkwalk>, C<snmptranslate>, C<snmptable> and the rest, from the same
pinned source as the library and the Perl modules. C<--disable-agent> means
there is no C<snmpd>; these are the client side. L</bin_dir> returns the
directory holding them, so a program that shells out can use them in preference
to whatever the operating system ships, or on a host that ships none:

 use Alien::SNMP;
 use Env qw( @PATH );
 unshift @PATH, Alien::SNMP->bin_dir;

 my $uptime = `snmpget -v2c -c public $host 1.3.6.1.2.1.1.3.0`;

They read MIBs and F<snmp.conf> from this distribution's own directories rather
than from F</usr/share/snmp/mibs> and F</etc/snmp>, so putting L</bin_dir> first
on C<PATH> changes both for anything that runs from there. See
L</Shadowing an operating system packaged SNMP.pm>.

Their options and output formats are Net-SNMP's own and are documented at
L<http://www.net-snmp.org/docs/man/>. This distribution builds with
C<--disable-manuals>, so it installs no man pages of its own for them.

=head2 Which libnetsnmp the utilities load

Each utility records this distribution's share directory as its run-path, so it
finds our C<libnetsnmp> without any help from you, and coexists with a system
Net-SNMP package. The one thing that overrides a run-path is
C<LD_LIBRARY_PATH>, an environment variable that is unset on most systems and
that C<echo $LD_LIBRARY_PATH> will show you. If it is set, and names a directory
holding another C<libnetsnmp> of the same major version, that copy is loaded
instead of ours. C<delete local $ENV{LD_LIBRARY_PATH};> around the call rules
that out.

=head1 METHODS

=head2 bin_dir

 my $bin_dir = Alien::SNMP->bin_dir;

Returns the location of the net-snmp apps (snmptranslate, etc).
See L</COMMAND LINE UTILITIES>.

=head2 cflags

 my $cflags = Alien::SNMP->cflags;

Returns the C compiler flags.

=head2 libs

 my $libs = Alien::SNMP->libs;

Returns the linker flags.

=head1 SEE ALSO

=over 4

=item L<Alien>

=item L<Alien::Base>

=item L<SNMP>

The Perl5 'SNMP' Extension Module for the Net-SNMP SNMP package.  Depends on
libnetsnmp and the corresponding version is installed along with the C
library.

=back

=head1 AUTHOR

Eric A. Miller, C<< <emiller at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Eric A. Miller.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Eric A. Miller's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
