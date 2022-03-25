package Acme::CPANModules::BloomFilters;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-BloomFilters'; # DIST
our $VERSION = '0.004'; # VERSION

our $LIST = {
    summary => "List of bloom filter modules on CPAN",
    description => <<'_',

Bloom filter is a data structure that allows you to quickly check whether an
element is in a set. Compared to a regular hash, it is much more
memory-efficient. The downside is that bloom filter can give you false
positives, although false negatives are not possible. So in essence you can ask
a bloom filter which item is "possibly in set" or "definitely not in set". You
can configure the rate of false positives. The larger the filter, the smaller
the rate. Some examples for application of bloom filter include: 1) checking
whether a password is in a dictionary of millions of common/compromised
passwords; 2) checking an email address against leak database; 3) virus pattern
checking; 4) IP/domain blacklisting/whitelisting. Due to its properties, it is
sometimes combined with other data structures. For example, a small bloom filter
can be distributed with a software to check against a database. When the answer
from bloom filter is "possibly in set", the software can further consult on
online database to make sure if it is indeed in set. Thus, bloom filter can be
used to reduce the number of direct queries to database.

In Perl, my default go-to choice is <pm:Algorithm::BloomFilter>, unless there's
a specific feature I need from other implementations.

_
    entries => [
        {
            module => 'Bloom::Filter',
            description => <<'_',

Does not provide mehods to save/load to/from strings/files, although you can
just take a peek at the source code or the hash object and get the filter there.
Performance might not be stellar since it's pure-Perl.

_
            tags => ['implementation'],
        },
        {
            module => 'Bloom16',
            description => <<'_',

An Inline::C module. Barely documented. Also does not provide filter
saving/loading methods.

_
            tags => ['implementation'],
        },
        {
            module => 'Algorithm::BloomFilter',
            description => <<'_',

XS, made by SMUELLER. Can merge other bloom filters. Provides serialize and
deserialize methods.

_
            tags => ['implementation'],
        },
        {
            module => 'Bloom::Scalable',
            description => <<'_',

Pure-perl module. A little weird, IMO, e.g. with hardcoded filenames. The
distribution also provides <pm:Bloom::Simple>.

_
            tags => ['implementation'],
        },
        {
            module => 'Bloom::Simple',
            description => <<'_',

Pure-perl module. A little weird, IMO, e.g. with hardcoded filenames.
The distribution also provides <pm:Bloom::Simple>.

_
            tags => ['implementation'],
        },
        {
            module => 'Bloom::Faster',
            description => <<'_',

XS module. Serialize/deserialize directly to/from files, no string
(de)serialization provided.

_
            tags => ['implementation'],
        },
        {
            module => 'Text::Bloom',
            description => <<'_',

Pure-Perl module, part of Text-Document distribution. Uses <pm:Bit::Vector>.

_
        },
        {
            module => 'App::BloomUtils',
            category => ['cli'],
        },
        {
            module => 'Bencher::Scenarios::BloomFilters',
            category => ['benchmark'],
        },
    ],
};

1;
# ABSTRACT: List of bloom filter modules on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::BloomFilters - List of bloom filter modules on CPAN

=head1 VERSION

This document describes version 0.004 of Acme::CPANModules::BloomFilters (from Perl distribution Acme-CPANModules-BloomFilters), released on 2022-03-18.

=head1 DESCRIPTION

Bloom filter is a data structure that allows you to quickly check whether an
element is in a set. Compared to a regular hash, it is much more
memory-efficient. The downside is that bloom filter can give you false
positives, although false negatives are not possible. So in essence you can ask
a bloom filter which item is "possibly in set" or "definitely not in set". You
can configure the rate of false positives. The larger the filter, the smaller
the rate. Some examples for application of bloom filter include: 1) checking
whether a password is in a dictionary of millions of common/compromised
passwords; 2) checking an email address against leak database; 3) virus pattern
checking; 4) IP/domain blacklisting/whitelisting. Due to its properties, it is
sometimes combined with other data structures. For example, a small bloom filter
can be distributed with a software to check against a database. When the answer
from bloom filter is "possibly in set", the software can further consult on
online database to make sure if it is indeed in set. Thus, bloom filter can be
used to reduce the number of direct queries to database.

In Perl, my default go-to choice is L<Algorithm::BloomFilter>, unless there's
a specific feature I need from other implementations.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Bloom::Filter> - Sample Perl Bloom filter implementation

Author: L<XAERXESS|https://metacpan.org/author/XAERXESS>

Does not provide mehods to save/load to/from strings/files, although you can
just take a peek at the source code or the hash object and get the filter there.
Performance might not be stellar since it's pure-Perl.


=item * L<Bloom16> - Perl extension for "threshold" Bloom filters

Author: L<IWOODHEAD|https://metacpan.org/author/IWOODHEAD>

An Inline::C module. Barely documented. Also does not provide filter
saving/loading methods.


=item * L<Algorithm::BloomFilter> - A simple bloom filter data structure

Author: L<SMUELLER|https://metacpan.org/author/SMUELLER>

XS, made by SMUELLER. Can merge other bloom filters. Provides serialize and
deserialize methods.


=item * L<Bloom::Scalable> - Implementation of the probalistic datastructure - ScalableBloomFilter

Author: L<SUBBU|https://metacpan.org/author/SUBBU>

Pure-perl module. A little weird, IMO, e.g. with hardcoded filenames. The
distribution also provides L<Bloom::Simple>.


=item * L<Bloom::Simple>

Author: L<SUBBU|https://metacpan.org/author/SUBBU>

Pure-perl module. A little weird, IMO, e.g. with hardcoded filenames.
The distribution also provides L<Bloom::Simple>.


=item * L<Bloom::Faster> - Perl extension for the c library libbloom.

Author: L<PALVARO|https://metacpan.org/author/PALVARO>

XS module. Serialize/deserialize directly to/from files, no string
(de)serialization provided.


=item * L<Text::Bloom>

Author: L<ASPINELLI|https://metacpan.org/author/ASPINELLI>

Pure-Perl module, part of Text-Document distribution. Uses L<Bit::Vector>.


=item * L<App::BloomUtils> - Utilities related to bloom filters

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

=item * L<Bencher::Scenarios::BloomFilters>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanm-cpanmodules> script (from
L<App::cpanm::cpanmodules> distribution):

 % cpanm-cpanmodules -n BloomFilters

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries BloomFilters | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=BloomFilters -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::BloomFilters -E'say $_->{module} for @{ $Acme::CPANModules::BloomFilters::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-BloomFilters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-BloomFilters>.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-BloomFilters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
