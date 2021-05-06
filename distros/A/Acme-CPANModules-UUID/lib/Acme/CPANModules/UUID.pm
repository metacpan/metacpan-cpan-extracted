package Acme::CPANModules::UUID;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-06'; # DATE
our $DIST = 'Acme-CPANModules-UUID'; # DIST
our $VERSION = '0.010'; # VERSION

use strict;
use warnings;

our $LIST = {
    summary => 'Modules that can generate immutable universally unique identifier (UUIDs)',
    description => <<'_',

UUIDs (Universally Unique Identifiers), sometimes also called GUIDs (Globally
Unique Identifiers), are 128-bit numbers that can be used as permanent IDs or
keys in databases. There are several standards that specify UUID, one of which
is RFC 4122 (2005), which we will follow in this document.

UUIDs are canonically represented as 32 hexadecimal digits in the form of:

    xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx

There are several variants of UUID. The variant information is encoded using 1-3
bits in the `N` position. RFC 4122 defines 4 variants (0 to 3), two of which (0
and 3) are for legacy UUIDs, so that leaves variants 1 and 2 as the current
specification.

There are 5 "versions" of UUID for both variants 1 & 2, each might be more
suitable than others in specific cases. The version information is encoded in
the M position. Version 1 (v1) UUIDs are generated from a time and a node ID
(usually the MAC address); version 2 (v2) UUIDs from an identifier (group/user
ID), a time, and a node ID; version 4 (v4) UUIDs from a rando/mpseudo-random
number; version 3 (v3) UUIDs from hashing a namespace using MD5; version 5 (v5)
from hashing a namespace using SHA-1.

<pm:Data::UUID> should be your first choice, and when you cannot install XS
modules you can use <pm:UUID::Tiny> instead.

Aside from the modules listed as entries below, there are also:
<pm:App::UUIDUtils> (containing CLIs to create/check UUID), <pm:Data::GUID>
(currently just a wrapper for Data::UUID).

_
    entry_features => {
        v4_rfc4122 => {summary => 'Whether the generated v4 UUID follows RFC 4122 specification (i.e. encodes variant and version information in M & N positions)'},
        v4_secure_random => {summary => 'Whether the module uses cryptographically secure pseudo-random number generator for v4 UUIDs'},
    },
    entries => [
        {
            module => 'Data::UUID',
            description => <<'_',

This module creates v1 and v2 UUIDs. Depending on the OS, for MAC address, it
usually uses a hash of hostname instead. This module is XS, so performance is
good. If you cannot use an XS module, try <pm:UUID::Tiny> instead.

The benchmark code creates 1000+1 v1 string UUIDs.

_
            bench_code_template => 'my $u = Data::UUID->new; $u->create for 1..1000; $u->to_string($u->create)',
            features => {
                is_xs => 1,
                is_pp => 0,
                create_v1 => 1,
                create_v2 => 1,
                create_v3 => 0,
                create_v4 => 0,
                create_v5 => 0,
            },
        },

        {
            module => 'UUID::FFI',
            description => <<'_',

This module provides access to libuuid via the FFI interface. It can create v1
as well as v4 (random) UUIDs. Note that Data::UUID (XS-based) is faster this
module (FFI-based).

The benchmark code creates 1000+1 v1 string UUIDs.

_
            bench_code_template => 'UUID::FFI->new_time for 1..1000; UUID::FFI->new_time->as_hex',
            features => {
                is_xs => 1,
                is_pp => 0,
                create_v1 => 1,
                create_v2 => 0,
                create_v3 => 0,
                create_v4 => 1,
                v4_secure_random => 0,
                v4_rfc4122 => 1,
                create_v5 => 0,
            },
        },

        {
            module => 'UUID::Tiny',
            description => <<'_',

This module should be your go-to choice if you cannot use an XS module. It can
create v1, v3, v4 UUIDs. However, the random v4 UUIDs are not cryptographically
secure; if you need cryptographically secure random UUIDs, use <pm:Crypt::Misc>.

The benchmark code creates 1000+1 v1 string UUIDs.

See also: <pm:Types::UUID> which is a type library that uses Data::UUID as the
backend.

_
            bench_code_template => 'UUID::Tiny::create_uuid() for 1..1000; UUID::Tiny::uuid_to_string(UUID::Tiny::create_uuid())',
            features => {
                is_xs => 0,
                is_pp => 1,
                create_v1 => 1,
                create_v2 => 0,
                create_v3 => 1,
                create_v4 => 1,
                v4_secure_random => 0,
                v4_rfc4122 => 1,
                create_v5 => 1,
            },
        },

        {
            module => 'UUID::Random',
            description => <<'_',

This module simply uses 32 calls to Perl's C<rand()> to construct each random
hexadecimal digits of the UUID (v4). Not really recommended, since perl's
default pseudo-random generator is neither cryptographically secure nor has 128
bit of entropy. It also does not produce v4 UUIDs that conform to RFC 4122 (no
encoding of variant & version information).

To create a cryptographically secure random UUIDs, use <pm:Crypt::Misc>.

The benchmark code creates 1000+1 v4 string UUIDs.

_
            bench_code_template => 'UUID::Random::generate() for 1..1000; ; UUID::Random::generate()',
            features => {
                is_xs => 0,
                is_pp => 1,
                create_v1 => 0,
                create_v2 => 0,
                create_v3 => 0,
                create_v4 => 1,
                v4_secure_random => 0,
                v4_rfc4122 => 0,
                create_v5 => 0,
            },
        },

        {
            module => 'UUID::Random::PERLANCAR',
            description => <<'_',

Just another implementation of <pm:UUID::Random>.

The benchmark code creates 1000+1 v4 string UUIDs.

_
            features => {
                is_xs => 0,
                is_pp => 1,
                create_v1 => 0,
                create_v2 => 0,
                create_v3 => 0,
                create_v4 => 1,
                v4_secure_random => 0,
                v4_rfc4122 => 1,
                create_v5 => 0,
            },
            functions => {
                generate => {
                    bench_code_template => 'UUID::Random::PERLANCAR::generate() for 1..1000; UUID::Random::PERLANCAR::generate()',
                },
                generate_rfc => {
                    bench_code_template => 'UUID::Random::PERLANCAR::generate_rfc() for 1..1000; UUID::Random::PERLANCAR::generate_rfc()',
                },
            },
        },

        {
            module => 'UUID::Random::Secure',
            description => <<'_',

Just like <pm:UUID::Random>, except it uses <pm:Math::Random::Secure>'s
`irand()` to produce random numbers.

The benchmark code creates 1000+1 v4 string UUIDs.

_
            features => {
                is_xs => 0,
                is_pp => 1,
                create_v1 => 0,
                create_v2 => 0,
                create_v3 => 0,
                create_v4 => 1,
                v4_secure_random => 1,
                v4_rfc4122 => 1,
                create_v5 => 0,
            },
            functions => {
                generate => {
                    bench_code_template => 'UUID::Random::Secure::generate() for 1..1000; UUID::Random::Secure::generate()',
                },
                generate_rfc => {
                    bench_code_template => 'UUID::Random::Secure::generate_rfc() for 1..1000; UUID::Random::Secure::generate_rfc()',
                },
            },
         },

        {
            module => 'Crypt::Misc',
            description => <<'_',

This module from the <pm:CryptX> distribution has a function to create and check
v4 UUIDs.

The benchmark code creates 1000+1 v4 string UUIDs.

_
            bench_code_template => 'Crypt::Misc::random_v4uuid() for 1..1000; Crypt::Misc::random_v4uuid()',
            features => {
                is_xs => 0,
                is_pp => 1,
                create_v1 => 0,
                create_v2 => 0,
                create_v3 => 0,
                create_v4 => 1,
                v4_secure_random => 1,
                v4_rfc4122 => 1,
                create_v5 => 0,
            },
        },

    ],
};

