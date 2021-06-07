package Acme::CPANModules::PERLANCAR::Dummy;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-20'; # DATE
our $DIST = 'Acme-CPANModules-PERLANCAR-Dummy'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'A dummy Acme::CPANModules list for testing',
    entry_features => {
        foo => {summary=>'Foo feature (bool)'},
        bar => {summary=>'Bar feature (bool)'},
        baz => {summary=>'Baz feature (string)', schema=>'str*'},
    },
    entries => [
        {
            module => "App::Trrr",
            features => {
                foo => {value=>undef, summary=>'Some note'},
                bar => {value=>undef, summary=>'Some note'},
                baz => 'value1',
            },
        },
        {
            module => "App::Wax",
            features => {foo=>1, bar=>1}},
        {
            module => "App::cpangrep",
            features => {foo=>0, bar=>0},
        },
        {
            module => "Acme::PPIx::MetaSyntactic",
            features => {foo=>1, bar=>0},
        },
    ],
};

1;
# ABSTRACT: A dummy Acme::CPANModules list for testing

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::PERLANCAR::Dummy - A dummy Acme::CPANModules list for testing

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::PERLANCAR::Dummy (from Perl distribution Acme-CPANModules-PERLANCAR-Dummy), released on 2021-02-20.

=head1 ACME::CPANMODULES FEATURE COMPARISON MATRIX

 +---------------------------+---------+---------+---------+
 | module                    | bar *1) | baz *2) | foo *3) |
 +---------------------------+---------+---------+---------+
 | App::Trrr                 | N/A *4) | value1  | N/A *4) |
 | App::Wax                  | yes     | N/A     | yes     |
 | App::cpangrep             | no      | N/A     | no      |
 | Acme::PPIx::MetaSyntactic | no      | N/A     | yes     |
 +---------------------------+---------+---------+---------+


Notes:

=over

=item 1. bar: Bar feature (bool)

=item 2. baz: Baz feature (string)

=item 3. foo: Foo feature (bool)

=item 4. Some note

=back

=head1 ACME::MODULES ENTRIES

=over

=item * L<App::Trrr>

=item * L<App::Wax>

=item * L<App::cpangrep>

=item * L<Acme::PPIx::MetaSyntactic>

=back

=head1 FAQ

=head2 What is an Acme::CPANModules::* module?

An Acme::CPANModules::* module, like this module, contains just a list of module
names that share a common characteristics. It is a way to categorize modules and
document CPAN. See L<Acme::CPANModules> for more details.

=head2 What are ways to use this Acme::CPANModules module?

Aside from reading this Acme::CPANModules module's POD documentation, you can
install all the listed modules (entries) using L<cpanmodules> CLI (from
L<App::cpanmodules> distribution):

    % cpanmodules ls-entries PERLANCAR::Dummy | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=PERLANCAR::Dummy -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::PERLANCAR::Dummy -E'say $_->{module} for @{ $Acme::CPANModules::PERLANCAR::Dummy::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-PERLANCAR-Dummy>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-PERLANCAR-Dummy>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Acme-CPANModules-PERLANCAR-Dummy/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANModules> - about the Acme::CPANModules namespace

L<cpanmodules> - CLI tool to let you browse/view the lists

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
