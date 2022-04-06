package Acme::CPANModules::StructuredDATA;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-18'; # DATE
our $DIST = 'Acme-CPANModules-StructuredDATA'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules that give some structure to DATA',
    description => <<'_',

The DATA file handle is a convenient feature provided by Perl to let scripts
access its own source code (specifically the part after __END__ or __DATA__).
Scripts can usually put some data so they can run without additional data files.

Instead of just a stream of bytes, some modules allow you to access the DATA as
some kind of structured storage.

_
    entries => [
        {
            module=>'Data::Section',
            description => <<'_',

With this module, you can put several strings in your DATA section, each
prepended with a header line containing the label for each. For example:

    __[ content1 ]__
    content for content1.

    __[ content2 ]__
    content
    for
    content2

and access each string by referring to its label.

_
        },
        {
            module=>'Data::Section::Seekable',
            description => <<'_',

This module is similar to <pm:Data::Section> in letting you put several
multipart content in DATA with the exception that it writes a table of content
(TOC) of all parts at the beginning of DATA, e.g.:

    __DATA__
    Data::Section::Seekable v1
    part1,0,14
    part2,14,17,important

    This is part1
    This is part
    two

The first paragraph after __DATA__ is called the TOC which lists all the parts
along with their offsets and lengths. It is therefore possible to locate any
part just from reading the TOC instead of scanning for headers on the whole
data. It is useful when the amount of data is quite large and you need quick
access to random parts.

_
        },
        {
            module=>'Inline::Files',
            description => <<'_',

This is a prior art for <pm:Data::Section> but more magical (using source
filters) and allows writing in addition to reading your parts. It completely
replaces __DATA__ with an unlimited number of __LABEL__'s. I'd be wary in using
it, and the module itself gives such warning.

_
        },
    ],
};

1;
# ABSTRACT: List of modules that give some structure to DATA

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::StructuredDATA - List of modules that give some structure to DATA

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::StructuredDATA (from Perl distribution Acme-CPANModules-StructuredDATA), released on 2022-03-18.

=head1 DESCRIPTION

The DATA file handle is a convenient feature provided by Perl to let scripts
access its own source code (specifically the part after B<END> or B<DATA>).
Scripts can usually put some data so they can run without additional data files.

Instead of just a stream of bytes, some modules allow you to access the DATA as
some kind of structured storage.

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Data::Section> - read multiple hunks of data out of your DATA section

Author: L<RJBS|https://metacpan.org/author/RJBS>

With this module, you can put several strings in your DATA section, each
prepended with a header line containing the label for each. For example:

 __[ content1 ]__
 content for content1.
 
 __[ content2 ]__
 content
 for
 content2

and access each string by referring to its label.


=item * L<Data::Section::Seekable> - Read and write parts from data section

Author: L<PERLANCAR|https://metacpan.org/author/PERLANCAR>

This module is similar to L<Data::Section> in letting you put several
multipart content in DATA with the exception that it writes a table of content
(TOC) of all parts at the beginning of DATA, e.g.:

 __DATA__
 Data::Section::Seekable v1
 part1,0,14
 part2,14,17,important
 
 This is part1
 This is part
 two

The first paragraph after B<DATA> is called the TOC which lists all the parts
along with their offsets and lengths. It is therefore possible to locate any
part just from reading the TOC instead of scanning for headers on the whole
data. It is useful when the amount of data is quite large and you need quick
access to random parts.


=item * L<Inline::Files> - Multiple virtual files at the end of your code

Author: L<AMBS|https://metacpan.org/author/AMBS>

This is a prior art for L<Data::Section> but more magical (using source
filters) and allows writing in addition to reading your parts. It completely
replaces B<DATA> with an unlimited number of B<LABEL>'s. I'd be wary in using
it, and the module itself gives such warning.


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

 % cpanm-cpanmodules -n StructuredDATA

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries StructuredDATA | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=StructuredDATA -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::StructuredDATA -E'say $_->{module} for @{ $Acme::CPANModules::StructuredDATA::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-StructuredDATA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-StructuredDATA>.

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

This software is copyright (c) 2022, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-StructuredDATA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