1;
# ABSTRACT: Modules that can generate immutable universally unique identifier (UUIDs)

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::UUID - Modules that can generate immutable universally unique identifier (UUIDs)

=head1 VERSION

This document describes version 0.010 of Acme::CPANModules::UUID (from Perl distribution Acme-CPANModules-UUID), released on 2021-05-06.

=head1 SYNOPSIS

To run benchmark with default option:

 % bencher --cpanmodules-module UUID

To run module startup overhead benchmark:

 % bencher --module-startup --cpanmodules-module UUID

For more options (dump scenario, list/include/exclude/add participants, list/include/exclude/add datasets, etc), see L<bencher> or run C<bencher --help>.

=head1 DESCRIPTION

UUIDs (Universally Unique Identifiers), sometimes also called GUIDs (Globally
Unique Identifiers), are 128-bit numbers that can be used as permanent IDs or
keys in databases. There are several standards that specify UUID, one of which
is RFC 4122 (2005), which we will follow in this document.

UUIDs are canonically represented as 32 hexadecimal digits in the form of:

 xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx

There are several variants of UUID. The variant information is encoded using 1-3
bits in the C<N> position. RFC 4122 defines 4 variants (0 to 3), two of which (0
and 3) are for legacy UUIDs, so that leaves variants 1 and 2 as the current
specification.

