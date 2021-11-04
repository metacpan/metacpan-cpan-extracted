package Acme::CPANModules::BloomFilters;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-28'; # DATE
our $DIST = 'Acme-CPANModules-BloomFilters'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => "Bloom filter modules on CPAN",
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
checking; 4) IP/domain blacklisting/whitelisting.

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
# ABSTRACT: Bloom filter modules on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::BloomFilters - Bloom filter modules on CPAN

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::BloomFilters (from Perl distribution Acme-CPANModules-BloomFilters), released on 2021-05-28.

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
checking; 4) IP/domain blacklisting/whitelisting.

In Perl, my default go-to choice is L<Algorithm::BloomFilter>, unless there's
a specific feature I need from other implementations.

=head1 ACME::MODULES ENTRIES

=over

=item * L<Bloom::Filter>

Does not provide mehods to save/load to/from strings/files, although you can
just take a peek at the source code or the hash object and get the filter there.
Performance might not be stellar since it's pure-Perl.


=item * L<Bloom16>

An Inline::C module. Barely documented. Also does not provide filter
saving/loading methods.


=item * L<Algorithm::BloomFilter>

XS, made by SMUELLER. Can merge other bloom filters. Provides serialize and
deserialize methods.


=item * L<Bloom::Scalable>

Pure-perl module. A little weird, IMO, e.g. with hardcoded filenames. The
distribution also provides L<Bloom::Simple>.


=item * L<Bloom::Simple>

Pure-perl module. A little weird, IMO, e.g. with hardcoded filenames.
The distribution also provides L<Bloom::Simple>.


=item * L<Bloom::Faster>

XS module. Serialize/deserialize directly to/from files, no string
(de)serialization provided.


=item * L<Text::Bloom>

Pure-Perl module, part of Text-Document distribution. Uses L<Bit::Vector>.


=item * L<App::BloomUtils>

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-BloomFilters>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-BloomFilters>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-BloomFilters>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
