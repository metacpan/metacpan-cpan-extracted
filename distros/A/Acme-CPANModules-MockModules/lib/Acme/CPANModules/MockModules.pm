package Acme::CPANModules::MockModules;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-26'; # DATE
our $DIST = 'Acme-CPANModules-MockModules'; # DIST
our $VERSION = '0.001'; # VERSION

our $LIST = {
    summary => 'Modules that mock other modules',
    description => <<'_',

Not to be confused with modules which you can use to do mock testing.

_
    entries => [
        {
            module => 'Log::Any::IfLOG',
            mocked_module => 'Log::Any',
        },
        {
            module => 'Locale::TextDomain::IfEnv',
            mocked_module => 'Locale::TextDomain',
        },
        {
            module => 'Locale::TextDomain::UTF8::IfEnv',
            mocked_module => 'Locale::TextDomain::UTF8',
        },
    ],
};

1;
# ABSTRACT: Modules that mock other modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::MockModules - Modules that mock other modules

=head1 VERSION

This document describes version 0.001 of Acme::CPANModules::MockModules (from Perl distribution Acme-CPANModules-MockModules), released on 2019-12-26.

=head1 DESCRIPTION

Modules that mock other modules.

Not to be confused with modules which you can use to do mock testing.

=head1 INCLUDED MODULES

=over

=item * L<Log::Any::IfLOG>

=item * L<Locale::TextDomain::IfEnv>

=item * L<Locale::TextDomain::UTF8::IfEnv>

=back

=head1 FAQ

=head2 What are ways to use this module?

Aside from reading it, you can install all the listed modules using
L<cpanmodules>:

    % cpanmodules ls-entries MockModules | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=MockModules -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

This module also helps L<lcpan> produce a more meaningful result for C<lcpan
related-mods> when it comes to finding related modules for the modules listed
in this Acme::CPANModules module.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-MockModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-MockModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-MockModules>

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