There are 5 "versions" of UUID for both variants 1 & 2, each might be more
suitable than others in specific cases. The version information is encoded in
the M position. Version 1 (v1) UUIDs are generated from a time and a node ID
(usually the MAC address); version 2 (v2) UUIDs from an identifier (group/user
ID), a time, and a node ID; version 4 (v4) UUIDs from a rando/mpseudo-random
number; version 3 (v3) UUIDs from hashing a namespace using MD5; version 5 (v5)
from hashing a namespace using SHA-1.

L<Data::UUID> should be your first choice, and when you cannot install XS
modules you can use L<UUID::Tiny> instead.

Aside from the modules listed as entries below, there are also:
L<App::UUIDUtils> (containing CLIs to create/check UUID), L<Data::GUID>
(currently just a wrapper for Data::UUID).

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Data::UUID>

This module creates v1 and v2 UUIDs. Depending on the OS, for MAC address, it
usually uses a hash of hostname instead. This module is XS, so performance is
good. If you cannot use an XS module, try L<UUID::Tiny> instead.

The benchmark code creates 1000+1 v1 string UUIDs.


=item * L<UUID::FFI>

This module provides access to libuuid via the FFI interface. It can create v1
as well as v4 (random) UUIDs. Note that Data::UUID (XS-based) is faster this
module (FFI-based).

The benchmark code creates 1000+1 v1 string UUIDs.


=item * L<UUID::Tiny>

This module should be your go-to choice if you cannot use an XS module. It can
create v1, v3, v4 UUIDs. However, the random v4 UUIDs are not cryptographically
secure; if you need cryptographically secure random UUIDs, use L<Crypt::Misc>.

The benchmark code creates 1000+1 v1 string UUIDs.

See also: L<Types::UUID> which is a type library that uses Data::UUID as the
backend.


=item * L<UUID::Random>

This module simply uses 32 calls to Perl's C<rand()> to construct each random
hexadecimal digits of the UUID (v4). Not really recommended, since perl's
default pseudo-random generator is neither cryptographically secure nor has 128
bit of entropy. It also does not produce v4 UUIDs that conform to RFC 4122 (no
encoding of variant & version information).

To create a cryptographically secure random UUIDs, use L<Crypt::Misc>.

The benchmark code creates 1000+1 v4 string UUIDs.


=item * L<UUID::Random::PERLANCAR>

Just another implementation of L<UUID::Random>.

