package Acme::CPANModules::StructuredDATA;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Modules that give some structure to DATA',
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
# ABSTRACT: Modules that give some structure to DATA

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::StructuredDATA - Modules that give some structure to DATA

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::StructuredDATA (from Perl distribution Acme-CPANModules-StructuredDATA), released on 2019-01-09.

=head1 DESCRIPTION

Modules that give some structure to DATA.

The DATA file handle is a convenient feature provided by Perl to let scripts
access its own source code (specifically the part after B<END> or B<DATA>).
Scripts can usually put some data so they can run without additional data files.

Instead of just a stream of bytes, some modules allow you to access the DATA as
some kind of structured storage.

=head1 INCLUDED MODULES

=over

=item * L<Data::Section>

With this module, you can put several strings in your DATA section, each
prepended with a header line containing the label for each. For example:

 __[ content1 ]__
 content for content1.
 
 __[ content2 ]__
 content
 for
 content2

and access each string by referring to its label.


=item * L<Data::Section::Seekable>

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


=item * L<Inline::Files>

This is a prior art for L<Data::Section> but more magical (using source
filters) and allows writing in addition to reading your parts. It completely
replaces B<DATA> with an unlimited number of B<LABEL>'s. I'd be wary in using
it, and the module itself gives such warning.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-StructuredDATA>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-StructuredDATA>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-StructuredDATA>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
