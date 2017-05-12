    README for DDC::Concordance (formerly known as ddc-perl)

ABSTRACT
    DDC::Concordance - Query and wrapper utilities for the ddc-concordance
    search engine

REQUIREMENTS
    IO::Socket::INET
    NetServer::Generic
        (for server wrapping)

    Text::Wrap
    Lingua::LTS
        (for LTS wrapping, see 'grimm/lts/Lingua-LTS' directory in the DWDS
        subversion repository)

RECOMMENDATIONS
    DDC::XS
        XS wrappers for the libDDC* C++ libraries will be used if available.

    a running DDC server
        (for client connection) Current sources for the DDC search engine
        should be available from
        <http://sourceforge.net/projects/ddc-concordance/>, and should be
        installable for supported systems via the Alien::DDC::Concordance
        module, available on CPAN.

DESCRIPTION
    The DDC::Concordance package (formerly known as ddc-perl) provides
    object-oriented wrappers for querying and/or wrapping a DDC corpus index
    server. Also included in the distribution are some example scripts for
    querying a server, simple query expansion using an LTS transducer and an
    indexed 'pho' field, as well as a drop-in wrapper for an underlying DDC
    server which performs transparent query translation for an indexed 'pho'
    field.

  Current Version
    Current sources for this module should be available from CPAN
    (<http://metacpan.org/release/DDC-Concordance>) or via sourceforce
    (<https://sourceforge.net/projects/ddc-concordance/files/ddc-perl/>).

KNOWN BUGS
  Conflicting CPAN module names
    Unforunately, the top-level "DDC" namespace conflicts with another
    module on CPAN, namely Torsten Raudssus' "DDC" from the "Data-Coloured"
    distribution (<https://metacpan.org/pod/DDC>). As a workaround to this
    problem, the top-level module for this package has been renamed to
    "DDC::Concordance" in ddc-perl v0.17. New code should use the
    DDC::Concordance module directly as a top-level entry point and
    dependency target.

    For backwards-compatibility, the ddc-perl-compat distribution is
    provided to enable older code to run without explicit changes, but note
    that its installation may cause unexpected results if you also use the
    "DDC" module from the "Data::Coloured" distribution. If necessary, you
    can explicitly define a dependency on "DDC::Compat" to ensure that a
    backwards-compatible top-level "use DDC;" will load the DDC::Concordance
    module. The ddc-perl-compat distribution is available via sourceforce
    (<https://sourceforge.net/projects/ddc-concordance/files/ddc-perl/>).

AUTHOR
    Bryan Jurish <moocow@cpan.org>