The benchmark code creates 1000+1 v4 string UUIDs.


=item * L<UUID::Random::Secure>

Just like L<UUID::Random>, except it uses L<Math::Random::Secure>'s
C<irand()> to produce random numbers.

The benchmark code creates 1000+1 v4 string UUIDs.


=item * L<Crypt::Misc>

This module from the L<CryptX> distribution has a function to create and check
v4 UUIDs.

The benchmark code creates 1000+1 v4 string UUIDs.


=back

=head1 ACME::CPANMODULES FEATURE COMPARISON MATRIX

 +-------------------------+-----------+-----------+-----------+-----------+-----------+-------+-------+----------------+----------------------+
 | module                  | create_v1 | create_v2 | create_v3 | create_v4 | create_v5 | is_pp | is_xs | v4_rfc4122 *1) | v4_secure_random *2) |
 +-------------------------+-----------+-----------+-----------+-----------+-----------+-------+-------+----------------+----------------------+
 | Data::UUID              | yes       | yes       | no        | no        | no        | no    | yes   | N/A            | N/A                  |
 | UUID::FFI               | yes       | no        | no        | yes       | no        | no    | yes   | yes            | no                   |
 | UUID::Tiny              | yes       | no        | yes       | yes       | yes       | yes   | no    | yes            | no                   |
 | UUID::Random            | no        | no        | no        | yes       | no        | yes   | no    | no             | no                   |
 | UUID::Random::PERLANCAR | no        | no        | no        | yes       | no        | yes   | no    | yes            | no                   |
 | UUID::Random::Secure    | no        | no        | no        | yes       | no        | yes   | no    | yes            | yes                  |
 | Crypt::Misc             | no        | no        | no        | yes       | no        | yes   | no    | yes            | yes                  |
 +-------------------------+-----------+-----------+-----------+-----------+-----------+-------+-------+----------------+----------------------+
 


Notes:

=over

=item 1. v4_rfc4122: Whether the generated v4 UUID follows RFC 4122 specification (i.e. encodes variant and version information in M & N positions)

=item 2. v4_secure_random: Whether the module uses cryptographically secure pseudo-random number generator for v4 UUIDs

=back

=head1 BENCHMARKED MODULES

Version numbers shown below are the versions used when running the sample benchmark.

L<Data::UUID> 1.224

L<UUID::FFI> 0.09

L<UUID::Tiny> 1.04

L<UUID::Random> 0.04

L<UUID::Random::PERLANCAR> 0.005

L<UUID::Random::Secure> 0.004

L<Crypt::Misc> 0.069

=head1 BENCHMARK PARTICIPANTS

=over

=item * Data::UUID (perl_code)

Code template:

 my $u = Data::UUID->new; $u->create for 1..1000; $u->to_string($u->create)



=item * UUID::FFI (perl_code)

Code template:

 UUID::FFI->new_time for 1..1000; UUID::FFI->new_time->as_hex



=item * UUID::Tiny (perl_code)

Code template:

 UUID::Tiny::create_uuid() for 1..1000; UUID::Tiny::uuid_to_string(UUID::Tiny::create_uuid())



=item * UUID::Random (perl_code)

Code template:

 UUID::Random::generate() for 1..1000; ; UUID::Random::generate()



=item * UUID::Random::PERLANCAR::generate (perl_code)

Code template:

 UUID::Random::PERLANCAR::generate() for 1..1000; UUID::Random::PERLANCAR::generate()



=item * UUID::Random::PERLANCAR::generate_rfc (perl_code)

Code template:

 UUID::Random::PERLANCAR::generate_rfc() for 1..1000; UUID::Random::PERLANCAR::generate_rfc()



=item * UUID::Random::Secure::generate (perl_code)

Code template:

 UUID::Random::Secure::generate() for 1..1000; UUID::Random::Secure::generate()



=item * UUID::Random::Secure::generate_rfc (perl_code)

