package Acme::CPANModules::Assert;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-08'; # DATE
our $DIST = 'Acme-CPANModules-Assert'; # DIST
our $VERSION = '0.002'; # VERSION

our $LIST = {
    summary => 'List of modules to do assertion',
    description => <<'_',

Assertion is a check statement that must evaluate to true or it will abort
program's execution. It is useful during development/debugging:

    assert("there must be >3 arguments", sub { @args > 3 });

In production code, compilers ideally do not generate code for assertion
statements so they do not have any impact on runtime performance.

In the old days, you only have this alternative to do it in Perl:

    assert(...) if DEBUG;

where `DEBUG` is a constant subroutine, declared using:

    use constant DEBUG => 0;

or:

    sub DEBUG() { 0 }

The perl compiler will optimize away and remove the code entirely when `DEBUG`
is false. But having to add `if DEBUG` to each assertion is annoying and
error-prone.

Nowadays, you have several alternatives to have a true, C-like assertions. One
technique is using <pm:Devel::Declare> (e.g. <pm:PerlX::Assert>). Another technique is
using <pm:B::CallChecker> (e.g. <pm:Assert::Conditional>).

_

        entries => [
            {module=>'Assert::Conditional'},
            {module=>'PerlX::Assert'},
            {module=>'Devel::Assert'},
            #{module=>'assertions'}, # this module doesn't work now, it uses an experimental feature available on 5.9.x which finally removed before 5.10.
        ],
    };

1;
# ABSTRACT: List of modules to do assertion

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANModules::Assert - List of modules to do assertion

=head1 VERSION

This document describes version 0.002 of Acme::CPANModules::Assert (from Perl distribution Acme-CPANModules-Assert), released on 2022-03-08.

=head1 DESCRIPTION

Assertion is a check statement that must evaluate to true or it will abort
program's execution. It is useful during development/debugging:

 assert("there must be >3 arguments", sub { @args > 3 });

In production code, compilers ideally do not generate code for assertion
statements so they do not have any impact on runtime performance.

In the old days, you only have this alternative to do it in Perl:

 assert(...) if DEBUG;

where C<DEBUG> is a constant subroutine, declared using:

 use constant DEBUG => 0;

or:

 sub DEBUG() { 0 }

The perl compiler will optimize away and remove the code entirely when C<DEBUG>
is false. But having to add C<if DEBUG> to each assertion is annoying and
error-prone.

Nowadays, you have several alternatives to have a true, C-like assertions. One
technique is using L<Devel::Declare> (e.g. L<PerlX::Assert>). Another technique is
using L<B::CallChecker> (e.g. L<Assert::Conditional>).

=head1 ACME::CPANMODULES ENTRIES

=over

=item * L<Assert::Conditional> - conditionally-compiled code assertions

Author: L<TOMC|https://metacpan.org/author/TOMC>

=item * L<PerlX::Assert> - yet another assertion keyword

Author: L<TOBYINK|https://metacpan.org/author/TOBYINK>

=item * L<Devel::Assert>

Author: L<RANDIR|https://metacpan.org/author/RANDIR>

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

 % cpanm-cpanmodules -n Assert

Alternatively you can use the L<cpanmodules> CLI (from L<App::cpanmodules>
distribution):

    % cpanmodules ls-entries Assert | cpanm -n

or L<Acme::CM::Get>:

    % perl -MAcme::CM::Get=Assert -E'say $_->{module} for @{ $LIST->{entries} }' | cpanm -n

or directly:

    % perl -MAcme::CPANModules::Assert -E'say $_->{module} for @{ $Acme::CPANModules::Assert::LIST->{entries} }' | cpanm -n

This Acme::CPANModules module also helps L<lcpan> produce a more meaningful
result for C<lcpan related-mods> command when it comes to finding related
modules for the modules listed in this Acme::CPANModules module.
See L<App::lcpan::Cmd::related_mods> for more details on how "related modules"
are found.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANModules-Assert>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANModules-Assert>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANModules-Assert>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