Code template:

 UUID::Random::Secure::generate_rfc() for 1..1000; UUID::Random::Secure::generate_rfc()



=item * Crypt::Misc (perl_code)

Code template:

 Crypt::Misc::random_v4uuid() for 1..1000; Crypt::Misc::random_v4uuid()



=back

=head1 SAMPLE BENCHMARK RESULTS

Run on: perl: I<< v5.30.0 >>, CPU: I<< Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz (2 cores) >>, OS: I<< GNU/Linux Ubuntu version 20.04 >>, OS kernel: I<< Linux version 5.3.0-64-generic >>.

Benchmark with default options (C<< bencher --cpanmodules-module UUID >>):

 #table1#
 +---------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | participant                           | rate (/s) | time (ms) | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +---------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+
 | UUID::Random::Secure::generate_rfc    |        46 |     22    |                 0.00% |              4868.44% | 7.5e-05   |      28 |
 | UUID::Random::Secure::generate        |        47 |     21    |                 2.74% |              4735.97% |   6e-05   |      23 |
 | UUID::Random                          |        90 |     10    |                95.80% |              2437.45% |   0.00034 |      22 |
 | UUID::Tiny                            |       140 |      7.2  |               201.89% |              1545.81% | 1.8e-05   |      20 |
 | Crypt::Misc                           |       290 |      3.5  |               525.12% |               694.80% | 1.4e-05   |      20 |
 | UUID::FFI                             |       930 |      1.1  |              1911.64% |               146.98% | 3.4e-06   |      20 |
 | UUID::Random::PERLANCAR::generate_rfc |      1000 |      1    |              2098.91% |               125.95% | 2.9e-05   |      34 |
 | UUID::Random::PERLANCAR::generate     |      1700 |      0.59 |              3596.91% |                34.39% | 1.1e-06   |      20 |
 | Data::UUID                            |      2300 |      0.44 |              4868.44% |                 0.00% | 1.8e-06   |      20 |
 +---------------------------------------+-----------+-----------+-----------------------+-----------------------+-----------+---------+


Benchmark module startup overhead (C<< bencher --cpanmodules-module UUID --module-startup >>):

 #table2#
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | participant             | time (ms) | mod_overhead_time | pct_faster_vs_slowest | pct_slower_vs_fastest |  errors   | samples |
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+
 | UUID::Random::Secure    |      86   |              78   |                 0.00% |               976.54% |   0.00038 |      20 |
 | UUID::FFI               |      60   |              52   |                44.16% |               646.77% | 8.1e-05   |      20 |
 | UUID::Tiny              |      24   |              16   |               259.84% |               199.17% | 3.8e-05   |      22 |
 | Crypt::Misc             |      18.3 |              10.3 |               371.86% |               128.15% | 1.6e-05   |      20 |
 | Data::UUID              |      16   |               8   |               429.19% |               103.43% |   0.00012 |      20 |
 | UUID::Random            |       9.2 |               1.2 |               840.25% |                14.50% | 2.7e-05   |      20 |
 | UUID::Random::PERLANCAR |       9.1 |               1.1 |               850.03% |                13.32% | 2.3e-05   |      20 |
 | perl -e1 (baseline)     |       8   |               0   |               976.54% |                 0.00% |   0.00018 |      20 |
 +-------------------------+-----------+-------------------+-----------------------+-----------------------+-----------+---------+


To display as an interactive HTML table on a browser, you can add option C<--format html+datatables>.

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries UUID | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=UUID -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::UUID -E'say $_->{module} for @{ $Acme::CPANModules::UUID::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module contains benchmark instructions. You can run a
benchmark for some/all the modules listed in this Acme::CPANModules module using
the L<bencher> CLI (from L<Bencher> distribution):

    % bencher --cpanmodules-module UUID

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-UUID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-UUID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-UUID/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

RFC 4122, L<https://tools.ietf.org/html/rfc4122>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
